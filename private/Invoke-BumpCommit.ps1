function Invoke-BumpCommit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OldVersion,

        [Parameter(Mandatory)]
        [string]$NewVersion,

        [Parameter(Mandatory)]
        [ValidateSet('patch', 'minor', 'major')]
        [string]$BumpType
    )

    Write-Verbose "Starting Invoke-BumpCommit"

    # --- Load config ---
    $config = Get-BumpConfig
    $branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
    if (-not $branch) { $branch = "unknown" }

    # --- Sanity checks ---
    if (-not $NewVersion -or [string]::IsNullOrWhiteSpace($NewVersion)) {
        Write-Warning "⚠️ No valid new version string found. Skipping commit/tag."
        return
    }

    # --- Detect files to add ---
    $filesToAdd = @('package.json', 'package-lock.json', 'yarn.lock') | Where-Object { Test-Path $_ }
    if ($filesToAdd.Count -eq 0) {
        Write-Warning "No lockfiles found to commit. Skipping git add."
        return
    }

    # --- Format commit message ---
    $pkg = Get-Content .\package.json | ConvertFrom-Json
    $pkgName = $pkg.name
    $commitMsg = $config.CommitTemplate `
        -replace '{name}', $pkgName `
        -replace '{type}', $BumpType `
        -replace '{from}', $OldVersion `
        -replace '{to}', $NewVersion `
        -replace '{ticket}', (Get-TicketFromBranch -Branch $branch -Pattern $config.BranchRegex)

    $commitMsg = $commitMsg -replace '\(\)\s*:?',''

    # --- Git commit ---
    Write-Host "📝 Committing bump to version $NewVersion..." -ForegroundColor Cyan
    try {
        git add @filesToAdd 2>$null | Out-Null
        git commit -m $commitMsg 2>$null | Out-Null
    } catch {
        Write-Warning "Failed to commit changes: $_"
        return
    }

    # --- Tagging (only on main/master) ---
    if ($branch -match '^(main|master)$') {
        $tagVersion = "v$NewVersion"

        if ([string]::IsNullOrWhiteSpace($tagVersion) -or $tagVersion -eq 'v') {
            Write-Warning "Tag version invalid ('$tagVersion'). Skipping tag."
            return
        }

        Write-Host "🏷️ Creating tag '$tagVersion'..." -ForegroundColor Yellow
        try {
            git tag $tagVersion 2>$null | Out-Null
        } catch {
            Write-Warning "Failed to create tag: $_"
        }

        # --- Confirm before push if enabled ---
        $shouldPush = $config.AutoPush
        if ($config.ConfirmPush) {
            $resp = Read-Host "Push commit and tag '$tagVersion' to origin? (y/N)"
            $shouldPush = ($resp -eq 'y')
        }

        if ($shouldPush) {
            Write-Host "⬆️  Pushing tag '$tagVersion' to origin..." -ForegroundColor Green
            try {
                git push origin $branch 2>$null | Out-Null
                git push origin $tagVersion 2>$null | Out-Null
            } catch {
                Write-Warning "Failed to push tag or branch: $_"
            }
        } else {
            Write-Host "Skipped pushing tag." -ForegroundColor DarkYellow
        }
    } else {
        Write-Host "⚙️  Skipped tagging — not on main/master branch." -ForegroundColor DarkYellow
    }

    # --- Audit log ---
    try {
        Add-BumpAuditEntry -Repository (Split-Path -Leaf (Get-Location)) `
            -OldVersion $OldVersion `
            -NewVersion $NewVersion `
            -Branch $branch `
            -BumpType $BumpType `
            -CommitMessage $commitMsg
    } catch {
        Write-Warning "Audit logging failed: $_"
    }

    Write-Host "✅ Version bumped and logged successfully." -ForegroundColor Green
}
