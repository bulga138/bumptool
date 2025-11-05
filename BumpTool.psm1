# $PSScriptRoot is a magic variable: the directory this .psm1 file is in.
$PublicFunctions = "$PSScriptRoot\functions"
$PrivateFunctions = "$PSScriptRoot\private"

# --- 1. Define Configuration ---
# Use the same logic as Get-BumpConfig.ps1
$Global:configDir  = Join-Path $env:USERPROFILE "Documents\BumpTool"
$Global:configFile = Join-Path $Global:configDir "bump-config.json"

# Ensure directory exists before anything else
if (-not (Test-Path $Global:configDir)) {
    New-Item -Path $Global:configDir -ItemType Directory | Out-Null 
}

# Export config path for other functions to use
Export-ModuleMember -Variable configDir, configFile

# --- 2. Load Private (Internal) Functions ---
# These are helpers not exposed to the user.
Get-ChildItem -Path $PrivateFunctions -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

# --- 3. Load Public (Exported) Functions ---
# These are the commands the user will run.
Get-ChildItem -Path $PublicFunctions -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

# --- 4. Define Aliases (handled by .psd1, but we define the *target*) ---
# The .psd1 manifest maps 'bump-patch' to 'Invoke-BumpVersion -BumpType patch'
# We need to define functions that can be aliased.
function bump-patch {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch]$Commit,
        [switch]$Tag
    )
    Invoke-BumpVersion -BumpType patch -Commit:$Commit -Tag:$Tag -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference -Debug:$DebugPreference
}
function bump-minor {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch]$Commit,
        [switch]$Tag
    )
    Invoke-BumpVersion -BumpType minor -Commit:$Commit -Tag:$Tag -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference -Debug:$DebugPreference
}
function bump-major {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [switch]$Commit,
        [switch]$Tag
    )
    Invoke-BumpVersion -BumpType major -Commit:$Commit -Tag:$Tag -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference -Debug:$DebugPreference
}
# Export these helper aliases
Export-ModuleMember -Alias 'bump-patch', 'bump-minor', 'bump-major'


# --- 5. Register Argument Completer (Improvement #6) ---
Register-ArgumentCompleter -CommandName 'Invoke-BumpVersion' -ParameterName 'BumpType' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $options = @('patch', 'minor', 'major')
    $options | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        New-Object System.Management.Automation.CompletionResult(
            "'$_'",  # Completion text
            $_,     # List item text
            'ParameterValue', # Result type
            'The version part to bump' # Tooltip
        )
    }
}