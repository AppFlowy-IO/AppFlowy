[Setup]
AppName=AppFlowy
AppVersion={#AppVersion}
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
DefaultDirName={autopf}\AppFlowy\
DefaultGroupName=AppFlowy
SetupIconFile=flowy_logo.ico
UninstallDisplayIcon={app}\appflowy_flutter.exe
UninstallDisplayName=AppFlowy
AppPublisher=AppFlowy-IO
VersionInfoVersion={#AppVersion}

[Files]
Source: "AppFlowy\appflowy_flutter.exe";DestDir: "{app}";DestName: "appflowy_flutter.exe"
Source: "AppFlowy\*";DestDir: "{app}"
Source: "AppFlowy\data\*";DestDir: "{app}\data\"; Flags: recursesubdirs

[Icons]
Name: "{group}\AppFlowy";Filename: "{app}\appflowy_flutter.exe"