function Show-BumpAudit {
    [CmdletBinding()]
    param(
        [switch]$Export,
        [string]$Format = "json",
        [switch]$Simple
    )

    $config = Get-BumpConfig
    $repoName = try {
        (git rev-parse --show-toplevel 2>$null | Split-Path -Leaf)
    } catch {
        (Get-Item .).Name
    }
    
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

    # Check if file is empty
    $content = Get-Content $logFile -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Host "Audit log file is empty" -ForegroundColor Yellow
        return
    }

    try {
        # First, try to parse as a JSON array (single JSON object)
        $logs = $content | ConvertFrom-Json -ErrorAction Stop
        # Only show parsing message in verbose mode
        Write-Verbose "Parsed as JSON array"
    } catch {
        Write-Verbose "Failed to parse as JSON array, trying line-by-line parsing..."
        try {
            # If that fails, try parsing each line separately (JSON lines format)
            $lines = Get-Content $logFile
            $logs = @()
            
            foreach ($line in $lines) {
                # Skip empty lines
                if ([string]::IsNullOrWhiteSpace($line)) {
                    continue
                }
                
                try {
                    $logEntry = $line | ConvertFrom-Json -ErrorAction Stop
                    $logs += $logEntry
                } catch {
                    Write-Warning "Skipping malformed line: $line"
                }
            }
            
            Write-Verbose "Parsed $($logs.Count) entries from individual lines"
        } catch {
            Write-Error "Failed to parse audit log file: $($_.Exception.Message)"
            Write-Host "File content preview:" -ForegroundColor Red
            Get-Content $logFile -First 10 | Write-Host
            return
        }
    }

    # Ensure $logs is always an array
    if ($logs -eq $null) {
        $logs = @()
    } elseif (-not ($logs -is [array])) {
        $logs = @($logs)
    }

    if ($logs.Count -eq 0) {
        Write-Host "No valid audit entries found in the log file" -ForegroundColor Yellow
        return
    }

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
        # Sort logs by timestamp if available
        $sortedLogs = $logs | Sort-Object @{Expression={
            if ($_.timestamp) { 
                try { [datetime]::Parse($_.timestamp) } catch { [datetime]::MinValue }
            } elseif ($_.Timestamp) {
                try { [datetime]::Parse($_.Timestamp) } catch { [datetime]::MinValue }
            } else {
                [datetime]::MinValue
            }
        }; Descending=$true}
        
        if ($Simple) {
            # Simple display - one line per entry
            Write-Host "Audit Log Entries (Simple View):" -ForegroundColor Green
            Write-Host ("=" * 50)
            foreach ($log in $sortedLogs) {
                $timestamp = if ($log.timestamp) {$log.timestamp} else {$log.Timestamp}
                $user = if ($log.user) {$log.user} else {$log.User}
                $project = if ($log.project) {$log.project} else {$log.Repository}
                $branch = if ($log.branch) {$log.branch} else {$log.Branch}
                $bumpType = if ($log.bumpType) {$log.bumpType} else {$log.Action}
                $from = if ($log.from) {$log.from} else {""}
                $to = if ($log.to) {$log.to} else {""}
                $newVersion = if ($log.NewVersion) {$log.NewVersion} else {""}
                
                # Use 'to' field or 'NewVersion' field for the new version
                $displayVersion = if ($to -and $to -ne "") {$to} elseif ($newVersion -and $newVersion -ne "") {$newVersion} else {""}
                $oldVersion = if ($from -and $from -ne "") {$from} elseif ($log.OldVersion -and $log.OldVersion -ne "") {$log.OldVersion} else {""}
                
                # Create a simple one-line summary
                $branchInfo = if ($branch -and $branch -ne "") {" [$branch]"} else {""}
                $versionInfo = if ($oldVersion -and $displayVersion) {" ${oldVersion} → ${displayVersion}"} 
                              elseif ($displayVersion) {" → ${displayVersion}"}
                              else {""}
                $typeInfo = if ($bumpType -and $bumpType -ne "") {" ($bumpType)"} else {""}
                
                Write-Host "${timestamp} | ${user} | ${project}${branchInfo}${typeInfo}${versionInfo}" -ForegroundColor Cyan
            }
        } else {
            # Display logs in a formatted way (detailed view)
            foreach ($log in $sortedLogs) {
                $timestamp = if ($log.timestamp) {$log.timestamp} else {$log.Timestamp}
                $user = if ($log.user) {$log.user} else {$log.User}
                $project = if ($log.project) {$log.project} else {$log.Repository}
                $branch = if ($log.branch) {$log.branch} else {$log.Branch}
                $bumpType = if ($log.bumpType) {$log.bumpType} else {$log.Action}
                $from = if ($log.from) {$log.from} else {""}
                $to = if ($log.to) {$log.to} else {""}
                $newVersion = if ($log.NewVersion) {$log.NewVersion} else {""}
                $oldVersion = if ($log.OldVersion) {$log.OldVersion} else {""}
                
                Write-Host "Timestamp: ${timestamp}" -ForegroundColor Cyan
                Write-Host "User: ${user}"
                Write-Host "Project: ${project}"
                if ($branch -and $branch -ne "") { Write-Host "Branch: ${branch}" }
                if ($bumpType -and $bumpType -ne "") { Write-Host "Action: ${bumpType}" }
                if ($from -or $to -or $oldVersion -or $newVersion) { 
                    $oldVer = if ($from -and $from -ne "") {$from} elseif ($oldVersion -and $oldVersion -ne "") {$oldVersion} else {"?"}
                    $newVer = if ($to -and $to -ne "") {$to} elseif ($newVersion -and $newVersion -ne "") {$newVersion} else {"?"}
                    Write-Host "Version: ${oldVer} -> ${newVer}" 
                }
                
                # Display other properties
                $log.PSObject.Properties | ForEach-Object {
                    $name = $_.Name
                    $value = $_.Value
                    # Skip already displayed properties
                    if ($name -notin @('timestamp', 'Timestamp', 'user', 'User', 'project', 'Project', 'Repository', 'branch', 'Branch', 'bumpType', 'Action', 'from', 'to', 'OldVersion', 'NewVersion')) {
                        if ($value -ne $null -and $value -ne '') {
                            Write-Host "${name}: ${value}"
                        }
                    }
                }
                
                Write-Host ("-" * 50)
                Write-Host ""
            }
        }
    }
}
