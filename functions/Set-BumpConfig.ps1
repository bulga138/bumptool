function Set-BumpConfig {
    [CmdletBinding()]
    param()
    
    # --- Initialization ---
    # Ensure the required module is installed
    if (-not (Get-Module -Name Microsoft.PowerShell.ConsoleGuiTools -ListAvailable)) {
        Write-Host "Installing required module 'Microsoft.PowerShell.ConsoleGuiTools'..."
        try {
            Install-Module Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        } catch {
            Write-Error "Failed to install Microsoft.PowerShell.ConsoleGuiTools. $_"
            return
        }
    }

    # Import the module and load the Terminal.Gui assembly
    try {
        Import-Module Microsoft.PowerShell.ConsoleGuiTools -ErrorAction Stop
        $modulePath = (Get-Module Microsoft.PowerShell.ConsoleGuiTools -ListAvailable).ModuleBase
        $assemblyPath = Join-Path $modulePath "Terminal.Gui.dll"
        if (-not (Test-Path $assemblyPath)) {
            Write-Error "Terminal.Gui.dll not found inside Microsoft.PowerShell.ConsoleGuiTools module path: $assemblyPath"
            return
        }
        Add-Type -Path $assemblyPath -ErrorAction Stop
    } catch {
        Write-Error "Failed to load Terminal.Gui from Microsoft.PowerShell.ConsoleGuiTools. $_"
        return
    }

    # --- Load current config ---
    $config = Get-BumpConfig

    [Terminal.Gui.Application]::Init()
    $Toplevel = [Terminal.Gui.Application]::Top

    $window = [Terminal.Gui.Window]::new("BumpTool Configuration")
    $window.Width  = [Terminal.Gui.Dim]::Fill()
    $window.Height = [Terminal.Gui.Dim]::Fill()

    # --- 1. Branch Regex ---
    $labelRegex = [Terminal.Gui.Label]::new("Branch Regex Pattern:")
    $labelRegex.X = 1
    $labelRegex.Y = 2
    $labelRegex.Width = 25
    $window.Add($labelRegex)

    $textRegex = [Terminal.Gui.TextField]::new([string]$config.BranchRegex)
    $textRegex.X = [Terminal.Gui.Pos]::Right($labelRegex) + 1
    $textRegex.Y = $labelRegex.Y
    $textRegex.Width = [Terminal.Gui.Dim]::Fill() - 5
    $window.Add($textRegex)

    # --- 2. Commit Template ---
    $labelTemplate = [Terminal.Gui.Label]::new("Commit Message Template:")
    $labelTemplate.X = 1
    $labelTemplate.Y = [Terminal.Gui.Pos]::Bottom($labelRegex) + 1
    $labelTemplate.Width = $labelRegex.Width
    $window.Add($labelTemplate)

    $textTemplate = [Terminal.Gui.TextField]::new([string]$config.CommitTemplate)
    $textTemplate.X = [Terminal.Gui.Pos]::Right($labelTemplate) + 1
    $textTemplate.Y = $labelTemplate.Y
    $textTemplate.Width = [Terminal.Gui.Dim]::Fill() - 5
    $window.Add($textTemplate)

    $labelHelp = [Terminal.Gui.Label]::new("(Use: {ticket}, {type}, {from}, {to})")
    $labelHelp.X = $textTemplate.X
    $labelHelp.Y = [Terminal.Gui.Pos]::Bottom($textTemplate)
    $window.Add($labelHelp)

    # --- 3. Package Manager ---
    $labelPm = [Terminal.Gui.Label]::new("Package Manager:")
    $labelPm.X = 1
    $labelPm.Y = [Terminal.Gui.Pos]::Bottom($labelHelp) + 2
    $labelPm.Width = $labelRegex.Width
    $window.Add($labelPm)

    $radioGroupPm = [Terminal.Gui.RadioGroup]::new(@("npm", "yarn"))
    $radioGroupPm.X = [Terminal.Gui.Pos]::Right($labelPm) + 1
    $radioGroupPm.Y = $labelPm.Y
    $radioGroupPm.SelectedItem = if ($config.PackageManager -eq 'yarn') { 1 } else { 0 }
    $window.Add($radioGroupPm)

    # --- 4. Default Actions ---
    $labelDefaults = [Terminal.Gui.Label]::new("Default Actions:")
    $labelDefaults.X = 1
    $labelDefaults.Y = [Terminal.Gui.Pos]::Bottom($radioGroupPm) + 2
    $labelDefaults.Width = $labelRegex.Width
    $window.Add($labelDefaults)

    $checkCommit = [Terminal.Gui.CheckBox]::new("Auto-Commit", $config.AutoCommit)
    $checkCommit.X = [Terminal.Gui.Pos]::Right($labelDefaults) + 1
    $checkCommit.Y = $labelDefaults.Y
    $window.Add($checkCommit)

    $checkTag = [Terminal.Gui.CheckBox]::new("Auto-Tag", $config.AutoTag)
    $checkTag.X = $checkCommit.X
    $checkTag.Y = [Terminal.Gui.Pos]::Bottom($checkCommit)
    $window.Add($checkTag)

    $checkPush = [Terminal.Gui.CheckBox]::new("Auto-Push", $config.AutoPush)
    $checkPush.X = $checkCommit.X
    $checkPush.Y = [Terminal.Gui.Pos]::Bottom($checkTag)
    $window.Add($checkPush)

    $checkConfirmPush = [Terminal.Gui.CheckBox]::new("Confirm Push", $config.ConfirmPush)
    $checkConfirmPush.X = $checkCommit.X
    $checkConfirmPush.Y = [Terminal.Gui.Pos]::Bottom($checkPush)
    $window.Add($checkConfirmPush)

    # --- 5. Audit Logging ---
    $labelAudit = [Terminal.Gui.Label]::new("Audit Settings:")
    $labelAudit.X = 1
    $labelAudit.Y = [Terminal.Gui.Pos]::Bottom($checkPush) + 2
    $labelAudit.Width = $labelRegex.Width
    $window.Add($labelAudit)

    $checkEnableAudit = [Terminal.Gui.CheckBox]::new("Enable Audit", $config.Audit.Enabled)
    $checkEnableAudit.X = [Terminal.Gui.Pos]::Right($labelAudit) + 1
    $checkEnableAudit.Y = $labelAudit.Y
    $window.Add($checkEnableAudit)

    $checkPerRepo     = [Terminal.Gui.CheckBox]::new("Per-Repository Logs", $config.Audit.SeparatePerRepo)
    $checkPerRepo.X = $checkEnableAudit.X
    $checkPerRepo.Y = [Terminal.Gui.Pos]::Bottom($checkEnableAudit)
    $window.Add($checkPerRepo)

    $labelMax = [Terminal.Gui.Label]::new("Max Entries:")
    $labelMax.X = $checkPerRepo.X
    $labelMax.Y = [Terminal.Gui.Pos]::Bottom($checkPerRepo)
    $window.Add($labelMax)

    $textMax          = [Terminal.Gui.TextField]::new([string]$config.Audit.MaxEntries)
    $textMax.X = [Terminal.Gui.Pos]::Right($labelMax) + 1
    $textMax.Y = $labelMax.Y
    $textMax.Width = 5
    $window.Add($textMax)

    $labelMaxSize = [Terminal.Gui.Label]::new("Max Size (MB):")
    $labelMaxSize.X = $labelMax.X
    $labelMaxSize.Y = [Terminal.Gui.Pos]::Bottom($labelMax)
    $window.Add($labelMaxSize)

    $textMaxSize         = [Terminal.Gui.TextField]::new([string]$config.Audit.MaxSizeMB)
    $textMaxSize.X = [Terminal.Gui.Pos]::Right($labelMaxSize) + 1
    $textMaxSize.Y = $labelMaxSize.Y
    $textMaxSize.Width = 5
    $window.Add($textMaxSize)

    # --- 5. Buttons ---
    $originalConfig = ($config | ConvertTo-Json -Depth 5) | ConvertFrom-Json

    function Decode-TextField {
        param($text)
        if ($text -is [string]) { return $text }
        if ($text -is [System.ReadOnlyMemory[byte]]) {
            $bytes = $text.ToArray()
            return [System.Text.Encoding]::UTF8.GetString($bytes)
        }
        if ($text -is [System.Collections.IEnumerable]) {
            try { return [System.Text.Encoding]::UTF8.GetString($text) }
            catch { return ($text -join '') }
        }
        return [string]$text
    }

    function Update-Config {
        $config.BranchRegex    = Decode-TextField $textRegex.Text
        $config.CommitTemplate = Decode-TextField $textTemplate.Text
        $config.PackageManager = if ($radioGroupPm.SelectedItem -eq 1) { 'yarn' } else { 'npm' }
        $config.AutoCommit     = $checkCommit.Checked
        $config.AutoTag        = $checkTag.Checked
        $config.AutoPush        = $checkPush.Checked
        $config.ConfirmPush    = $checkConfirmPush.Checked
        $config.Audit = @{
            Enabled    = $checkEnableAudit.Checked
            SeparatePerRepo    = $checkPerRepo.Checked
            MaxEntries = [int]($textMax.Text.ToString())
            MaxSizeMB = [int]($textMaxSize.Text.ToString())
        }
    }

    function Is-ConfigChanged {
        Update-Config
        $currentJson  = $config | ConvertTo-Json -Depth 5
        $originalJson = $originalConfig | ConvertTo-Json -Depth 5
        return ($currentJson -ne $originalJson)
    }

    $btnSave = [Terminal.Gui.Button]::new("Save")
    $btnSave.X = [Terminal.Gui.Pos]::Center() - 10
    $btnSave.Y = [Terminal.Gui.Pos]::AnchorEnd(3)
    $btnSave.add_Clicked({
        Update-Config
        $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $Global:configFile -Encoding utf8BOM
        [Terminal.Gui.MessageBox]::Query("Saved", "Configuration saved successfully!", @("OK")) | Out-Null
        [Terminal.Gui.Application]::RequestStop()
    })
    $window.Add($btnSave)

    $btnCancel = [Terminal.Gui.Button]::new("Cancel")
    $btnCancel.X = [Terminal.Gui.Pos]::Center() + 2
    $btnCancel.Y = [Terminal.Gui.Pos]::AnchorEnd(3)
    $btnCancel.add_Clicked({
        if (Is-ConfigChanged) {
            $choice = [Terminal.Gui.MessageBox]::Query(
                "Unsaved Changes",
                "You have unsaved changes. Save before exiting?",
                @("Save & Exit", "Exit Without Saving", "Cancel")
            )
            switch ($choice) {
                0 { $btnSave.OnClicked() }
                1 { [Terminal.Gui.Application]::RequestStop() }
                default { return }
            }
        } else {
            [Terminal.Gui.Application]::RequestStop()
        }
    })
    $window.Add($btnCancel)

    # --- 6. Hint ---
    $hintLabel = [Terminal.Gui.Label]::new("Tab = navigate | Spacebar = select | Esc/Cancel = exit")
    $hintLabel.X = 1
    $hintLabel.Y = [Terminal.Gui.Pos]::AnchorEnd(1)
    $window.Add($hintLabel)

    # --- Run ---
    $Toplevel.Add($window)
    [Terminal.Gui.Application]::Run()
    [Terminal.Gui.Application]::Shutdown()
}
