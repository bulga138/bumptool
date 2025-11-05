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

    # --- Load config to check if auditing is enabled ---
    $config = Get-BumpConfig
    if (-not $config.Audit.EnableAudit) {
        Write-Verbose "Audit logging disabled in config."
        return
    }

    # --- Prepare paths ---
   $baseDir = if $config.Audit.SeparatePerRepo) {
    Join-Path $env:USERPROFILE "Documents\BumpTool\logs\$Repository"
    } else {
        Join-Path $env:USERPROFILE "Documents\BumpTool\logs\global"
    }


    $logFile = Join-Path $baseDir "bump-audit.json"

    # --- Load existing log (if any) ---
    $entries = @()
    if (Test-Path $logFile) {
        try {
            $entries = Get-Content $logFile -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Corrupted audit file detected, recreating."
            $entries = @()
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

    # --- Add entry to beginning (newest first) ---
    $entries = ,$entry + $entries

    # --- Apply size limit ---
    $max = [int]$config.Audit.MaxAuditEntries
    if ($entries.Count -gt $max) {
        $entries = $entries[0..($max - 1)]
    }

    # --- Save updated log ---
    try {
        $entries | ConvertTo-Json -Depth 5 | Set-Content $logFile -Encoding UTF8
        Write-Verbose "Audit log updated successfully for $Repository"
    } catch {
        Write-Warning "Failed to write audit log: $_"
    }
}
    