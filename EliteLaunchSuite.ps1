# ==========================================================
# Elite Dangerous Launch Suite   ||||||||||||||||||||||||||
# v1.4 by CMDR Coyote Bongwater  ||||||||||||||||||||||||||
# ==========================================================

#first things first: force 64bit
if (-not [Environment]::Is64BitProcess) {
    Write-Host "Restarting in 64-bit PowerShell..."
    Start-Process "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

 # ==========================
 # Vars |||||||||||||||||||||
 # ==========================

#window name
$Host.UI.RawUI.WindowTitle = "Elite: Dangerous | One-click launch"

#locate elite thru steam
$EliteAppId = 359320

#pathfinding black magic
$LocalAppData    = $env:LOCALAPPDATA
$ProgramFilesX86 = ${env:ProgramFiles(x86)}

$LaunchDelaySeconds = 3

#array to track & close all apps on game exit
$LaunchedProcesses = @()

#todo put back edhm-ui with new pathfinding
$Apps = @(
    @{
        Name    = "EDMarketConnector"
        Process = "EDMarketConnector"
        Path    = Join-Path $ProgramFilesX86 "EDMarketConnector\EDMarketConnector.exe"
    },
    @{
        Name    = "SrvSurvey"
        Process = "SrvSurvey"
        Path    = {
            Get-ChildItem `
                -Path (Join-Path $LocalAppData "Apps\2.0") `
                -Filter "SrvSurvey.exe" `
                -Recurse `
                -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        }
    },
    @{
        Name    = "OdysseyMaterialsHelper"
        Process = "Elite Dangerous Odyssey Materials Helper"
        Path    = Join-Path $LocalAppData `
            "Elite Dangerous Odyssey Materials Helper Launcher\program\Elite Dangerous Odyssey Materials Helper.exe"
    },
    @{
        Name    = "EDCoPilot"
        Process = "EDCoPilot"
        Path    = "C:\EDCoPilot\EDCoPilot.exe"
    }
)


 # ===============================
 # Helper Functions ||||||||||||||
 # ===============================

function Write-Log {
    param ($Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message"
}

function Is-Process-Running {
    param ($ProcessName)
    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
}

function Resolve-AppPath {
    param ($Path)
    if ($Path -is [scriptblock]) { & $Path }
    else { $Path }
}


 # ===============================
 # MAIN ||||||||||||||||||||||||||
 # ===============================

Write-Log "||                                ||"
Write-Log "||          WELCOME CMDR          ||"
Write-Log "||                                ||"
Write-Log "`r`n`n`n`n"
Write-Log "Checking for Steam..."
#find & boot steam
if (-not (Is-Process-Running "steam")) {
    Write-Log "Steam not running. Launching Steam..."
    Start-Process "steam://open/main"
    Start-Sleep -Seconds 10
}
else {
    Write-Log "Steam already running."
}

#boot elite
Write-Log "Launching Elite: Dangerous..."
Start-Process "steam://run/$EliteAppId"
Write-Log "Waiting for EliteDangerous64.exe...`r`n (GO CLICK THE BUTTON IN FRONTIER LAUNCHER!)`r`n"

do {
    Start-Sleep -Seconds 2
    $EliteProcess = Get-Process -Name "EliteDangerous64" -ErrorAction SilentlyContinue
} until ($EliteProcess)

Write-Log "Elite detected (PID: $($EliteProcess.Id))"


#launch apps
foreach ($App in $Apps) {

    Write-Log "Launching $($App.Name)..."

    if (Is-Process-Running $App.Process) {
        Write-Log "$($App.Name) already running."
        continue
    }

    $ResolvedPath = Resolve-AppPath $App.Path

    if ($ResolvedPath -and (Test-Path $ResolvedPath)) {
        Write-Log "Launching $($App.Name)..."
        Start-Process $ResolvedPath

        #add to tracked apps
        $LaunchedProcesses += $App.Process

        Start-Sleep -Seconds $LaunchDelaySeconds
    }
    else {
        Write-Log "WARNING: Path not found for $($App.Name)"
    }
}


Write-Log "All tools launched."
Write-Log "Waiting for game to exit..."



Wait-Process -Name "EliteDangerous64.exe"
Write-Log "Elite Dangerous has exited."
Write-Log "Closing third-party tools..."
#kill 3rd party apps on close
foreach ($ProcessName in $LaunchedProcesses) {

    $Running = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

    if ($Running) {
        Write-Log "Stopping $ProcessName..."
        $Running | Stop-Process -Force
    }
}

Write-Log "Launcher shutting down. Farewell, CMDR."
exit 0
