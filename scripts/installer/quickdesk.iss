; QuickDesk Inno Setup Script
; Version placeholders are replaced by package_qd_win.bat before compilation

#define MyAppName "QuickDesk"
#define MyAppPublisher "QuickCoder"
#define MyAppURL "https://github.com/user/QuickDesk"
#define MyAppExeName "QuickDesk.exe"
#define MyAppCopyright "Copyright (C) QuickCoder 2018-2038. All rights reserved."

; These are set via /D command line options from package_qd_win.bat
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#ifndef MyPublishDir
  #define MyPublishDir "..\..\publish\Release"
#endif
#ifndef MyOutputDir
  #define MyOutputDir "..\..\publish"
#endif
#ifndef MyIconPath
  #define MyIconPath "..\..\QuickDesk\res\QuickDesk.ico"
#endif

[Setup]
AppId={{B7E3F2A1-8C4D-4E5F-9A6B-1D2E3F4A5B6C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppCopyright={#MyAppCopyright}
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=no
OutputDir={#MyOutputDir}
OutputBaseFilename=QuickDesk-win-x64-setup
SetupIconFile={#MyIconPath}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
VersionInfoVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
WelcomeLabel2=This will install [name/ver] on your computer.%n%nPlease read the following important information before continuing.

[Code]
// Disclaimer page
var
  DisclaimerPage: TOutputMsgMemoWizardPage;

procedure InitializeWizard;
begin
  DisclaimerPage := CreateOutputMsgMemoPage(wpWelcome,
    'Disclaimer', 'Please read the following disclaimer carefully before proceeding.',
    'By clicking "Next", you acknowledge that you have read and agree to the following:',
    'DISCLAIMER'#13#10 +
    '=========='#13#10#13#10 +
    '1. This software is a remote desktop tool designed for lawful purposes only, '#13#10 +
    '   including but not limited to remote technical support, remote work, and '#13#10 +
    '   personal device management.'#13#10#13#10 +
    '2. You must obtain explicit authorization from the owner of any device before '#13#10 +
    '   initiating a remote connection. Unauthorized access to computer systems '#13#10 +
    '   may violate applicable laws and regulations.'#13#10#13#10 +
    '3. The developer assumes no responsibility or liability for any misuse of '#13#10 +
    '   this software, including but not limited to unauthorized access, data '#13#10 +
    '   theft, privacy violations, or any illegal activities conducted using '#13#10 +
    '   this software.'#13#10#13#10 +
    '4. You agree to comply with all applicable local, national, and international '#13#10 +
    '   laws and regulations when using this software.'#13#10#13#10 +
    '5. This software is provided "AS IS" without warranty of any kind, express '#13#10 +
    '   or implied. Use at your own risk.'#13#10#13#10 +
    '6. By proceeding with the installation, you acknowledge that you have read, '#13#10 +
    '   understood, and agreed to this disclaimer.'
  );
end;

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startmenuicon"; Description: "Create a Start Menu shortcut"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "{#MyPublishDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startmenuicon
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"; Tasks: startmenuicon
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
