function Export-AuditLog {
    [CmdletBinding()]
    param(
        [ValidateSet("json","csv")]
        [string]$Format = "json",
        [string]$OutputPath
    )

    $repoName = try { (git rev-parse --show-toplevel 2>$null | Split-Path -Leaf) } catch { "default" }
    $baseDir = Join-Path $env:USERPROFILE "Documents\BumpTool\logs"
    $auditFile = Join-Path $baseDir "$repoName\bump-audit.json"

    if (-not (Test-Path $auditFile)) {
        Write-Error "No audit log found for '$repoName' at $auditFile."
        return
    }

    $entries = Get-Content $auditFile -Raw | ConvertFrom-Json

    if (-not $OutputPath) {
        $OutputPath = Join-Path (Get-Location) "bump-audit-export.$Format"
    }

    switch ($Format) {
        "json" {
            $entries | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8
        }
        "csv" {
            # Flatten the object for CSV export
            $entries | Select-Object Timestamp, Repository, Branch, OldVersion, NewVersion, BumpType, CommitMessage, User, Machine, GitCommitHash |
                Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
        }
    }

    Write-Host "📤 Exported audit log to $OutputPath" -ForegroundColor Green
}