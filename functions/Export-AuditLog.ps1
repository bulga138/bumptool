function Export-AuditLog {
    [CmdletBinding()]
    param(
        [ValidateSet("json","csv")]
        [string]$Format = "json",
        [string]$OutputPath
    )

    $config = Get-BumpConfig
    $repoName = try { (git rev-parse --show-toplevel 2>$null | Split-Path -Leaf) } catch { "default" }
    $auditPath = Join-Path (Join-Path $env:APPDATA "BumpTool\audits") "$repoName.json"

    if (-not (Test-Path $auditPath)) {
        Write-Error "No audit log found for '$repoName'."
        return
    }

    $entries = Get-Content $auditPath -Raw | ConvertFrom-Json

    if (-not $OutputPath) {
        $OutputPath = Join-Path (Get-Location) "bump-audit-export.$Format"
    }

    switch ($Format) {
        "json" {
            $entries | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8
        }
        "csv" {
            $entries | ForEach-Object {
                [PSCustomObject]@{
                    Timestamp = $_.Timestamp
                    Action    = $_.Action
                    Details   = ($_?.Data | ConvertTo-Json -Compress)
                }
            } | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
        }
    }

    Write-Host "📤 Exported audit log to $OutputPath" -ForegroundColor Green
}
