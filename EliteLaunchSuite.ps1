# ===============================
# Configuration
# ===============================

$EliteAppId = 359320

$Apps = @(
    @{
        Name = "EDMarketConnector"
        Process = "EDMarketConnector"
        Path = "C:\Program Files (x86)\EDMarketConnector\EDMarketConnector.exe"
    },
    @{
        Name = "SrvSurvey"
        Process = "SrvSurvey"
        Path = "C:\Users\Andrew\AppData\Local\Apps\2.0\HY5GKY7N.214\DPC60QJN.OC9\srvs..tion_0000000000000000_0002.0000_6851f976136fff83\SrvSurvey.exe"
    },
    @{
        Name = "OdysseyMaterialsHelper"
        Process = "OdysseyMaterialsHelper"
        Path = "C:\Users\Andrew\AppData\Local\Elite Dangerous Odyssey Materials Helper Launcher\program\Elite Dangerous Odyssey Materials Helper.exe"
    },
	#@{
    #    Name = "EDHM-UI"
    #    Process = "EDHM-UI-V3"
    #    Path = "C:\Users\Andrew\AppData\Local\EDHM-UI-V3\EDHM-UI-V3.exe"
    #},
	@{
        Name = "EDCoPilot"
        Process = "EDCoPilot"
        Path = "C:\EDCoPilot\EDCoPilot.exe"
    }
)

# Placeholder for future tool
# $Apps += @{
#     Name = "FutureTool"
#     Process = "FutureTool"
#     Path = "C:\Path\To\FutureTool.exe"
# }

$LaunchDelaySeconds = 3


# ===============================
# Helper Functions
# ===============================

function Write-Log {
    param ($Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message"
}

function Is-Process-Running {
    param ($ProcessName)
    return Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
}


# ===============================
# Steam Detection / Startup
# ===============================

Write-Log "Checking for Steam..."

if (-not (Is-Process-Running "steam")) {
    Write-Log "Steam not running. Starting Steam..."
    Start-Process "steam://open/main"
    Start-Sleep -Seconds 10
} else {
    Write-Log "Steam is already running."
}


# ===============================
# Launch Elite: Dangerous
# ===============================

Write-Log "Launching Elite: Dangerous via Steam..."
Start-Process "steam://run/$EliteAppId"

Write-Log "Waiting for EliteDangerous64.exe to appear..."

do {
    Start-Sleep -Seconds 2
    $EliteProcess = Get-Process -Name "EliteDangerous64" -ErrorAction SilentlyContinue
} until ($EliteProcess)

Write-Log "Elite: Dangerous detected (PID: $($EliteProcess.Id))"


# ===============================
# Launch Third-Party Tools
# ===============================

foreach ($App in $Apps) {

    Write-Log "Processing $($App.Name)..."

    if (Is-Process-Running $App.Process) {
        Write-Log "$($App.Name) already running. Skipping."
    }
    else {
        if (Test-Path $App.Path) {
            Write-Log "Launching $($App.Name)..."
            Start-Process $App.Path
            Start-Sleep -Seconds $LaunchDelaySeconds
        }
        else {
            Write-Log "WARNING: Path not found for $($App.Name): $($App.Path)"
        }
    }
}


# ===============================
# Auto-Close When Elite Exits
# ===============================

Write-Log "All tools launched."
Write-Log "Monitoring Elite: Dangerous process..."

Wait-Process -Id $EliteProcess.Id

Write-Log "Elite: Dangerous has exited."
Write-Log "Launcher script exiting."

exit
