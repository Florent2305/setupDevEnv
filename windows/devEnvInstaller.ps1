param ([Switch]$dev,
    [Switch]$devPlus,
    [Switch]$ci,
    [Switch]$fullset,
    [Switch]$putty,
    [Switch]$openssh,
    [string]$qtEmail,
    [string]$qtPass
 )

## ############################################################################
## INCLUDE POWERSHELL LIBRARIES                                              ##
## ############################################################################

Add-Type -AssemblyName System.IO.Compression.FileSystem
Import-Module BitsTransfer

## ############################################################################
## DEFINE INTERESTING FUNCTIONS                                              ##
## ############################################################################

function set-shortcut {
param ( [string]$SourceLnk, [string]$DestinationPath )
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($SourceLnk)
    $Shortcut.TargetPath = $DestinationPath
    $Shortcut.Save()
    }
    
function download {
param ( [string]$url, [string]$output )
    Write-Host "Download $output" -ForegroundColor green
    $start_time = Get-Date
    Invoke-WebRequest -Uri $url -OutFile $output                          #Invoke-WebRequest Way
    #(New-Object System.Net.WebClient).DownloadFile($url, $output)        #System.Net.WebClient Way
    #(New-Object System.Net.Http.HttpClient).DownloadFile($url, $output)  #System.Net.WebClient Way
    #Start-BitsTransfer -Source $url -Destination $output                 #BITS-Transfer Way
    Write-Output "Time taken: $((Get-Date).Subtract($start_time))"
}
    
function add-openSSH {
param ( [Switch]$enableOpenSSHServer )
    Add-WindowsCapability -Online -Name OpenSSH.Client*
    if($enableOpenSSHServer)
    {    
        Add-WindowsCapability -Online -Name OpenSSH.Server*
    }    
    New-Item -Path "$home" -Name ".ssh" -ItemType "directory" -Force
    $folder=get-item $home\.ssh -Force
    $folder.attributes="Hidden"
}    
    
function enable-symlinks {
    fsutil behavior query SymlinkEvaluation
}    

## ############################################################################
## PREPARE VARIABLES                                                         ##
## ############################################################################

Write-Host "`r`nPREPARATION PHASE" -ForegroundColor Yellow
$currentPath=Get-Location
$installQt = $true
if($openssh){
$SSHTOOL = "OpenSSH"
}else{
$SSHTOOL = "Plink"
}

if( ( (-not ($qtEmail -eq "")) -and (-not ($qtEmail -eq $null) ) ) -and ( (-not ($qtPass -eq "")) -and (-not ($qtPass -eq $null) ) ) )
{
    Write-Host "Qt5 will try to use QtCredential provided in parameters."
}
elseif([System.IO.File]::Exists("$currentPath\qtaccount.ini"))
{
    Write-Host "Qt5 will try to use provided qtaccount.ini"
    Copy-Item "$currentPath\qtaccount.ini" -Destination "$home\AppData\Roaming\Qt\qtaccount.ini"
}
elseif([System.IO.File]::Exists("$home\AppData\Roaming\Qt\qtaccount.ini"))
{
    Write-Host "Qt5 will try to be installed with the local system qtaccount.ini"  -ForegroundColor Red -BackgroundColor DarkGray;
}
else
{
    $installQt = $false
    Write-Host "`aQt5 can not be installed automatically."   -ForegroundColor Red  -BackgroundColor Black;
    Write-Host "Then installation of Qt5 will be skip.  "    -ForegroundColor Blue -BackgroundColor DarkGray;
    Write-Host "For the future, please use:             "    -ForegroundColor Blue -BackgroundColor DarkGray;
    Write-Host "qtEmail and qtPass script parameters    "    -ForegroundColor Blue -BackgroundColor DarkGray;
    Write-Host "OR                                      "    -ForegroundColor Blue -BackgroundColor DarkGray;
    Write-Host "provide qtaccount.ini in curreent folder."   -ForegroundColor Blue -BackgroundColor DarkGray;
}                       

## ############################################################################
## CREATE DIFFERENT CONFIGURATION FILES                                      ##
## ############################################################################

Write-Host "`r`nCREATE CONFIG-FILES PHASE" -ForegroundColor Yellow
$vsconfigTexteToWrite = "{
  `"version`": `"1.0`",
  `"components`": [
    `"Microsoft.VisualStudio.Component.CoreEditor`",
    `"Microsoft.VisualStudio.Workload.CoreEditor`",
    `"Microsoft.VisualStudio.Component.Roslyn.Compiler`",
    `"Microsoft.Component.MSBuild`",
    `"Microsoft.VisualStudio.Component.Static.Analysis.Tools`",
    `"Microsoft.VisualStudio.Component.Roslyn.LanguageServices`",
    `"Microsoft.VisualStudio.Component.TextTemplating`",
    `"Microsoft.VisualStudio.Component.Debugger.JustInTime`",
    `"Microsoft.VisualStudio.Component.NuGet`",
    `"Microsoft.VisualStudio.Component.TypeScript.3.1`",
    `"Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions`",
    `"Microsoft.VisualStudio.Component.JavaScript.TypeScript`",
    `"Microsoft.VisualStudio.Component.VC.CoreIde`",
    `"Microsoft.VisualStudio.Component.VC.Redist.14.Latest`",
    `"Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core`",
    `"Microsoft.VisualStudio.Component.VC.Tools.x86.x64`",
    `"Microsoft.VisualStudio.Component.Graphics.Win81`",
    `"Microsoft.VisualStudio.Component.Graphics.Tools`",
    `"Microsoft.VisualStudio.Component.VC.DiagnosticTools`",
    `"Microsoft.VisualStudio.Component.Windows10SDK.17763`",
    `"Microsoft.VisualStudio.Component.VC.CMake.Project`",
    `"Microsoft.VisualStudio.Component.VC.ATL`",
    `"Microsoft.VisualStudio.Component.VC.TestAdapterForBoostTest`",
    `"Microsoft.VisualStudio.Component.VC.TestAdapterForGoogleTest`",
    `"Microsoft.VisualStudio.Component.VC.Modules.x86.x64`",
    `"Microsoft.VisualStudio.Workload.NativeDesktop`",
    `"Microsoft.VisualStudio.Component.VC.ClangC2`"
  ]
}"
Remove-Item "$currentPath\.vsconfig" -ErrorAction Ignore
ADD-content -path "$currentPath\.vsconfig" -value "$vsconfigTexteToWrite"

$gitconfigTexteToWrite = "
[Setup]
Lang=default
Dir=C:\Program Files\Git
Group=Git
NoIcons=0
SetupType=default
Components=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh
Tasks=
EditorOption=Notepad++
CustomEditorPath=
PathOption=Cmd
SSHOption=OpenSSH
TortoiseOption=false
CURLOption=OpenSSL
CRLFOption=CRLFAlways
BashTerminalOption=MinTTY
GitPullBehaviorOption=Merge
UseCredentialManager=Enabled
PerformanceTweaksFSCache=Enabled
EnableSymlinks=Disabled
EnablePseudoConsoleSupport=Disabled
"
Remove-Item "$currentPath\gitconfig.inf" -ErrorAction Ignore
ADD-content -path "$currentPath\gitconfig.inf" -value "$gitconfigTexteToWrite"

$qt5TexteToWrite = "
var InstallComponents = [
    `"qt.qt5.5123.win64_msvc2017_64`"
]

var InstallPath = `"C:\\Qt`"

function Controller() {
    // It tends to complain about XCode, even if all is okay.
    installer.setMessageBoxAutomaticAnswer(`"XcodeError`", QMessageBox.Ok);

    installer.installationFinished.connect(proceed)
}

function logCurrentPage() {
    var pageName = page().objectName
    var pagePrettyTitle = page().title
    console.log(`"At page: `" + pageName + `" ('`" + pagePrettyTitle + `"')`")
}

function page() {
    return gui.currentPageWidget()
}

function proceed(button, delay) {
    gui.clickButton(button || buttons.NextButton, delay)
}

/// Skip welcome page
Controller.prototype.WelcomePageCallback = function() {
    logCurrentPage()
    // For some reason, delay is needed.  Two seconds seems to be enough.
    proceed(buttons.NextButton, 3000)
}
Controller.prototype.CredentialsPageCallback = function() {
    logCurrentPage();
    var widget = gui.currentPageWidget();
    var login = installer.environmentVariable(`"QT_CI_LOGIN`");
    var password = installer.environmentVariable(`"QT_CI_PASSWORD`");
    if(Boolean(`"$qtEmail`") && Boolean(`"$qtPass`")){
        login = `"$qtEmail`";
        password =`"$qtPass`";
    }else if (login === `"`" || password === `"`") {
        gui.clickButton(buttons.CommitButton);
    }else{    
        widget.loginWidget.EmailLineEdit.setText(login);
        widget.loginWidget.PasswordLineEdit.setText(password);
	}
    gui.clickButton(buttons.CommitButton);
}

Controller.prototype.ObligationsPageCallback = function() {
    var page = gui.pageWidgetByObjectName(`"ObligationsPage`");
    page.obligationsAgreement.setChecked(true);
    page.completeChanged();
    gui.clickButton(buttons.NextButton);
}

/// Skip introduction page
Controller.prototype.IntroductionPageCallback = function() {
    logCurrentPage()
    proceed()
}

/// Set target directory
Controller.prototype.TargetDirectoryPageCallback = function() {
    logCurrentPage()
    page().TargetDirectoryLineEdit.text = InstallPath
    proceed()
}

Controller.prototype.ComponentSelectionPageCallback = function() {
    logCurrentPage()
    // Deselect whatever was default, and can be deselected.
    page().deselectAll()

    InstallComponents.forEach(function(component) {
        page().selectComponent(component)
    })

    proceed()
}

/// Agree license
Controller.prototype.LicenseAgreementPageCallback = function() {
    logCurrentPage()
    page().AcceptLicenseRadioButton.checked = true
    gui.clickButton(buttons.NextButton)
}

/// Windows-specific, skip it
Controller.prototype.StartMenuDirectoryPageCallback = function() {
    logCurrentPage()
    gui.clickButton(buttons.NextButton)
}

/// Skip confirmation page
Controller.prototype.ReadyForInstallationPageCallback = function() {
    logCurrentPage()
    proceed()
}

/// Installation in progress, do nothing
Controller.prototype.PerformInstallationPageCallback = function() {
    logCurrentPage()
}

Controller.prototype.FinishedPageCallback = function() {
    logCurrentPage()
    // Deselect `"launch QtCreator`"
    page().RunItCheckBox.checked = false
    proceed(buttons.FinishButton)
}

/// Question for tracking usage data, refuse it
Controller.prototype.DynamicTelemetryPluginFormCallback = function() {
    logCurrentPage()
    console.log(Object.keys(page().TelemetryPluginForm.statisticGroupBox))
    var radioButtons = page().TelemetryPluginForm.statisticGroupBox
    radioButtons.disableStatisticRadioButton.checked = true
    proceed()
}"
Remove-Item "$currentPath\control_script.qs" -ErrorAction Ignore
ADD-content -path "$currentPath\control_script.qs" -value "$qt5TexteToWrite"

## ############################################################################
## DOWNLOAD PHASE                                                            ##
## ############################################################################

Write-Host "`r`nDOWNLOAD PHASE" -ForegroundColor Yellow
download "https://download.visualstudio.microsoft.com/download/pr/5f6dfbf7-a8f7-4f36-9b9e-928867c28c08/da9f4f32990642c17a4188493949adcfd785c4058d7440b9cfe3b291bbb17424/vs_Community.exe" "vs_Community.exe"
download "http://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe"             "qt-setup.exe"
download "https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.7z"                                   "boost.7z"
download "https://github.com/Kitware/CMake/releases/download/v3.14.3/cmake-3.14.3-win64-x64.msi"                   "cmake-setup.msi"
download "https://www.7-zip.org/a/7z1900-x64.exe"                                                                  "7z-setup.exe"
download "https://www.7-zip.org/a/7z1900-x64.msi"                                                                  "7z-setup.msi"
download "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.9/npp.7.9.Installer.x64.exe" "npp-setup.exe"
download "https://github.com/git-for-windows/git/releases/download/v2.28.0.windows.1/Git-2.28.0-64-bit.exe"        "Git-setup.exe"

if($putty -or $fullset){
download "https://the.earth.li/~sgtatham/putty/0.73/w64/putty-64bit-0.73-installer.msi"                            "putty-setup.msi"
}

if($dev -or $devPlus -or $fullset){
download "https://download.tortoisegit.org/tgit/2.8.0.0/TortoiseGit-2.8.0.0-64bit.msi"                             "TortoiseGit-setup.msi"
download "https://download.sysinternals.com/files/ProcessExplorer.zip"                                             "ProcessExplorer.zip"
}

if($devPlus -or $fullset){
download "https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/LLVM-10.0.0-win64.exe"             "LLVM-setup.exe"
download "https://schinagl.priv.at/nt/hardlinkshellext/HardLinkShellExt_X64.exe"                                   "HardLinkShellExt-setup.exe"
download "http://www.dependencywalker.com/depends22_x64.zip"                                                       "dependencywalker.zip"
download "https://netcologne.dl.sourceforge.net/project/winmerge/stable/2.16.8/WinMerge-2.16.8-x64-Setup.exe"      "WinMerge-setup.exe"
}

if($ci -or $fullset)
{    
    download "https://netcologne.dl.sourceforge.net/project/nsis/NSIS%203/3.06.1/nsis-3.06.1-setup.exe"                 "nsis-setup.exe"
    download "https://www2.graphviz.org/Packages/stable/windows/10/cmake/Release/x64/graphviz-install-2.44.1-win64.exe" "graphviz-setup.exe"
    download "http://doxygen.nl/files/doxygen-1.8.20-setup.exe"                                                         "doxygen-setup.exe"
}

## ############################################################################
## INSTALLATION PHASE                                                        ##
## ############################################################################

Write-Host "`r`nINSTALATION PHASE" -ForegroundColor Yellow
## 7-Zip
Write-Host "Installing 7Zip" -ForegroundColor green
$process = Start-Process -FilePath "$currentPath\7z-setup.exe" -ArgumentList "/S" -Wait -PassThru
Write-Output $process.ExitCode

## Boost
Write-Host "Installing Boost" -ForegroundColor green
$process = Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x", "$currentPath\boost.7z", "-oC:\boost", "-y" -Wait -PassThru
Write-Output $process.ExitCode

## CMake
Write-Host "Installing CMake" -ForegroundColor green
$process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", "$currentPath\cmake-setup.msi", "/qn", "ADD_CMAKE_TO_PATH=`"System`"" -Wait -PassThru
Write-Output $process.ExitCode

## Notepad++
Write-Host "Installing Notepad++" -ForegroundColor green
$process = Start-Process -FilePath "$currentPath\npp-setup.exe" -ArgumentList "/S" -Wait -PassThru
Write-Output $process.ExitCode

## GIT
Write-Host "Installing GIT for Windows" -ForegroundColor green
$process = Start-Process -FilePath "$currentPath\Git-setup.exe" -ArgumentList "/VERYSILENT", "/LOADINF=$currentPath\gitconfig.inf" -Wait -PassThru
Write-Output $process.ExitCode

## VisualStudio 2017 Community
Write-Host "Installing VisualStudio 2017 Community" -ForegroundColor green
$process = Start-Process -FilePath "$currentPath\vs_Community.exe" -ArgumentList "--config", "$currentPath\.vsconfig", "--quiet", "--norestart", "--wait" -Wait -PassThru
Write-Output $process.ExitCode 

## Qt5
if($installQt)
{
    Write-Host "Installing Qt5" -ForegroundColor green
    $process = Start-Process -FilePath "$currentPath\qt-setup.exe" -ArgumentList "--verbose", "--script", "control_script.qs" -Wait -PassThru
    Write-Output $process.ExitCode
}

## Putty
if($putty -or $fullset)
{
    Write-Host "Installing Putty" -ForegroundColor green
    $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", "$currentPath\putty-setup.msi", "/qn" -Wait -PassThru
    Write-Output $process.ExitCode
}

## OpenSSH
if(  (-not $putty) -or $openssh -or $fullset)
{
    Write-Host "Installing OpenSSH" -ForegroundColor green
    add-openSSH -enableOpenSSHServer ($ci -or $fullset)    
    Write-Host "OpenSSH installation finished"
}

if($dev -or $devPlus -or $fullset)
{
    ## ProcessExplorer
    Write-Host "Installing Process Explorer" -ForegroundColor green
    #[System.IO.Compression.ZipFile]::ExtractToDirectory("$currentPath\ProcessExplorer.zip", "$Env:windir\system32\ProcessExplorer")
    Expand-Archive -Path "$currentPath\ProcessExplorer.zip" -DestinationPath "$Env:windir\system32\ProcessExplorer" -Force
    set-shortcut "$home\Desktop\process explorer.lnk" "$Env:windir\system32\ProcessExplorer\procexp.exe"
    
    ## Tortoise Git
    Write-Host "Installing Tortoise GIT" -ForegroundColor green
    $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i", "$currentPath\TortoiseGit-setup.msi", "/qn", "SSHTOOL=`"$SSHTOOL`"" -Wait -PassThru
    Write-Output $process.ExitCode
}

if($devPlus -or $fullset)
{
    ## LLVM
    Write-Host "Installing LLVM" -ForegroundColor green
    $process = Start-Process -FilePath "$currentPath\LLVM-setup.exe" -ArgumentList "/S" -Wait -PassThru
    Write-Output $process.ExitCode
    
    ## HardLink Shell Extion
    Write-Host "Installing HardLink Shell Extion" -ForegroundColor green
    $process = Start-Process -FilePath "$currentPath\HardLinkShellExt-setup.exe" -ArgumentList "/S" -Wait -PassThru
    Write-Output $process.ExitCode
    
    ## WinMerge
    Write-Host "Installing WinMerge" -ForegroundColor green
    $process = Start-Process -FilePath "$currentPath\WinMerge-setup.exe" -ArgumentList "/VERYSILENT" -Wait -PassThru
    Write-Output $process.ExitCode
    
    ## Dependency walker
    Write-Host "Installing WinMerge" -ForegroundColor green
    #[System.IO.Compression.ZipFile]::ExtractToDirectory("$currentPath\dependencywalker.zip", "$Env:windir\system32\dependencywalker")
    Expand-Archive -Path "$currentPath\dependencywalker.zip" -DestinationPath "$Env:windir\system32\dependencywalker" -Force
    set-shortcut "$home\Desktop\Dependency walker.lnk" "$Env:windir\system32\dependencywalker\depends.exe"
}

if($ci -or $fullset)
{    
    ## NSIS
    Write-Host "Installing NSIS" -ForegroundColor green
    $process = Start-Process -FilePath "$currentPath\nsis-setup.exe" -ArgumentList "/S" -Wait -PassThru
    Write-Output $process.ExitCode
    
    ## GraphViz
    Write-Host "Installing GraphViz" -ForegroundColor green
    $process = Start-Process -FilePath "$currentPath\graphviz-setup.exe" -ArgumentList "/S" -Wait -PassThru
    Write-Output $process.ExitCode
    
    ## Doxygen
    Write-Host "Installing Doxygen" -ForegroundColor green
    $process = Start-Process -FilePath "$currentPath\doxygen-setup.exe" -ArgumentList "/VERYSILENT" -Wait -PassThru
    Write-Output $process.ExitCode
}

## ############################################################################
## POST INSTALLATION                                                         ##
## ############################################################################

Write-Host "`r`nPost installation phase" -ForegroundColor Yellow

Write-Host "Export Environment variables" -ForegroundColor green
## Git-SSH variable
if($putty -and -not ( $openssh -or $fullset) )
{
    if($dev -or $devPlus)
    {
        [System.Environment]::SetEnvironmentVariable('GIT_SSH','C:\Program Files\TortoiseGit\bin\TortoiseGitPlink.exe',[System.EnvironmentVariableTarget]::Machine)
    }
    else
    {    
        [System.Environment]::SetEnvironmentVariable('GIT_SSH','C:\Program Files\PuTTY\plink.exe',[System.EnvironmentVariableTarget]::Machine)
    }
}
elseif($openssh -or $fullset)
{
    [System.Environment]::SetEnvironmentVariable('GIT_SSH','C:\Windows\System32\OpenSSH\ssh.exe',[System.EnvironmentVariableTarget]::User)    
}

## Qt5 variable
[System.Environment]::SetEnvironmentVariable('Qt5_DIR','C:\Qt\5.12.3\msvc2017_64\lib\cmake\Qt5',[System.EnvironmentVariableTarget]::User)


Write-Host "Set .SSH folder" -ForegroundColor green

New-Item -Path "$home" -Name ".ssh" -ItemType "directory" -Force

if([System.IO.Directory]::Exists("$currentPath\.ssh\"))
{
    Copy-Item -Path "$currentPath\.ssh\*" -Destination "$home\.ssh\" -recurse -Force
}

if($openssh -or $fullset)
{
    Get-Service ssh-agent
    Get-Service -Name ssh-agent | Set-Service -StartupType Manual
    ssh-agent.exe
    if([System.IO.File]::Exists("$currentPath\qtaccount.ini"))
    {
        ssh-add "$home\.ssh\id_rsa"
    }    
}

Write-Host "END OF INSTALLATION" -ForegroundColor Yellow