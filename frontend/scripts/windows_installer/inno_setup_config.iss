[Setup]
AppName=AppFlowy
AppVersion={#AppVersion}
AppPublisher=AppFlowy-IO
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
DefaultDirName={autopf}\AppFlowy\
DefaultGroupName=AppFlowy
SetupIconFile=flowy_logo.ico
UninstallDisplayIcon={app}\AppFlowy.exe
UninstallDisplayName=AppFlowy
VersionInfoVersion={#AppVersion}
UsePreviousAppDir=no

[Files]
Source: "AppFlowy\AppFlowy.exe"; DestDir: "{app}"; DestName: "AppFlowy.exe"; Flags: ignoreversion
Source: "AppFlowy\*";DestDir: "{app}"
Source: "AppFlowy\data\*";DestDir: "{app}\data\"; Flags: recursesubdirs

[Icons]
Name: "{userdesktop}\AppFlowy"; Filename: "{app}\AppFlowy.exe"
Name: "{group}\AppFlowy"; Filename: "{app}\AppFlowy.exe"

[Registry]
Root: HKCR; Subkey: "AppFlowy"; ValueType: "string"; ValueData: "URL:Custom Protocol"; Flags: uninsdeletekey
Root: HKCR; Subkey: "AppFlowy"; ValueType: "string"; ValueName: "URL Protocol"; ValueData: ""
Root: HKCR; Subkey: "AppFlowy\DefaultIcon"; ValueType: "string"; ValueData: "{app}\AppFlowy.exe,0"
Root: HKCR; Subkey: "AppFlowy\shell\open\command"; ValueType: "string"; ValueData: """{app}\AppFlowy.exe"" ""%1"""