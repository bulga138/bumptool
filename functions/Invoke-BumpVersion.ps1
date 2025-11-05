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

    # --- Load Configuration ---
    $config = Get-BumpConfig
    Write-Debug "Config loaded. PackageManager=$($config.PackageManager)"

    # --- Read package.json ---
    $pkgPath = '.\package.json'
    if (-not (Test-Path $pkgPath)) {
        Write-Error "No 'package.json' found in the current directory."
        return
    }

    $pkg = Get-Content $pkgPath | ConvertFrom-Json
    $orig_version = $pkg.version
    $pkg_name = $pkg.name

    $computed_new = Get-BumpedVersion $orig_version $BumpType

    if ($PSCmdlet.ShouldProcess(
            "package.json (from $orig_version to $computed_new)",
            "Bump $BumpType version"
        )) {

        $pm = $config.PackageManager
        if ($pm -eq 'unknown') {
            Write-Warning "⚠️ Could not detect a supported package manager. Skipping version bump."
            return
        }

        $pm_args = "version $BumpType --no-git-tag-version"
        Write-Verbose "Running $pm $pm_args"

        try {
            $npm_out = Invoke-Expression "$pm $pm_args" 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) { throw $npm_out }
        }
        catch {
            Write-Error "Package manager command failed: $_"
            return
        }

        # Update version and handle commits/audit
        $new_version = (Get-Content $pkgPath | ConvertFrom-Json).version
        Invoke-BumpPostProcess `
            -OldVersion $orig_version `
            -NewVersion $new_version `
            -BumpType $BumpType `
            -Config $config `
            -Commit:$Commit `
            -Tag:$Tag
    }
}
