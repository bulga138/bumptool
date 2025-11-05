function Get-BumpAudit {
    [CmdletBinding()]
    param(
        [string]$Repository = (Split-Path -Leaf (Get-Location))
    )

    $logFile = Join-Path $env:USERPROFILE "Documents\BumpTool\logs\$Repository\bump-audit.json"
    if (-not (Test-Path $logFile)) {
        Write-Warning "No audit log found for repository '$Repository'."
        return
    }

    Get-Content $logFile -Raw | ConvertFrom-Json
}
