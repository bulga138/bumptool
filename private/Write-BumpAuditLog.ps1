function Write-BumpAuditLog {
    [CmdletBinding()]
    param(
        [string]$OldVersion,
        [string]$NewVersion,
        [string]$Branch,
        [string]$BumpType,
        [string]$CommitMessage,
        [string]$TagVersion,
        [bool]$Pushed = $false,
        [bool]$ConfirmedPush = $false,
        [string]$Result = "success"
    )

    try {
        # --- 1. Load configuration ---
        $config = Get-BumpConfig
        if (-not $config.Audit.Enabled) {
            Write-Verbose "Audit logging is disabled in config."
            return
        }

        $maxEntries = $config.Audit.MaxEntries
        $maxSizeMB  = $config.Audit.MaxFileSizeMB

        # --- 2. Resolve repo name ---
        $repoName = try {
            (git rev-parse --show-toplevel 2>$null | Split-Path -Leaf)
        } catch {
            (Get-Item .).Name
        }

        # --- 3. Prepare directories and file path ---
        $logDir = Join-Path "$env:USERPROFILE\Documents\BumpTool\logs" $repoName
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $logFile = Join-Path $logDir "bump-audit.json"

        # --- 4. Prepare entry ---
        $entry = [ordered]@{
            timestamp     = (Get-Date).ToUniversalTime().ToString("o")
            user          = $env:USERNAME
            project       = $repoName
            branch        = $Branch
            bumpType      = $BumpType
            from          = $OldVersion
            to            = $NewVersion
            commit        = $CommitMessage
            tag           = $TagVersion
            pushed        = $Pushed
            confirmedPush = $ConfirmedPush
            result        = $Result
        }

        # --- 5. Append safely ---
        $entries = @()
        if (Test-Path $logFile) {
            try {
                $entries = Get-Content $logFile | ConvertFrom-Json -ErrorAction Stop
                if (-not ($entries -is [System.Collections.IEnumerable])) {
                    $entries = @($entries)
                }
            } catch {
                Write-Warning "Failed to parse existing audit log. Creating new file."
                $entries = @()
            }
        }

        $entries += $entry

        # --- 6. Prune old entries by count ---
        if ($entries.Count -gt $maxEntries) {
            $entries = $entries | Select-Object -Last $maxEntries
        }

        # --- 7. Prune by file size (if needed) ---
        if ((Test-Path $logFile) -and ((Get-Item $logFile).Length / 1MB -gt $maxSizeMB)) {
            Write-Warning "Audit log size exceeded ${maxSizeMB}MB. Rotating..."
            $entries = $entries | Select-Object -Last ([math]::Floor($maxEntries / 2))
        }

        # --- 8. Save new log ---
        $entries | ConvertTo-Json -Depth 5 | Set-Content -Path $logFile -Encoding UTF8

        Write-Verbose "Audit entry saved for project $repoName."
    }
    catch {
        Write-Warning "Failed to write audit log: $_"
    }
}

function Write-BumpAudit {
    param(
        [string]$Action,
        [hashtable]$Details
    )

    $config = Get-BumpConfig
    if (-not $config.Audit.Enabled) { return }

    $repoName = (Split-Path (git rev-parse --show-toplevel 2>$null) -Leaf)
    $baseDir = Join-Path $env:USERPROFILE "Documents\BumpTool\logs"
    $logDir = if ($config.Audit.SeparatePerRepo -and $repoName) {
        Join-Path $baseDir $repoName
    } else {
        Join-Path $baseDir "global"
    }

    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    $logFile = Join-Path $logDir "bump-audit.json"

    # Enforce max file size
    if ((Test-Path $logFile) -and ((Get-Item $logFile).Length -gt ($config.Audit.MaxSizeMB * 1MB))) {
        Copy-Item $logFile "$logFile.bak" -Force
        Clear-Content $logFile
    }

    $entry = [ordered]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Action    = $Action
        User      = $env:USERNAME
        Repository = $repoName
        Details   = $Details
    }

    $jsonLine = $entry | ConvertTo-Json -Compress
    Add-Content -Path $logFile -Value $jsonLine
}

