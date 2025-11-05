function Get-BumpedVersion {
    <#
    .SYNOPSIS
    Calculates a bumped version string (for --dry-run).
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Version,
        [ValidateSet("patch","minor","major")][string]$BumpType = "patch"
    )

    # Normalize input: strip leading "v" or "V"
    $v = $Version.Trim()
    if ($v.StartsWith('v') -or $v.StartsWith('V')) {
        $v = $v.Substring(1)
    }

    # Remove pre-release/build metadata (anything after '-' or '+')
    # Use parentheses so we index the split result, not the literal split pattern.
    $cleanVersion = ($v -split '[-+]')[0]

    if ([string]::IsNullOrWhiteSpace($cleanVersion)) {
        $cleanVersion = "0.0.0"
    }

    # Split into parts and pad to 3 components
    $parts = $cleanVersion.Split('.')
    # Ensure we have 3 numeric parts
    for ($i = $parts.Count; $i -lt 3; $i++) {
        $parts += '0'
    }

    # Parse parts safely
    $major = 0; $minor = 0; $patch = 0
    [int]::TryParse($parts[0], [ref]$major) | Out-Null
    [int]::TryParse($parts[1], [ref]$minor) | Out-Null
    [int]::TryParse($parts[2], [ref]$patch) | Out-Null

    switch ($BumpType) {
        "patch" { $patch += 1 }
        "minor" { $minor += 1; $patch = 0 }
        "major" { $major += 1; $minor = 0; $patch = 0 }
        default { $patch += 1 }
    }

    $newVersion = "{0}.{1}.{2}" -f $major, $minor, $patch

    return $newVersion
}
