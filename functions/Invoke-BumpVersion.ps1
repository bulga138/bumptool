# File: ./BumpTool/functions/Invoke-BumpVersion.ps1

function Invoke-BumpVersion {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('patch', 'minor', 'major')]
        [string]$BumpType,

        [switch]$Commit,
        [switch]$Tag
    )
    
    Write-Debug "Starting Invoke-BumpVersion"
    
    # --- 1. Load Configuration ---
    $config = Get-BumpConfig
    Write-Debug "Config loaded. Using package manager: $($config.PackageManager)"

    # --- 2. Read package.json ---
    $pkgPath = '.\package.json'
    if (-not (Test-Path $pkgPath)) {
        Write-Error "No 'package.json' found in the current directory."
        return
    }
    $pkg = Get-Content $pkgPath | ConvertFrom-Json
    $orig_version = $pkg.version
    $pkg_name = $pkg.name
    Write-Verbose "Found package '$pkg_name' version '$orig_version'"

    # --- 3. Handle -WhatIf (Dry Run) ---
    $computed_new = Get-BumpedVersion $orig_version $BumpType # (This would be another private function)
    
    if ($PSCmdlet.ShouldProcess(
            "package.json (from $orig_version to $computed_new)",  # Target
            "Bump $BumpType version" # Action
        )) {
        # --- 4. Run NPM/Yarn Version ---
        $pm = $config.PackageManager
        $pm_args = "version $BumpType --no-git-tag-version"
        Write-Verbose "Running command: $pm $pm_args"
        
        $npm_out = ""
        try {
            $npm_out = Invoke-Expression "$pm $pm_args" 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) { throw $npm_out }
        }
        catch {
            Write-Error "Package manager command failed: $_"
            return
        }

        # --- 5. Get New Version & Git Context ---
        $new_version = (Get-Content $pkgPath | ConvertFrom-Json).version
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        $ticket = Get-TicketFromBranch -Branch $branch -Pattern $config.BranchRegex
        
        Write-Verbose "Version bumped to $new_version"
        Write-Debug "Branch: $branch | Ticket: $ticket"

        # --- 6. Format Commit Message (Configurable) ---
        $commit_msg = $config.CommitTemplate -replace '{ticket}', $ticket `
            -replace '{from}', $orig_version `
            -replace '{to}', $new_version `
            -replace '{type}', $BumpType `
            -replace '{name}', $pkg_name
        
        # Clean up template if no ticket was found (e.g., "feat():")
        $commit_msg = $commit_msg -replace '\([A-Z\s-]+\):', ':'
        $commit_msg = $commit_msg -replace ' \(\):', ':'
        
        Write-Host "Bumped $pkg_name from $orig_version to $new_version ($BumpType)" -ForegroundColor Green

        # --- 7. Copy to Clipboard ---
        if (Set-ClipboardHelper -Content $commit_msg) {
            Write-Verbose "Commit message copied to clipboard."
            Write-Debug "Clipboard content: $commit_msg"
        }

        # --- 8. Handle Commit and Tag ---
        if ($Commit) {
            Write-Verbose "Committing changes..."
            git add package.json package-lock.json yarn.lock 2>$null | Out-Null
            git commit -m $commit_msg
        }
        
        if ($Tag) {
            $tag_version = "v$new_version"
            Write-Verbose "Tagging version $tag_version..."
            git tag $tag_version
        }
    }
}