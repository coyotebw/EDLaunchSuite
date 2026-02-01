# ==========================================================
# Elite Dangerous Launch Suite   ||||||||||||||||||||||||||
# v1.2 by CMDR Coyote Bongwater  ||||||||||||||||||||||||||
# ==========================================================



# Force 64-bit
if (-not [Environment]::Is64BitProcess) {
    Write-Host "Restarting in 64-bit PowerShell..."
    Start-Process "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# Title for console window so we don't look sketchy
$Host.UI.RawUI.WindowTitle = "Elite Dangerous Launch Suite"

$EliteAppId = 359320

$LocalAppData      = $env:LOCALAPPDATA
$ProgramFilesX86   = ${env:ProgramFiles(x86)}

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
    #@{
    #    Name    = "EDHM-UI"
    #    Process = "EDHM-UI-V3"
    #    Path    = Join-Path $LocalAppData "EDHM-UI-V3\EDHM-UI-V3.exe"
    #},
    @{
        Name    = "EDCoPilot"
        Process = "EDCoPilot"
        Path    = "C:\EDCoPilot\EDCoPilot.exe"
    }
)

$LaunchDelaySeconds = 3


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

    if ($Path -is [scriptblock]) {
        return & $Path
    }
    return $Path
}


# ===============================
# Steam Detection / Startup |||||
# ===============================

Write-Log "Checking for Steam..."

if (-not (Is-Process-Running "steam")) {
    Write-Log "Steam not running. Starting Steam..."
    Start-Process "steam://open/main"
    Start-Sleep -Seconds 10
}
else {
    Write-Log "Steam is already running."
}


# ===============================
# Launch Elite: Dangerous |||||||
# ===============================

Write-Log "Launching Elite: Dangerous via Steam..."
Start-Process "steam://run/$EliteAppId"

Write-Log "Waiting for EliteDangerous64.exe..."

do {
    Start-Sleep -Seconds 2
    $EliteProcess = Get-Process -Name "EliteDangerous64" -ErrorAction SilentlyContinue
} until ($EliteProcess)

Write-Log "Elite detected (PID: $($EliteProcess.Id))"


# ===============================
# Launch Third-Party Tools ||||||
# ===============================

foreach ($App in $Apps) {

    Write-Log "Processing $($App.Name)..."

    if (Is-Process-Running $App.Process) {
        Write-Log "$($App.Name) already running. Skipping."
        continue
    }

    $ResolvedPath = Resolve-AppPath $App.Path

    if ($ResolvedPath -and (Test-Path $ResolvedPath)) {
        Write-Log "Launching $($App.Name)..."
        Start-Process $ResolvedPath
        Start-Sleep -Seconds $LaunchDelaySeconds
    }
    else {
        Write-Log "WARNING: Path not found for $($App.Name)"
    }
}


# ===============================
# Auto-Close When Elite Exits |||
# ===============================

Write-Log "All tools launched."
Write-Log "Monitoring Elite Dangerous process..."

Wait-Process -Id $EliteProcess.Id

Write-Log "Elite Dangerous has exited."
Write-Log "Launcher shutting down."

exit 0
