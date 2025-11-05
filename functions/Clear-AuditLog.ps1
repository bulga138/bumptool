function Clear-AuditLog {
    [CmdletBinding()]
    param(
        [switch]$All
    )

    $baseDir = Join-Path $env:USERPROFILE "Documents\BumpTool\logs"

    if ($All -and (Test-Path $baseDir)) {
        Remove-Item -Path $baseDir -Recurse -Force
        Write-Host "🗑 Cleared all audit logs."
        return
    }

    # Determine path for current repo
    $repoName = try { (git rev-parse --show-toplevel 2>$null | Split-Path -Leaf) } catch { "default" }
    $repoAuditDir = Join-Path $baseDir $repoName

    if (Test-Path $repoAuditDir) {
        Remove-Item -Path $repoAuditDir -Recurse -Force
        Write-Host "🧹 Cleared audit log for repository '$repoName'."
    } else {
        Write-Host "No audit log found for '$repoName' at $repoAuditDir."
    }
}