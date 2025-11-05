function Get-AutoDetectedPackageManager {
    $repoPath = Get-Location
    if (Test-Path "$repoPath/package-lock.json") { return 'npm' }
    if (Test-Path "$repoPath/pnpm-lock.yaml")   { return 'pnpm' }
    if (Test-Path "$repoPath/yarn.lock")        { return 'yarn' }
    if (Test-Path "$repoPath/pyproject.toml")   { return 'python' }
    if (Test-Path "$repoPath/go.mod")           { return 'go' }
    if (Test-Path "$repoPath/Cargo.toml")       { return 'rust' }
    if (Test-Path "$repoPath/composer.json")    { return 'php' }
    return 'unknown'
}
