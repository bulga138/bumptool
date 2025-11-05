function Add-BumpAuditEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Repository,

        [Parameter(Mandatory)]
        [string]$OldVersion,

        [Parameter(Mandatory)]
        [string]$NewVersion,

        [Parameter(Mandatory)]
        [string]$Branch,

        [Parameter(Mandatory)]
        [ValidateSet('patch', 'minor', 'major')]
        [string]$BumpType,

        [Parameter(Mandatory)]
        [string]$CommitMessage
    )

    Write-Verbose "Starting Add-BumpAuditEntry for $Repository"

    # --- Load config ---
    $config = Get-BumpConfig
    if (-not $config.Audit.Enabled) {
        Write-Verbose "Audit logging disabled in config."
        return
    }

    # --- Prepare paths ---
    $baseDir = Join-Path $env:USERPROFILE "Documents\BumpTool\logs\$Repository"
    if (-not (Test-Path $baseDir)) {
        New-Item -ItemType Directory -Force -Path $baseDir | Out-Null
    }
    $logFile = Join-Path $baseDir "bump-audit.json"

    # --- Load existing log (if any) ---
    $entries = @()
    if (Test-Path $logFile) {
        try {
            # Prune by file size *before* loading if it's too large
            $maxSizeMB = [int]$config.Audit.MaxSizeMB
            if ((Get-Item $logFile).Length / 1MB -gt $maxSizeMB) {
                Write-Warning "Audit log size exceeded ${maxSizeMB}MB. Rotating..."
                $existing = Get-Content $logFile -Raw | ConvertFrom-Json
                if ($existing -is [System.Collections.IEnumerable]) {
                     $entries = $existing | Select-Object -Last ([math]::Floor($config.Audit.MaxEntries / 2))
                }
            } else {
                 $entries = Get-Content $logFile -Raw | ConvertFrom-Json
            }
        } catch {
            Write-Warning "Corrupted audit file detected, recreating."
            $entries = @()
        }
        
        # Ensure it's always an array
        if (-not ($entries -is [System.Collections.IEnumerable])) {
            $entries = @($entries)
        }
    }

    # --- Create new entry ---
    $entry = [ordered]@{
        Timestamp      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Repository     = $Repository
        Branch         = $Branch
        OldVersion     = $OldVersion
        NewVersion     = $NewVersion
        BumpType       = $BumpType
        CommitMessage  = $CommitMessage
        User           = [System.Environment]::UserName
        Machine        = $env:COMPUTERNAME
        GitCommitHash  = (git rev-parse HEAD 2>$null)
    }

    # --- Add entry to end ---
    $entries += $entry

    # --- Apply count limit ---
    $maxCount = [int]$config.Audit.MaxEntries
    if ($entries.Count -gt $maxCount) {
        $entries = $entries | Select-Object -Last $maxCount
    }

    # --- Save updated log ---
    try {
        $entries | ConvertTo-Json -Depth 5 | Set-Content $logFile -Encoding UTF8
        Write-Verbose "Audit log updated successfully for $Repository"
    } catch {
        Write-Warning "Failed to write audit log: $_"
    }
}