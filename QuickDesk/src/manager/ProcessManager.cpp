// Copyright 2026 QuickDesk Authors

#include "ProcessManager.h"
#include "NativeMessaging.h"
#include "infra/log/log.h"
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>

namespace quickdesk {

ProcessManager::ProcessManager(QObject* parent)
    : QObject(parent)
{
    // Setup restart timers
    m_hostRestartTimer.setSingleShot(true);
    connect(&m_hostRestartTimer, &QTimer::timeout,
            this, &ProcessManager::onHostRestartTimer);
    
    m_clientRestartTimer.setSingleShot(true);
    connect(&m_clientRestartTimer, &QTimer::timeout,
            this, &ProcessManager::onClientRestartTimer);
}

ProcessManager::~ProcessManager()
{
    // Stop timers first
    m_hostRestartTimer.stop();
    m_clientRestartTimer.stop();
    
    // Disable auto-restart during destruction
    m_hostAutoRestart = false;
    m_clientAutoRestart = false;
    
    stopAllProcesses();
}

bool ProcessManager::startHostProcess()
{
    if (isHostRunning()) {
        LOG_WARN("Host process is already running");
        return true;
    }

    if (m_hostExePath.isEmpty()) {
        emit hostProcessError("Host executable path not set");
        return false;
    }

    m_hostProcess = std::make_unique<QProcess>(this);
    
    connect(m_hostProcess.get(), 
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ProcessManager::onHostProcessFinished);

    if (!startProcess(m_hostProcess.get(), m_hostExePath, "Host", m_logDir)) {
        m_hostProcess.reset();
        return false;
    }

    // Create Native Messaging handler
    m_hostMessaging = std::make_unique<NativeMessaging>(m_hostProcess.get(), this);
    
    setHostStatus("running");
    emit hostProcessStarted();
    LOG_INFO("Host process started, PID: {}", m_hostProcess->processId());
    
    return true;
}

bool ProcessManager::startClientProcess()
{
    if (isClientRunning()) {
        LOG_WARN("Client process is already running");
        return true;
    }

    if (m_clientExePath.isEmpty()) {
        emit clientProcessError("Client executable path not set");
        return false;
    }

    m_clientProcess = std::make_unique<QProcess>(this);
    
    connect(m_clientProcess.get(), 
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ProcessManager::onClientProcessFinished);

    if (!startProcess(m_clientProcess.get(), m_clientExePath, "Client", m_logDir)) {
        m_clientProcess.reset();
        return false;
    }

    // Create Native Messaging handler
    m_clientMessaging = std::make_unique<NativeMessaging>(m_clientProcess.get(), this);
    
    setClientStatus("running");
    emit clientProcessStarted();
    LOG_INFO("Client process started, PID: {}", m_clientProcess->processId());
    
    return true;
}

void ProcessManager::stopHostProcess()
{
    m_hostRestartTimer.stop();
    m_hostStoppingIntentionally = true;
    
    if (m_hostProcess && m_hostProcess->state() != QProcess::NotRunning) {
        LOG_INFO("begin stop host process...");
        m_hostProcess->closeWriteChannel(); // Close stdin to trigger graceful exit
        bool finished = m_hostProcess->waitForFinished(10000);
        if (!finished) {
            LOG_WARN("Host process did not exit gracefully, terminating...");
            m_hostProcess->terminate();
            finished = m_hostProcess->waitForFinished(5000);
        }
        if (!finished) {
            LOG_WARN("Host process did not terminate, killing...");
            m_hostProcess->kill();
            finished = m_hostProcess->waitForFinished(5000);
        }
        LOG_INFO("end stop host process...");
        if (!finished && m_hostProcess->state() != QProcess::NotRunning) {
            LOG_WARN("Host process still running, skipping destroy");
            return;
        }
    }
    m_hostMessaging.reset();
    m_hostProcess.reset();
    m_hostRestartCount = 0;
    setHostStatus("stopped");
}

void ProcessManager::stopClientProcess()
{
    m_clientRestartTimer.stop();
    m_clientStoppingIntentionally = true;
    
    if (m_clientProcess && m_clientProcess->state() != QProcess::NotRunning) {
        LOG_INFO("begin stop client process...");
        m_clientProcess->closeWriteChannel();
        bool finished = m_clientProcess->waitForFinished(3000);
        if (!finished) {
            LOG_WARN("Client process did not exit gracefully, terminating...");
            m_clientProcess->terminate();
            finished = m_clientProcess->waitForFinished(3000);
        }
        if (!finished) {
            LOG_WARN("Client process did not terminate, killing...");
            m_clientProcess->kill();
            finished = m_clientProcess->waitForFinished(3000);
        }
        LOG_INFO("end stop client process...");
        if (!finished && m_clientProcess->state() != QProcess::NotRunning) {
            LOG_WARN("Client process still running, skipping destroy");
            return;
        }
    }
    m_clientMessaging.reset();
    m_clientProcess.reset();
    m_clientRestartCount = 0;
    setClientStatus("stopped");
}

void ProcessManager::stopAllProcesses()
{
    stopHostProcess();
    stopClientProcess();
}

bool ProcessManager::isHostRunning() const
{
    return m_hostProcess && m_hostProcess->state() == QProcess::Running;
}

bool ProcessManager::isClientRunning() const
{
    return m_clientProcess && m_clientProcess->state() == QProcess::Running;
}

NativeMessaging* ProcessManager::hostMessaging() const
{
    return m_hostMessaging.get();
}

NativeMessaging* ProcessManager::clientMessaging() const
{
    return m_clientMessaging.get();
}

void ProcessManager::setHostExePath(const QString& path)
{
    m_hostExePath = path;
}

void ProcessManager::setClientExePath(const QString& path)
{
    m_clientExePath = path;
}

void ProcessManager::setLogDir(const QString& logDir)
{
    m_logDir = logDir;
}

QString ProcessManager::logDir() const
{
    return m_logDir;
}

QString ProcessManager::hostExePath() const
{
    return m_hostExePath;
}

QString ProcessManager::clientExePath() const
{
    return m_clientExePath;
}

bool ProcessManager::autoDetectPaths()
{
    QString hostPath = findExecutable("quickdesk_host");
    QString clientPath = findExecutable("quickdesk_client");

    if (!hostPath.isEmpty()) {
        m_hostExePath = hostPath;
        LOG_INFO("Auto-detected host executable: {}", hostPath.toStdString());
    }

    if (!clientPath.isEmpty()) {
        m_clientExePath = clientPath;
        LOG_INFO("Auto-detected client executable: {}", clientPath.toStdString());
    }

    return !hostPath.isEmpty() && !clientPath.isEmpty();
}

bool ProcessManager::hostAutoRestart() const
{
    return m_hostAutoRestart;
}

void ProcessManager::setHostAutoRestart(bool enabled)
{
    if (m_hostAutoRestart != enabled) {
        m_hostAutoRestart = enabled;
        emit hostAutoRestartChanged();
    }
}

bool ProcessManager::clientAutoRestart() const
{
    return m_clientAutoRestart;
}

void ProcessManager::setClientAutoRestart(bool enabled)
{
    if (m_clientAutoRestart != enabled) {
        m_clientAutoRestart = enabled;
        emit clientAutoRestartChanged();
    }
}

QString ProcessManager::hostStatus() const
{
    return m_hostStatus;
}

QString ProcessManager::clientStatus() const
{
    return m_clientStatus;
}

void ProcessManager::resetHostRetryCount()
{
    m_hostRestartCount = 0;
}

void ProcessManager::resetClientRetryCount()
{
    m_clientRestartCount = 0;
}

void ProcessManager::onHostProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    LOG_INFO("Host process finished with exit code: {} status: {}", 
             exitCode, 
             (status == QProcess::NormalExit ? "NormalExit" : "CrashExit"));
    
    // Emit signal BEFORE destroying messaging so listeners can disconnect first
    emit hostProcessStopped(exitCode);
    m_hostMessaging.reset();
    
    // Check if we should auto-restart
    bool isAbnormalExit = (status == QProcess::CrashExit) || (exitCode != 0);
    
    if (m_hostStoppingIntentionally) {
        // User requested stop, don't restart
        m_hostStoppingIntentionally = false;
        setHostStatus("stopped");
        LOG_INFO("Host stopped intentionally, not restarting");
        return;
    }
    
    if (!m_hostAutoRestart) {
        setHostStatus("stopped");
        LOG_INFO("Host auto-restart disabled");
        return;
    }
    
    if (!isAbnormalExit) {
        // Normal exit with code 0, don't restart
        setHostStatus("stopped");
        LOG_INFO("Host exited normally, not restarting");
        return;
    }
    
    // Abnormal exit - try to restart
    if (m_hostRestartCount >= MAX_RESTART_ATTEMPTS) {
        setHostStatus("failed");
        QString error = QString("Host process crashed %1 times, giving up").arg(MAX_RESTART_ATTEMPTS);
        LOG_WARN("{}", error.toStdString());
        emit hostProcessError(error);
        return;
    }
    
    m_hostRestartCount++;
    int delay = calculateRestartDelay(m_hostRestartCount);
    
    setHostStatus(QString("restarting:%1").arg(m_hostRestartCount));
    LOG_INFO("Host crashed, restarting in {} ms (attempt {} of {})", 
             delay, m_hostRestartCount, MAX_RESTART_ATTEMPTS);
    
    emit hostProcessRestarting(m_hostRestartCount, MAX_RESTART_ATTEMPTS);
    m_hostRestartTimer.start(delay);
}

void ProcessManager::onClientProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    LOG_INFO("Client process finished with exit code: {} status: {}", 
             exitCode,
             (status == QProcess::NormalExit ? "NormalExit" : "CrashExit"));
    
    // Emit signal BEFORE destroying messaging so listeners can disconnect first
    emit clientProcessStopped(exitCode);
    m_clientMessaging.reset();
    
    // Check if we should auto-restart
    bool isAbnormalExit = (status == QProcess::CrashExit) || (exitCode != 0);
    
    if (m_clientStoppingIntentionally) {
        // User requested stop, don't restart
        m_clientStoppingIntentionally = false;
        setClientStatus("stopped");
        LOG_INFO("Client stopped intentionally, not restarting");
        return;
    }
    
    if (!m_clientAutoRestart) {
        setClientStatus("stopped");
        LOG_INFO("Client auto-restart disabled");
        return;
    }
    
    if (!isAbnormalExit) {
        // Normal exit with code 0, don't restart
        setClientStatus("stopped");
        LOG_INFO("Client exited normally, not restarting");
        return;
    }
    
    // Abnormal exit - try to restart
    if (m_clientRestartCount >= MAX_RESTART_ATTEMPTS) {
        setClientStatus("failed");
        QString error = QString("Client process crashed %1 times, giving up").arg(MAX_RESTART_ATTEMPTS);
        LOG_WARN("{}", error.toStdString());
        emit clientProcessError(error);
        return;
    }
    
    m_clientRestartCount++;
    int delay = calculateRestartDelay(m_clientRestartCount);
    
    setClientStatus(QString("restarting:%1").arg(m_clientRestartCount));
    LOG_INFO("Client crashed, restarting in {} ms (attempt {} of {})",
             delay, m_clientRestartCount, MAX_RESTART_ATTEMPTS);
    
    emit clientProcessRestarting(m_clientRestartCount, MAX_RESTART_ATTEMPTS);
    m_clientRestartTimer.start(delay);
}

void ProcessManager::onHostRestartTimer()
{
    LOG_INFO("Attempting to restart Host process...");
    if (!startHostProcess()) {
        // Failed to start, increment count and try again
        if (m_hostRestartCount < MAX_RESTART_ATTEMPTS) {
            m_hostRestartCount++;
            int delay = calculateRestartDelay(m_hostRestartCount);
            setHostStatus(QString("restarting:%1").arg(m_hostRestartCount));
            emit hostProcessRestarting(m_hostRestartCount, MAX_RESTART_ATTEMPTS);
            m_hostRestartTimer.start(delay);
        } else {
            setHostStatus("failed");
            emit hostProcessError("Failed to restart Host after multiple attempts");
        }
    }
}

void ProcessManager::onClientRestartTimer()
{
    LOG_INFO("Attempting to restart Client process...");
    if (!startClientProcess()) {
        // Failed to start, increment count and try again
        if (m_clientRestartCount < MAX_RESTART_ATTEMPTS) {
            m_clientRestartCount++;
            int delay = calculateRestartDelay(m_clientRestartCount);
            setClientStatus(QString("restarting:%1").arg(m_clientRestartCount));
            emit clientProcessRestarting(m_clientRestartCount, MAX_RESTART_ATTEMPTS);
            m_clientRestartTimer.start(delay);
        } else {
            setClientStatus("failed");
            emit clientProcessError("Failed to restart Client after multiple attempts");
        }
    }
}

bool ProcessManager::startProcess(QProcess* process, const QString& exePath, 
                                  const QString& processName, const QString& logDir)
{
    QFileInfo fileInfo(exePath);
    if (!fileInfo.exists() || !fileInfo.isExecutable()) {
        QString error = QString("%1 executable not found: %2").arg(processName, exePath);
        LOG_WARN("{}", error.toStdString());
        if (processName == "Host") {
            emit hostProcessError(error);
        } else {
            emit clientProcessError(error);
        }
        return false;
    }

    connect(process, &QProcess::readyReadStandardError, this, [process, processName]() {
        QByteArray err = process->readAllStandardError();
        if (!err.isEmpty()) {
            LOG_INFO("[ {}  stderr] {}", processName.toStdString(), err.toStdString());
        }
    });

    // Prepare command line arguments
    QStringList arguments;
    if (!logDir.isEmpty()) {
        // Use --log-dir=path format (Chromium style)
        arguments << QString("--log-dir=%1").arg(logDir);
    }

    process->setProgram(exePath);
    process->setArguments(arguments);
    process->setWorkingDirectory(fileInfo.absolutePath());
    
    // Native Messaging uses stdin/stdout
    process->setProcessChannelMode(QProcess::SeparateChannels);
    
    process->start();
    
    if (!process->waitForStarted(5000)) {
        QString error = QString("Failed to start %1 process: %2")
                        .arg(processName, process->errorString());
        LOG_WARN("{}", error.toStdString());
        if (processName == "Host") {
            emit hostProcessError(error);
        } else {
            emit clientProcessError(error);
        }
        return false;
    }

    return true;
}

QString ProcessManager::findExecutable(const QString& name)
{
    // Search paths in order of priority
    QStringList searchPaths;
    
    // 1. Same directory as Qt app
    searchPaths << QCoreApplication::applicationDirPath();
    
    // 2. Relative to workspace (for development)
    QString appDir = QCoreApplication::applicationDirPath();
    searchPaths << QDir(appDir).filePath("../../src/out/Debug");
    searchPaths << QDir(appDir).filePath("../../../src/out/Debug");
    searchPaths << QDir(appDir).filePath("../../../../src/out/Debug");
    
    // 3. Absolute development paths
    searchPaths << "D:/mycode/remoting/src/out/Debug";
    
#ifdef Q_OS_WIN
    QString exeName = name + ".exe";
#else
    QString exeName = name;
#endif

    for (const QString& path : searchPaths) {
        QString fullPath = QDir(path).filePath(exeName);
        QFileInfo fileInfo(fullPath);
        if (fileInfo.exists() && fileInfo.isExecutable()) {
            return fileInfo.absoluteFilePath();
        }
    }

    return QString();
}

int ProcessManager::calculateRestartDelay(int retryCount) const
{
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s (capped at 32s)
    int delay = BASE_RESTART_DELAY_MS * (1 << (retryCount - 1));
    return qMin(delay, 32000);
}

void ProcessManager::setHostStatus(const QString& status)
{
    if (m_hostStatus != status) {
        m_hostStatus = status;
        emit hostStatusChanged();
    }
}

void ProcessManager::setClientStatus(const QString& status)
{
    if (m_clientStatus != status) {
        m_clientStatus = status;
        emit clientStatusChanged();
    }
}

} // namespace quickdesk
