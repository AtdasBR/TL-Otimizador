; ============================================================
;  TL Optimizer - Inno Setup Installer Script
;  Compila com: ISCC.exe tloptimizer.iss
;  Requer Inno Setup 6 (https://jrsoftware.org/isdl.php)
; ============================================================

#define MyAppName "TL Optimizer"
#define MyAppVersion "1.7.2"
#define MyAppPublisher "AtdasBR"
#define MyAppURL "https://github.com/AtdasBR/TL-Otimizador"
#define MyAppExeName "TLOptimizer.exe"

[Setup]
AppId={{8F3C2A1B-4D5E-4F6A-9B1C-2D3E4F5A6B7C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\deploy\assets\terms.txt
InfoBeforeFile=..\deploy\assets\features.txt
OutputDir=..\build\installer
OutputBaseFilename=TLOptimizer-Setup-{#MyAppVersion}
SetupIconFile=..\deploy\icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=windows11 dark
WizardImageFile=..\deploy\assets\wizard-side.bmp
WizardSmallImageFile=..\deploy\assets\wizard-small.bmp
WizardImageBackColor=clBlack
WizardSmallImageBackColor=clBlack
DisableWelcomePage=no
ArchitecturesInstallIn64BitMode=x64os
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
AppMutex=TLOptimizerMutex

[Languages]
Name: "portuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
; Launcher principal (self-contained, já inclui o .NET).
Source: "..\build\publish\TLOptimizer.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\publish\*.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\publish\icon.ico"; DestDir: "{app}"; Flags: ignoreversion
; Script do otimizador (o launcher atualiza isto em runtime).
Source: "..\build\publish\scripts\*"; DestDir: "{localappdata}\TLOptimizer"; Flags: ignoreversion uninsneveruninstall
; Logos dos aplicativos do gerenciador de instalacao
Source: "..\build\publish\assets\logos\*"; DestDir: "{app}\assets\logos"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; WorkingDir: "{app}"

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na Área de Trabalho"; GroupDescription: "Atalhos:"; Flags: unchecked

[Registry]
; Marca a instalação para que o launcher saiba que veio do instalador.
Root: HKLM; Subkey: "Software\AtdasBR\TLOptimizer"; ValueType: string; ValueName: "Installed"; ValueData: "1"; Flags: uninsdeletekey

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Iniciar {#MyAppName}"; Flags: nowait postinstall

[UninstallDelete]
Type: dirifempty; Name: "{localappdata}\TLOptimizer"

[Messages]
portuguese.SetupAppTitle=Configuração do {#MyAppName}
portuguese.WelcomeLabel1=Bem-vindo ao assistente de instalação do {#MyAppName}
portuguese.WelcomeLabel2=Este assistente irá instalar o {#MyAppName} em seu computador.
portuguese.SelectDirLabel3=Manutenção e otimização de Windows com um clique — gerenciador de aplicativos e ajustes avançados.
portuguese.ReadyLabel1=O {#MyAppName} está pronto para ser instalado.
portuguese.ReadyLabel2b=Clique em Instalar para continuar.
portuguese.FinishedLabel=O {#MyAppName} foi instalado com sucesso.
