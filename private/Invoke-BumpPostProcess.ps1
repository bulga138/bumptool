function Invoke-BumpPostProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OldVersion,

        [Parameter(Mandatory)]
        [string]$NewVersion,

        [Parameter(Mandatory)]
        [ValidateSet('patch', 'minor', 'major')]
        [string]$BumpType,

        [Parameter()]
        [PSCustomObject]$Config,

        [switch]$Commit,
        [switch]$Tag
    )

    Write-Verbose "Starting Invoke-BumpPostProcess for $BumpType"

    # Ensure config is loaded
    if (-not $Config) {
        $Config = Get-BumpConfig
    }

    # Detect repo and branch
    $repo   = Split-Path -Leaf (Get-Location)
    $branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
    if (-not $branch) { $branch = "unknown" }

    # Handle commit & tag (only if enabled)
    $shouldCommit = $Commit -or ($Config.AutoCommit -eq $true)
    $shouldTag    = $Tag    -or ($Config.AutoTag -eq $true)

    if ($shouldCommit -or $shouldTag) {
        Invoke-BumpCommit -OldVersion $OldVersion -NewVersion $NewVersion -BumpType $BumpType
    } else {
        Write-Host "🟡 Skipped commit/tag (AutoCommit and AutoTag disabled)." -ForegroundColor DarkYellow
    }

    # Handle optional push
    if ($Config.AutoPush -eq $true -and $branch -match '^(main|master)$') {
        Write-Host "⬆️  Auto-pushing to remote..." -ForegroundColor Green
        try {
            git push origin $branch 2>$null | Out-Null
            git push origin "v$NewVersion" 2>$null | Out-Null
        } catch {
            Write-Warning "Failed to auto-push: $_"
        }
    }
    elseif ($Config.ConfirmPush -eq $true -and $branch -match '^(main|master)$') {
        $resp = Read-Host "Push commit and tag to origin? (y/N)"
        if ($resp -eq 'y') {
            git push origin $branch 2>$null | Out-Null
            git push origin "v$NewVersion" 2>$null | Out-Null
        } else {
            Write-Host "Skipped push." -ForegroundColor DarkYellow
        }
    }

    # --- Audit logging ---
    if ($Config.Audit.Enabled -eq $true) {
        try {
            Add-BumpAuditEntry `
                -Repository $repo `
                -OldVersion $OldVersion `
                -NewVersion $NewVersion `
                -Branch $branch `
                -BumpType $BumpType `
                -CommitMessage "bump: $OldVersion → $NewVersion ($BumpType)"
        } catch {
            Write-Warning "Audit logging failed: $_"
        }
    } else {
        Write-Verbose "Audit disabled in config."
    }

    Write-Host "✅ Post-process completed." -ForegroundColor Green
}
