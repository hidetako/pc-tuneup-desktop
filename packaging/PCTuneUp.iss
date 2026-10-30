; PC TuneUp インストーラー (Inno Setup 6)
; ビルドは build\Build.ps1 から行います。単体で使う場合は次の 3 つを渡してください:
;   ISCC.exe /DAppVersion=1.0.0 /DStageDir=...\dist\stage\PCTuneUp /DOutputDir=...\dist /DRepoRoot=... packaging\PCTuneUp.iss

#ifndef AppVersion
  #error AppVersion が指定されていません (/DAppVersion=1.0.0)
#endif
#ifndef StageDir
  #error StageDir が指定されていません (/DStageDir=...)
#endif
#ifndef OutputDir
  #error OutputDir が指定されていません (/DOutputDir=...)
#endif
#ifndef RepoRoot
  #error RepoRoot が指定されていません (/DRepoRoot=...)
#endif

#define AppName "PC TuneUp"
#define AppPublisher "hidetako"
#define AppURL "https://github.com/hidetako/pc-tuneup"
#define AppExe "PCTuneUp.exe"

[Setup]
; AppId は変えないこと。変えると「更新」ではなく「別アプリ」として二重にインストールされる
AppId={{A7F3C2E8-5B41-4D96-9E27-3C8D1F6A0B54}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName} {#AppVersion}
OutputDir={#OutputDir}
OutputBaseFilename=PCTuneUp-{#AppVersion}-setup
SetupIconFile={#StageDir}\pc_maintenance_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; 修復には管理者権限が要るので、インストールも管理者で行う
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
; Windows 10 1809 以降
MinVersion=10.0.17763
DisableProgramGroupPage=yes
LicenseFile={#RepoRoot}\LICENSE

[Languages]
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "english";  MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "weeklytask";  Description: "毎週の自動メンテナンスを登録する (毎週土曜 10:00、低リスクの問題だけを自動修復)"; Flags: unchecked

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
; 週次メンテナンスのタスク登録 (任意)
Filename: "powershell.exe"; \
  Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\PCTuneUp.ps1"" -InstallSchedule"; \
  StatusMsg: "毎週の自動メンテナンスを登録しています..."; \
  Flags: runhidden waituntilterminated; Tasks: weeklytask
; インストール直後に起動するか
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; \
  Flags: nowait postinstall skipifsilent

[UninstallRun]
; 登録していた場合に備えて、アンインストール時にタスクを消す (無ければ何も起きない)
Filename: "powershell.exe"; \
  Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\PCTuneUp.ps1"" -UninstallSchedule"; \
  Flags: runhidden waituntilterminated; RunOnceId: "RemoveWeeklyTask"

[Messages]
japanese.WelcomeLabel2=%1 をこのコンピューターにインストールします。%n%nWindows の不要ファイル・設定・レジストリ・セキュリティを点検し、見つかった問題を修復するツールです。Windows 標準の機能だけで動き、常駐しません。%n%n続行する前に、ほかのアプリケーションをすべて終了してください。
