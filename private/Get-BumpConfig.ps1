if (-not $Global:configDir) {
    $Global:configDir  = Join-Path $env:USERPROFILE "Documents\BumpTool"
}
if (-not $Global:configFile) {
    $Global:configFile = Join-Path $Global:configDir "bump-config.json"
}

function Get-BumpConfig {
    if (-not (Test-Path $Global:configDir)) {
        New-Item -Path $Global:configDir -ItemType Directory | Out-Null
    }

    if (-not (Test-Path $Global:configFile)) {
        Write-Host "🧩 No config found, creating default configuration..."
        $defaultConfig = @{
            PackageManager = 'auto'
            AutoCommit     = $false
            AutoTag        = $false
            AutoPush       = $false
            ConfirmPush    = $false
            CommitTemplate = 'chore({type}): bump {name} from {from} to {to} ({ticket})'
            BranchRegex    = '(?<=feature/|bugfix/|hotfix/)([A-Z]+-\d+)'
            Audit          = @{
                Enabled     = $true
                SeparatePerRepo = $true
                MaxSizeMB   = 10
            }
        }
        $defaultConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $Global:configFile -Encoding utf8
    }

    $config = Get-Content $Global:configFile | ConvertFrom-Json

    # Ensure all top-level properties exist
    $defaults = @{
        PackageManager = 'auto'
        AutoCommit     = $false
        AutoTag        = $false
        AutoPush       = $false
        ConfirmPush    = $false
        CommitTemplate = 'chore({type}): bump {name} from {from} to {to} ({ticket})'
        BranchRegex    = '(?<=feature/|bugfix/|hotfix/)([A-Z]+-\d+)'
        Audit          = @{
            Enabled     = $true
            SeparatePerRepo = $true
            MaxSizeMB   = 10
        }
    }

    foreach ($key in $defaults.Keys) {
        if (-not $config.PSObject.Properties.Match($key)) {
            $config | Add-Member -MemberType NoteProperty -Name $key -Value $defaults[$key]
        }
    }

    # Ensure Audit object has all sub-properties
    if (-not $config.Audit) { $config.Audit = @{} }
    foreach ($key in $defaults.Audit.Keys) {
        if (-not $config.Audit.PSObject.Properties.Match($key)) {
            $config.Audit | Add-Member -MemberType NoteProperty -Name $key -Value $defaults.Audit[$key]
        }
    }
    
    # 🧠 Auto-detect package manager if 'auto'
    if ($config.PackageManager -eq 'auto') {
        $detected = Get-AutoDetectedPackageManager
        $config.PackageManager = $detected
        Write-Verbose "Detected package manager: $detected"
    }

    return $config
}
