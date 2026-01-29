#pragma once

#include <QObject>

class ConfigViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(int darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    ConfigViewModel(QObject* parent = nullptr);
    virtual ~ConfigViewModel();

    int darkTheme();
    void setDarkTheme(int value);
    
    QString language();
    void setLanguage(const QString& value);

signals:
    void darkThemeChanged(int value);
    void languageChanged(const QString& value);
};
