@{
    # Version of your module
    ModuleVersion     = '1.0.0'

    # GUID (run [guid]::NewGuid() in PowerShell to get one)
    GUID              = 'b8e1e61a-3dcc-4cd9-bde5-aeb0028a31ae'

    Author            = 'bulga'
    Description       = 'A tool to bump package versions and generate commit messages.'

    # The main module file
    RootModule        = 'BumpTool.psm1'

    # The functions we want to make public
    FunctionsToExport = @(
        'Invoke-BumpVersion',
        'Set-BumpConfig',
        'Show-BumpAudit',
        'bump-patch',
        'bump-minor',
        'bump-major'
    )
    
    # We now depend on ConsoleGuiTools, which includes Terminal.Gui
    RequiredModules   = @(
        @{
            ModuleName    = 'Microsoft.PowerShell.ConsoleGuiTools'
            ModuleVersion = '0.7.1' # Specify a version you've tested with
        }
    )

    # Set the minimum PowerShell version
    PowerShellVersion = '5.1'
}