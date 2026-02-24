@echo off

echo=
echo=
echo ---------------------------------------------------------------
echo check ENV
echo ---------------------------------------------------------------

:: example: C:\QtPro\6.8.4
set ENV_QT_PATH=C:\QtPro\6.8.4
:: example: C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat
set ENV_VCVARSALL=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat
:: VC Runtime DLL version
set ENV_VCRUNTIME_VERSION=14.42.34433

echo ENV_VCVARSALL %ENV_VCVARSALL%
echo ENV_QT_PATH %ENV_QT_PATH%
echo ENV_VCRUNTIME_VERSION %ENV_VCRUNTIME_VERSION%

:: 获取脚本绝对路径
set script_path=%~dp0
:: 进入脚本所在目录,因为这会影响脚本中执行的程序的工作目录
set old_cd=%cd%
cd /d %~dp0

:: 启动参数声明和默认值
SETLOCAL EnableDelayedExpansion
set cpu_mode=x64
set build_mode=Release
set errno=1

echo=
echo=
echo ---------------------------------------------------------------
echo 解析命令行参数
echo ---------------------------------------------------------------

:: 遍历所有参数
:parse_args
if "%1"=="" goto args_done

REM 检查编译类型（不区分大小写）
if /i "%1"=="debug" set build_mode=Debug
if /i "%1"=="release" set build_mode=Release

shift
goto parse_args
:args_done

echo [*] 架构: %cpu_mode%
echo [*] 编译类型: %build_mode%
echo=

:: 设置路径
set qt_msvc_path=%ENV_QT_PATH%\msvc2022_64\bin
set publish_path=%script_path%..\publish\%build_mode%\
set release_path=%script_path%..\output\x64\%build_mode%
set src_out_path=%script_path%..\..\src\out\%build_mode%
set vcvarsall="%ENV_VCVARSALL%"
set vcruntime_path=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Redist\MSVC\%ENV_VCRUNTIME_VERSION%\x64\Microsoft.VC143.CRT

echo [*] Qt MSVC 路径: %qt_msvc_path%
echo [*] 发布路径: %publish_path%
echo [*] 输出路径: %release_path%
echo [*] src/out 路径: %src_out_path%
echo [*] VCRuntime 路径: %vcruntime_path%
echo=

set PATH=%qt_msvc_path%;%PATH%

:: 注册vc环境
call %vcvarsall% x64

echo=
echo=
echo ---------------------------------------------------------------
echo 开始发布
echo ---------------------------------------------------------------

:: 检查输出路径是否存在
if not exist %release_path% (
    echo [?] 错误: 输出路径不存在: %release_path%
    echo [?] 请先运行 build_qd_win.bat %build_mode% 进行编译
    goto return
)

:: 清理并创建发布目录
if exist %publish_path% (
    echo [*] 清理旧的发布目录...
    rmdir /s/q %publish_path%
)
echo [*] 创建发布目录: %publish_path%
mkdir %publish_path%

:: 复制要发布的程序文件
echo [*] 复制程序文件...
xcopy %release_path% %publish_path% /E /Y

:: 复制src/out目录下的host和client程序
echo [*] 复制 host 和 client 程序...
if not exist %src_out_path% (
    echo [?] 警告: src/out 路径不存在: %src_out_path%
) else (
    if exist "%src_out_path%\quickdesk_core.dll" (
        copy /Y "%src_out_path%\quickdesk_core.dll" %publish_path%\ >nul
        echo [*] 已复制 quickdesk_core.dll
    ) else (
        echo [?] 警告: 未找到 quickdesk_core.dll
    )

    if exist "%src_out_path%\quickdesk_host.exe" (
        copy /Y "%src_out_path%\quickdesk_host.exe" %publish_path%\ >nul
        echo [*] 已复制 quickdesk_host.exe
    ) else (
        echo [?] 警告: 未找到 quickdesk_host.exe
    )

    if exist "%src_out_path%\quickdesk_host_uiaccess.exe" (
        copy /Y "%src_out_path%\quickdesk_host_uiaccess.exe" %publish_path%\ >nul
        echo [*] 已复制 quickdesk_host_uiaccess.exe
    ) else (
        echo [?] 警告: 未找到 quickdesk_host_uiaccess.exe
    )
    
    if exist "%src_out_path%\quickdesk_client.exe" (
        copy /Y "%src_out_path%\quickdesk_client.exe" %publish_path%\ >nul
        echo [*] 已复制 quickdesk_client.exe
    ) else (
        echo [?] 警告: 未找到 quickdesk_client.exe
    )    

    if exist "%src_out_path%\icudtl.dat" (
        copy /Y "%src_out_path%\icudtl.dat" %publish_path%\ >nul
        echo [*] 已复制 icudtl.dat
    ) else (
        echo [?] 警告: 未找到 icudtl.dat
    )
)
echo=

:: 添加qt依赖包（指定qml路径）
echo [*] 运行 windeployqt 添加 Qt 依赖...
windeployqt --qmldir %script_path%..\QuickDesk\qml %publish_path%\QuickDesk.exe

:: 删除多余qt依赖包
echo [*] 清理多余的 Qt 依赖...
if exist %publish_path%\iconengines (
    rmdir /s/q %publish_path%\iconengines
)
if exist %publish_path%\translations (
    rmdir /s/q %publish_path%\translations
)
if exist %publish_path%\generic (
    rmdir /s/q %publish_path%\generic
)
if exist %publish_path%\logs (
    rmdir /s/q %publish_path%\logs
)
if exist %publish_path%\db (
    rmdir /s/q %publish_path%\db
)
if exist %publish_path%\platforminputcontexts (
    rmdir /s/q %publish_path%\platforminputcontexts
)
if exist %publish_path%\qmltooling (
    rmdir /s/q %publish_path%\qmltooling
)

:: 清理imageformats，保留需要的dll
if exist %publish_path%\imageformats (
    echo [*] 清理 imageformats...
    del /q %publish_path%\imageformats\qgif.dll 2>nul
    del /q %publish_path%\imageformats\qicns.dll 2>nul
    del /q %publish_path%\imageformats\qico.dll 2>nul
    del /q %publish_path%\imageformats\qsvg.dll 2>nul
    del /q %publish_path%\imageformats\qtga.dll 2>nul
    del /q %publish_path%\imageformats\qtiff.dll 2>nul
    del /q %publish_path%\imageformats\qwbmp.dll 2>nul
    del /q %publish_path%\imageformats\qwebp.dll 2>nul
)

:: 清理sqldrivers，只保留sqlite
if exist %publish_path%\sqldrivers (
    echo [*] 清理 sqldrivers（保留sqlite）...
    for %%f in (%publish_path%\sqldrivers\*.dll) do (
        echo %%~nxf | findstr /i "sqlite" >nul
        if errorlevel 1 (
            del /q "%%f" 2>nul
        )
    )
)

:: 删除不需要的dll和文件
echo [*] 删除不需要的文件...
del /q %publish_path%\Qt6VirtualKeyboard.dll 2>nul
del /q %publish_path%\QuickDesk.exe.manifest 2>nul
del /q %publish_path%\*.exp 2>nul
del /q %publish_path%\*.lib 2>nul

:: 删除不需要的Qt6 dll
del /q %publish_path%\dxcompiler.dll 2>nul
del /q %publish_path%\opengl32sw.dll 2>nul
del /q %publish_path%\Qt6QuickControls2FluentWinUI3StyleImpl.dll 2>nul
del /q %publish_path%\Qt6QuickControls2Fusion.dll 2>nul
del /q %publish_path%\Qt6QuickControls2FusionStyleImpl.dll 2>nul
del /q %publish_path%\Qt6QuickControls2Imagine.dll 2>nul
del /q %publish_path%\Qt6QuickControls2ImagineStyleImpl.dll 2>nul
del /q %publish_path%\Qt6QuickControls2Material.dll 2>nul
del /q %publish_path%\Qt6QuickControls2MaterialStyleImpl.dll 2>nul
del /q %publish_path%\Qt6QuickControls2Universal.dll 2>nul
del /q %publish_path%\Qt6QuickControls2UniversalStyleImpl.dll 2>nul
del /q %publish_path%\Qt6QuickControls2WindowsStyleImpl.dll 2>nul

:: 删除vc_redist，自己copy vcruntime dll
echo [*] 删除 vc_redist 安装包...
del /q %publish_path%\vc_redist.x64.exe 2>nul

:: copy vcruntime dll from VC Redist directory
echo [*] 复制 VCRuntime DLL...
if not exist "%vcruntime_path%" (
    echo [?] 警告: VCRuntime 路径不存在: %vcruntime_path%
    echo [?] 请检查 ENV_VCRUNTIME_VERSION 是否正确
) else (
    copy /Y "%vcruntime_path%\msvcp140.dll" %publish_path%\ >nul
    copy /Y "%vcruntime_path%\msvcp140_1.dll" %publish_path%\ >nul
    copy /Y "%vcruntime_path%\msvcp140_2.dll" %publish_path%\ >nul
    copy /Y "%vcruntime_path%\vcruntime140.dll" %publish_path%\ >nul
    copy /Y "%vcruntime_path%\vcruntime140_1.dll" %publish_path%\ >nul
    echo [*] VCRuntime DLL 复制完成
)

echo=
echo=
echo ---------------------------------------------------------------
echo [?] 发布完成！
echo ---------------------------------------------------------------
echo [*] 发布目录: %publish_path%
echo=

set errno=0

:return
cd %old_cd%
exit /B %errno%

ENDLOCAL