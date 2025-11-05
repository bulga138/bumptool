# File: ./BumpTool/private/Get-BumpConfig.ps1
function Get-BumpConfig {
    # Default config
    $defaults = @{
        BranchRegex    = '([A-Z]+-\d+)'
        CommitTemplate = 'feat({ticket}): bump version {from} to {to} ({type})'
        PackageManager = 'npm'
        AutoCommit     = $false
        AutoTag        = $false
    }
    
    # Create config dir/file if it doesn't exist
    if (-not (Test-Path $Global:configDir)) {
        New-Item -Path $Global:configDir -ItemType Directory | Out-Null
    }
    if (-not (Test-Path $Global:configFile)) {
        $defaults | ConvertTo-Json | Out-File -FilePath $Global:configFile -Encoding utf8
        return $defaults
    }
    
    # Load and merge config
    $userConfig = Get-Content $Global:configFile | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($null -eq $userConfig) { return $defaults }
    
    # Merge (user config overrides defaults)
    $finalConfig = $defaults.Clone()
    $userConfig.PSObject.Properties | ForEach-Object {
        $finalConfig[$_.Name] = $_.Value
    }
    
    return $finalConfig
}