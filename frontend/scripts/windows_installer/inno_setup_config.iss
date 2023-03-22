[Setup]
AppName=AppFlowy
AppVersion={#AppVersion}
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
DefaultDirName={autopf}\AppFlowy\
DefaultGroupName=AppFlowy
SetupIconFile=flowy_logo.ico
UninstallDisplayIcon={app}\AppFlowy.exe
UninstallDisplayName=AppFlowy
AppPublisher=AppFlowy-IO
VersionInfoVersion={#AppVersion}

[Files]
Source: "AppFlowy\AppFlowy.exe";DestDir: "{app}";DestName: "AppFlowy.exe"
Source: "AppFlowy\*";DestDir: "{app}"
Source: "AppFlowy\data\*";DestDir: "{app}\data\"; Flags: recursesubdirs

[Icons]
Name: "{group}\AppFlowy";Filename: "{app}\AppFlowy.exe"