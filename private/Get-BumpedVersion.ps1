# File: ./BumpTool/private/Get-BumpedVersion.ps1
function Get-BumpedVersion {
    <#
    .SYNOPSIS
    Calculates a bumped version string (for --dry-run).
    #>
    param(
        [string]$Version = "0.0.0",
        [string]$BumpType = "patch"
    )

    # Strip prerelease/metadata (e.g., 1.2.3-beta+456 -> 1.2.3)
    $cleanVersion = $Version -split '[-+]'[0]
    
    $parts = $cleanVersion.Split('.')
    
    # Safely parse major, minor, patch, defaulting to 0
    [int]$major = 0; [int]::TryParse($parts[0], [ref]$major) | Out-Null
    [int]$minor = 0; if ($parts.Length -gt 1) { [int]::TryParse($parts[1], [ref]$minor) | Out-Null }
    [int]$patch = 0; if ($parts.Length -gt 2) { [int]::TryParse($parts[2], [ref]$patch) | Out-Null }

    switch ($BumpType) {
        "major" { return "$([int]$major + 1).0.0" }
        "minor" { return "$major.$([int]$minor + 1).0" }
        default { return "$major.$minor.$([int]$patch + 1)" }
    }
}