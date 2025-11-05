function Show-BumpAudit {
    [CmdletBinding()]
    param(
        [switch]$Export,
        [string]$Format = "json"
    )

    $config = Get-BumpConfig
    $repoName = (Split-Path (git rev-parse --show-toplevel 2>$null) -Leaf)
    $logBase = Join-Path $env:USERPROFILE "Documents\BumpTool\logs"
    $logDir = if ($config.Audit.SeparatePerRepo -and $repoName) {
        Join-Path $logBase $repoName
    } else {
        Join-Path $logBase "global"
    }
    $logFile = Join-Path $logDir "bump-audit.json"

    if (-not (Test-Path $logFile)) {
        Write-Host "No audit log found at $logFile" -ForegroundColor Yellow
        return
    }

    $logs = Get-Content $logFile | ForEach-Object { $_ | ConvertFrom-Json }

    if ($Export) {
        $output = if ($Format -eq "csv") {
            $logs | ConvertTo-Csv -NoTypeInformation
        } else {
            $logs | ConvertTo-Json -Depth 5
        }
        $outFile = Join-Path $logDir "bump-audit-export.$Format"
        $output | Out-File $outFile -Encoding utf8BOM
        Write-Host "Exported audit to $outFile" -ForegroundColor Green
    } else {
        $logs |
            Sort-Object Timestamp -Descending |
            Out-Host -Paging
    }
}
