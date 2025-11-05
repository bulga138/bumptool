function Clear-AuditLog {
    [CmdletBinding()]
    param(
        [switch]$All
    )

    $config = Get-BumpConfig
    $baseDir = Join-Path $env:APPDATA "BumpTool\audits"

    if ($All -and (Test-Path $baseDir)) {
        Remove-Item -Path $baseDir -Recurse -Force
        Write-Host "🗑 Cleared all audit logs."
        return
    }

    # Determine path for current repo
    $repoName = try { (git rev-parse --show-toplevel 2>$null | Split-Path -Leaf) } catch { "default" }
    $auditPath = Join-Path $baseDir "$repoName.json"

    if (Test-Path $auditPath) {
        Remove-Item -Path $auditPath -Force
        Write-Host "🧹 Cleared audit log for repository '$repoName'."
    } else {
        Write-Host "No audit log found for '$repoName'."
    }
}
