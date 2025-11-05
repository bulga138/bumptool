function Show-BumpAuditSummary {
    [CmdletBinding()]
    param(
        [string]$Repository = (git rev-parse --show-toplevel 2>$null | Split-Path -Leaf)
    )

    $logFile = Join-Path "$env:USERPROFILE\Documents\BumpTool\logs\$Repository" "bump-audit.json"

    if (-not (Test-Path $logFile)) {
        Write-Warning "No audit log found for repository '$Repository'."
        return
    }

    try {
        $entries = Get-Content $logFile -Raw | ConvertFrom-Json
        if (-not ($entries -is [System.Collections.IEnumerable])) { $entries = @($entries) }
        if (-not $entries) {
            Write-Host "No entries found in the audit log for '$Repository'."
            return
        }

        # --- Basic Stats ---
        $total = $entries.Count
        $byType = $entries | Group-Object bumpType | ForEach-Object {
            [pscustomobject]@{
                Type  = $_.Name
                Count = $_.Count
            }
        }

        $successCount = ($entries | Where-Object { $_.result -eq 'success' }).Count
        $failCount    = ($entries | Where-Object { $_.result -ne 'success' }).Count

        # --- Most Recent ---
        $latest = $entries | Sort-Object { [datetime]$_.timestamp } -Descending | Select-Object -First 1
        $earliest = $entries | Sort-Object { [datetime]$_.timestamp } | Select-Object -First 1

        # --- Average Interval (in days) ---
        $timestamps = $entries | Sort-Object { [datetime]$_.timestamp } | ForEach-Object { [datetime]$_.timestamp }
        $intervals = @()
        for ($i = 1; $i -lt $timestamps.Count; $i++) {
            $intervals += ($timestamps[$i] - $timestamps[$i - 1]).TotalDays
        }
        $avgInterval = if ($intervals.Count -gt 0) { [math]::Round(($intervals | Measure-Object -Average).Average, 2) } else { 0 }

        # --- Output ---
        Write-Host "📦 Repository:" -ForegroundColor Cyan -NoNewline
        Write-Host " $Repository"
        Write-Host "──────────────────────────────────────────"

        Write-Host "Total bumps: $total"
        Write-Host "  ✅ Successful: $successCount"
        Write-Host "  ❌ Failed: $failCount"
        Write-Host ""
        Write-Host "By type:"
        $byType | Format-Table -AutoSize | Out-String | Write-Host

        Write-Host ""
        Write-Host "Average interval between bumps: $avgInterval days"
        Write-Host ""
        Write-Host "First bump:  " ([datetime]$earliest.timestamp).ToLocalTime()
        Write-Host "Last bump:   " ([datetime]$latest.timestamp).ToLocalTime()
        Write-Host ""
        Write-Host "Last change:"
        Write-Host "  Branch:  $($latest.branch)"
        Write-Host "  From:    $($latest.from)"
        Write-Host "  To:      $($latest.to)"
        Write-Host "  Type:    $($latest.bumpType)"
        Write-Host "  Commit:  $($latest.commit)"
        Write-Host "  Result:  $($latest.result)"
    }
    catch {
        Write-Warning "Failed to read or summarize audit log: $_"
    }
}
