[Setup]
AppName=AppFlowy
AppVersion={#AppVersion}
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
DefaultDirName={autopf}\AppFlowy\
DefaultGroupName=AppFlowy
SetupIconFile=flowy_logo.ico
UninstallDisplayIcon={app}\app_flowy.exe
UninstallDisplayName=AppFlowy
AppPublisher=AppFlowy-IO
VersionInfoVersion={#AppVersion}

[Files]
Source: "AppFlowy\app_flowy.exe";DestDir: "{app}";DestName: "app_flowy.exe"
Source: "AppFlowy\*";DestDir: "{app}"
Source: "AppFlowy\data\*";DestDir: "{app}\data\"; Flags: recursesubdirs

[Icons]
Name: "{group}\AppFlowy";Filename: "{app}\app_flowy.exe"