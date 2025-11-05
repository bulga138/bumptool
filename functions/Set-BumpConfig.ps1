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

    # Create buttons for tab navigation
    $btnConfig = [Terminal.Gui.Button]::new("Configuration")
    $btnConfig.X = 1
    $btnConfig.Y = 0
    
    $btnAudit = [Terminal.Gui.Button]::new("Audit Log")
    $btnAudit.X = [Terminal.Gui.Pos]::Right($btnConfig) + 2
    $btnAudit.Y = 0

    # Create views for each "tab"
    $configView = [Terminal.Gui.View]::new()
    $configView.X = 0
    $configView.Y = 3
    $configView.Width = [Terminal.Gui.Dim]::Fill()
    $configView.Height = [Terminal.Gui.Dim]::Fill() - 3

    $auditView = [Terminal.Gui.View]::new()
    $auditView.X = 0
    $auditView.Y = 3
    $auditView.Width = [Terminal.Gui.Dim]::Fill()
    $auditView.Height = [Terminal.Gui.Dim]::Fill() - 3
    $auditView.Visible = $false  # Hidden by default

    # --- Configuration View Elements ---
    # --- 1. Branch Regex ---
    $labelRegex = [Terminal.Gui.Label]::new("Branch Regex Pattern:")
    $labelRegex.X = 1
    $labelRegex.Y = 1
    $labelRegex.Width = 25
    $configView.Add($labelRegex)

    $textRegex = [Terminal.Gui.TextField]::new([string]$config.BranchRegex)
    $textRegex.X = [Terminal.Gui.Pos]::Right($labelRegex) + 1
    $textRegex.Y = $labelRegex.Y
    $textRegex.Width = [Terminal.Gui.Dim]::Fill() - 5
    $configView.Add($textRegex)

    # --- 2. Commit Template ---
    $labelTemplate = [Terminal.Gui.Label]::new("Commit Message Template:")
    $labelTemplate.X = 1
    $labelTemplate.Y = [Terminal.Gui.Pos]::Bottom($labelRegex) + 1
    $labelTemplate.Width = $labelRegex.Width
    $configView.Add($labelTemplate)

    $textTemplate = [Terminal.Gui.TextField]::new([string]$config.CommitTemplate)
    $textTemplate.X = [Terminal.Gui.Pos]::Right($labelTemplate) + 1
    $textTemplate.Y = $labelTemplate.Y
    $textTemplate.Width = [Terminal.Gui.Dim]::Fill() - 5
    $configView.Add($textTemplate)

    $labelHelp = [Terminal.Gui.Label]::new("(Use: {ticket}, {type}, {from}, {to})")
    $labelHelp.X = $textTemplate.X
    $labelHelp.Y = [Terminal.Gui.Pos]::Bottom($textTemplate)
    $configView.Add($labelHelp)

    # --- 3. Package Manager ---
    $labelPm = [Terminal.Gui.Label]::new("Package Manager:")
    $labelPm.X = 1
    $labelPm.Y = [Terminal.Gui.Pos]::Bottom($labelHelp) + 2
    $labelPm.Width = $labelRegex.Width
    $configView.Add($labelPm)

    $radioGroupPm = [Terminal.Gui.RadioGroup]::new(@("npm", "yarn"))
    $radioGroupPm.X = [Terminal.Gui.Pos]::Right($labelPm) + 1
    $radioGroupPm.Y = $labelPm.Y
    $radioGroupPm.SelectedItem = if ($config.PackageManager -eq 'yarn') { 1 } else { 0 }
    $configView.Add($radioGroupPm)

    # --- 4. Default Actions ---
    $labelDefaults = [Terminal.Gui.Label]::new("Default Actions:")
    $labelDefaults.X = 1
    $labelDefaults.Y = [Terminal.Gui.Pos]::Bottom($radioGroupPm) + 2
    $labelDefaults.Width = $labelRegex.Width
    $configView.Add($labelDefaults)

    $checkCommit = [Terminal.Gui.CheckBox]::new("Auto-Commit", $config.AutoCommit)
    $checkCommit.X = [Terminal.Gui.Pos]::Right($labelDefaults) + 1
    $checkCommit.Y = $labelDefaults.Y
    $configView.Add($checkCommit)

    $checkTag = [Terminal.Gui.CheckBox]::new("Auto-Tag", $config.AutoTag)
    $checkTag.X = $checkCommit.X
    $checkTag.Y = [Terminal.Gui.Pos]::Bottom($checkCommit)
    $configView.Add($checkTag)

    $checkPush = [Terminal.Gui.CheckBox]::new("Auto-Push", $config.AutoPush)
    $checkPush.X = $checkCommit.X
    $checkPush.Y = [Terminal.Gui.Pos]::Bottom($checkTag)
    $configView.Add($checkPush)

    $checkConfirmPush = [Terminal.Gui.CheckBox]::new("Confirm Push", $config.ConfirmPush)
    $checkConfirmPush.X = $checkCommit.X
    $checkConfirmPush.Y = [Terminal.Gui.Pos]::Bottom($checkPush)
    $configView.Add($checkConfirmPush)

    # --- 5. Audit Logging ---
    $labelAudit = [Terminal.Gui.Label]::new("Audit Settings:")
    $labelAudit.X = 1
    $labelAudit.Y = [Terminal.Gui.Pos]::Bottom($checkPush) + 2
    $labelAudit.Width = $labelRegex.Width
    $configView.Add($labelAudit)

    $checkEnableAudit = [Terminal.Gui.CheckBox]::new("Enable Audit", $config.Audit.Enabled)
    $checkEnableAudit.X = [Terminal.Gui.Pos]::Right($labelAudit) + 1
    $checkEnableAudit.Y = $labelAudit.Y
    $configView.Add($checkEnableAudit)

    $checkPerRepo     = [Terminal.Gui.CheckBox]::new("Per-Repository Logs", $config.Audit.SeparatePerRepo)
    $checkPerRepo.X = $checkEnableAudit.X
    $checkPerRepo.Y = [Terminal.Gui.Pos]::Bottom($checkEnableAudit)
    $configView.Add($checkPerRepo)

    $labelMax = [Terminal.Gui.Label]::new("Max Entries:")
    $labelMax.X = $checkPerRepo.X
    $labelMax.Y = [Terminal.Gui.Pos]::Bottom($checkPerRepo)
    $configView.Add($labelMax)

    $textMax          = [Terminal.Gui.TextField]::new([string]$config.Audit.MaxEntries)
    $textMax.X = [Terminal.Gui.Pos]::Right($labelMax) + 1
    $textMax.Y = $labelMax.Y
    $textMax.Width = 5
    $configView.Add($textMax)

    $labelMaxSize = [Terminal.Gui.Label]::new("Max Size (MB):")
    $labelMaxSize.X = $labelMax.X
    $labelMaxSize.Y = [Terminal.Gui.Pos]::Bottom($labelMax)
    $configView.Add($labelMaxSize)

    $textMaxSize         = [Terminal.Gui.TextField]::new([string]$config.Audit.MaxSizeMB)
    $textMaxSize.X = [Terminal.Gui.Pos]::Right($labelMaxSize) + 1
    $textMaxSize.Y = $labelMaxSize.Y
    $textMaxSize.Width = 5
    $configView.Add($textMaxSize)

    # --- Buttons ---
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
    $configView.Add($btnSave)

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
    $configView.Add($btnCancel)

    # --- Hint ---
    $hintLabel = [Terminal.Gui.Label]::new("Tab = navigate | Spacebar = select | Esc/Cancel = exit")
    $hintLabel.X = 1
    $hintLabel.Y = [Terminal.Gui.Pos]::AnchorEnd(1)
    $configView.Add($hintLabel)

    # --- Audit Log View Elements ---
    # Create filter controls
    
    # Sort Radio Group
    $labelSort = [Terminal.Gui.Label]::new("Sort Order:")
    $labelSort.X = 1
    $labelSort.Y = 0
    $auditView.Add($labelSort)

    $radioSort = [Terminal.Gui.RadioGroup]::new(@("Newest First", "Oldest First"))
    $radioSort.X = [Terminal.Gui.Pos]::Right($labelSort) + 1
    $radioSort.Y = 0
    $radioSort.SelectedItem = 0  # Newest First by default
    $auditView.Add($radioSort)

    # Type Radio Group
    $labelType = [Terminal.Gui.Label]::new("Type:")
    $labelType.X = [Terminal.Gui.Pos]::Right($radioSort) + 3
    $labelType.Y = 0
    $auditView.Add($labelType)

    $radioType = [Terminal.Gui.RadioGroup]::new(@("All", "patch", "minor", "major"))
    $radioType.X = [Terminal.Gui.Pos]::Right($labelType) + 1
    $radioType.Y = 0
    $radioType.SelectedItem = 0  # All by default
    $auditView.Add($radioType)

    # Branch ComboBox
    $labelBranch = [Terminal.Gui.Label]::new("Branch:")
    $labelBranch.X = [Terminal.Gui.Pos]::Right($radioType) + 1
    $labelBranch.Y = 0
    $auditView.Add($labelBranch)

    $branchItems = @("All")
    $comboBranch = [Terminal.Gui.ComboBox]::new($branchItems)
    $comboBranch.X = [Terminal.Gui.Pos]::Right($labelBranch) + 1
    $comboBranch.Y = 0
    $comboBranch.Width = 20
    $comboBranch.SelectedItem = 0
    $auditView.Add($comboBranch)

    # Create a TextView for displaying audit logs
    $textView = [Terminal.Gui.TextView]::new()
    $textView.X = 1
    $textView.Y = 5
    $textView.Width = [Terminal.Gui.Dim]::Fill() - 1
    $textView.Height = [Terminal.Gui.Dim]::Fill() - 6
    $textView.ReadOnly = $true
    $textView.AllowsTab = $false

    # Add navigation help
    $navLabel = [Terminal.Gui.Label]::new("Navigation: ↑/↓/PageUp/PageDown/Home/End | q/Q = Quit | Tab = Navigate Controls")
    $navLabel.X = 1
    $navLabel.Y = [Terminal.Gui.Pos]::AnchorEnd(2)
    $auditView.Add($navLabel)

    # Global variables to store state
    $script:auditLogs = @()
    $script:filteredLogs = @()
    $script:branchItems = $branchItems

    # Function to load and display audit logs with filters
    function Update-AuditDisplay {
        try {
            # Get filter values
            $sortByText = @("Newest First", "Oldest First")[$radioSort.SelectedItem]
            $typeText = @("All", "patch", "minor", "major")[$radioType.SelectedItem]
            
            $branchText = if ($comboBranch.SelectedItem -ge 0 -and $comboBranch.SelectedItem -lt $script:branchItems.Count) { 
                $script:branchItems[$comboBranch.SelectedItem] 
            } else { 
                "All" 
            }
            
            Write-Host "Filters: Sort=$sortByText, Type=$typeText, Branch=$branchText" # Debug
            
            # Apply filters
            $filteredLogs = $script:auditLogs
            
            # Filter by type
            if ($typeText -and $typeText -ne "All" -and $typeText -ne "") {
                $filteredLogs = $filteredLogs | Where-Object {
                    $entryType = if ($_.bumpType) { $_.bumpType } 
                                elseif ($_.Action) { $_.Action } 
                                else { $null }
                    $entryType -eq $typeText
                }
            }
            
            # Filter by branch
            if ($branchText -and $branchText -ne "All" -and $branchText -ne "") {
                $filteredLogs = $filteredLogs | Where-Object {
                    $entryBranch = if ($_.branch) { $_.branch } 
                                  elseif ($_.Branch) { $_.Branch }
                                  else { $null }
                    $entryBranch -eq $branchText
                }
            }
            
            $script:filteredLogs = $filteredLogs
            
            # Sort
            if ($sortByText -eq "Newest First") {
                # Newest First
                $sortedLogs = $filteredLogs | Sort-Object @{Expression={Get-AuditTimestamp $_}; Descending=$true}
            } else {
                # Oldest First
                $sortedLogs = $filteredLogs | Sort-Object @{Expression={Get-AuditTimestamp $_}; Descending=$false}
            }
            
            # Format for display
            $auditContent = Format-AuditLogs $sortedLogs
            $textView.Text = $auditContent
        } catch {
            $textView.Text = "Error filtering audit log: $($_.Exception.Message)"
        }
    }
    
    # Helper function to get timestamp from audit entry
    function Get-AuditTimestamp {
        param($logEntry)
        if ($logEntry.timestamp) {
            try { return [datetime]::Parse($logEntry.timestamp) } catch { return [datetime]::MinValue }
        } elseif ($logEntry.Timestamp) {
            try { return [datetime]::Parse($logEntry.Timestamp) } catch { return [datetime]::MinValue }
        } else {
            return [datetime]::MinValue
        }
    }
    
    # Helper function to format logs for display
    function Format-AuditLogs {
        param($logs)
        
        if ($logs.Count -eq 0) {
            return "No audit entries match the selected filters."
        }
        
        $output = ""
        foreach ($log in $logs) {
            $timestamp = if ($log.timestamp) {$log.timestamp} else {$log.Timestamp}
            $user = if ($log.user) {$log.user} else {$log.User}
            $project = if ($log.project) {$log.project} else {$log.Repository}
            $branch = if ($log.branch) {$log.branch} elseif ($log.Branch) {$log.Branch} else {""}
            $bumpType = if ($log.bumpType) {$log.bumpType} else {$log.Action}
            $from = if ($log.from) {$log.from} else {""}
            $to = if ($log.to) {$log.to} else {""}
            
            $output += "Timestamp: ${timestamp}`n"
            $output += "User: ${user}`n"
            $output += "Project: ${project}`n"
            if ($branch -and $branch -ne "") { $output += "Branch: ${branch}`n" }
            if ($bumpType -and $bumpType -ne "") { $output += "Action: ${bumpType}`n" }
            if (($from -or $to) -and ($from -ne "" -or $to -ne "")) { $output += "Version: ${from} -> ${to}`n" }
            
            # Add other details
            $log.PSObject.Properties | ForEach-Object {
                $name = $_.Name
                $value = $_.Value
                # Skip already displayed properties
                if ($name -notin @('timestamp', 'Timestamp', 'user', 'User', 'project', 'Project', 'Repository', 'branch', 'Branch', 'bumpType', 'Action', 'from', 'to')) {
                    if ($value -ne $null -and $value -ne '') {
                        $output += "${name}: ${value}`n"
                    }
                }
            }
            
            $output += "-" * 50 + "`n`n"
        }
        
        return $output
    }
    
    # Function to get raw audit logs
    function Get-BumpAuditLogs {
        $config = Get-BumpConfig
        $repoName = try {
            (git rev-parse --show-toplevel 2>$null | Split-Path -Leaf)
        } catch {
            (Get-Item .).Name
        }
        
        $logBase = Join-Path $env:USERPROFILE "Documents\BumpTool\logs"
        $logDir = if ($config.Audit.SeparatePerRepo -and $repoName) {
            Join-Path $logBase $repoName
        } else {
            Join-Path $logBase "global"
        }
        $logFile = Join-Path $logDir "bump-audit.json"

        if (-not (Test-Path $logFile)) {
            Write-Host "Audit log file not found: $logFile"
            return @()
        }

        try {
            Write-Host "Reading audit log from: $logFile"
            # Try to read as JSON lines first (new format)
            $content = Get-Content $logFile -Raw
            if ([string]::IsNullOrWhiteSpace($content)) {
                Write-Host "Audit log file is empty"
                return @()
            }

            # Try to parse as array of JSON objects
            $logs = $content | ConvertFrom-Json -ErrorAction Stop
            Write-Host "Parsed $($logs.Count) audit entries"
            if ($logs -is [array]) {
                return $logs
            } else {
                return @($logs)
            }
        } catch {
            Write-Host "Error parsing audit log: $($_.Exception.Message)"
            # Try to read as JSON lines (one JSON object per line)
            try {
                $lines = Get-Content $logFile
                if ($lines.Count -eq 0) {
                    Write-Host "Audit log file has no lines"
                    return @()
                }
                
                $logs = @()
                foreach ($line in $lines) {
                    if (-not [string]::IsNullOrWhiteSpace($line)) {
                        try {
                            $logEntry = $line | ConvertFrom-Json
                            $logs += $logEntry
                        } catch {
                            Write-Host "Skipping malformed line: $line"
                            # Skip malformed lines
                        }
                    }
                }
                Write-Host "Parsed $($logs.Count) audit entries from lines"
                return $logs
            } catch {
                Write-Host "Error reading audit log lines: $($_.Exception.Message)"
                return @()
            }
        }
    }
    
    # Function to populate branch dropdown
    function Update-BranchDropdown {
        try {
            Write-Host "Updating branch dropdown with $($script:auditLogs.Count) logs"
            $logs = $script:auditLogs
            $branches = @("All")
            
            $uniqueBranches = $logs | ForEach-Object {
                $branch = if ($_.branch) { $_.branch } elseif ($_.Branch) { $_.Branch } else { $null }
                if ($branch -and $branch -ne "") { $branch }
            } | Sort-Object -Unique
            
            Write-Host "Found unique branches: $($uniqueBranches -join ', ')"
            $branches += $uniqueBranches
            
            # Store the new branch items
            $script:branchItems = $branches
            
            # Remove old combo box
            $auditView.Remove($comboBranch)
            
            # Create new ComboBox with updated branches
            $comboBranch = [Terminal.Gui.ComboBox]::new($branches)
            $comboBranch.X = [Terminal.Gui.Pos]::Right($labelBranch) + 1
            $comboBranch.Y = 0  # Same Y as the label
            $comboBranch.Width = 20
            $comboBranch.SelectedItem = 0
            $auditView.Add($comboBranch)
            
            # Reattach event handler
            $comboBranch.add_SelectedItemChanged({
                Write-Host "Branch changed"
                Update-AuditDisplay
            })
            
            # Update the global reference
            $script:comboBranch = $comboBranch
            
        } catch {
            Write-Host "Error updating branch dropdown: $($_.Exception.Message)"
            # If error, keep defaults
        }
    }

    $auditView.Add($textView)

    # Setup button click events for tab switching
    $btnConfig.add_Clicked({
        $configView.Visible = $true
        $auditView.Visible = $false
        $btnConfig.SetFocus()
    })

    $btnAudit.add_Clicked({
        Write-Host "Switching to audit tab..."
        $configView.Visible = $false
        $auditView.Visible = $true
        # Load data when switching to audit tab
        Write-Host "Loading audit logs..."
        $script:auditLogs = Get-BumpAuditLogs
        Write-Host "Loaded $($script:auditLogs.Count) audit logs"
        Update-BranchDropdown
        Update-AuditDisplay
        $textView.SetFocus()
    })

    # Setup filter events - RadioGroups trigger on selection change
    $radioSort.add_SelectedItemChanged({
        Write-Host "Sort changed to item $($radioSort.SelectedItem)"
        Update-AuditDisplay
    })
    
    $radioType.add_SelectedItemChanged({
        Write-Host "Type changed to item $($radioType.SelectedItem)"
        Update-AuditDisplay
    })
    
    $comboBranch.add_SelectedItemChanged({
        Write-Host "Branch changed"
        Update-AuditDisplay
    })

    # Handle key presses for the audit log tab
    $keyEventHandler = {
        param($sender, $e)
        
        # Get the key character (handle both char and numeric key codes)
        $keyChar = if ($e.KeyEvent.Key -is [char]) {
            $e.KeyEvent.Key
        } else {
            [char]$e.KeyEvent.Key
        }
        
        # Quit on "q" or "Q"
        if ($keyChar -eq 'q' -or $keyChar -eq 'Q') {
            [Terminal.Gui.Application]::RequestStop()
            $e.Handled = $true
        }
    }
    
    # Add the event handler to the textView
    $textView.add_KeyDown($keyEventHandler)

    # Add elements to window
    $window.Add($btnConfig)
    $window.Add($btnAudit)
    $window.Add($configView)
    $window.Add($auditView)

    # Set initial focus to config view
    $configView.Visible = $true
    $auditView.Visible = $false

    # --- Run ---
    $Toplevel.Add($window)
    [Terminal.Gui.Application]::Run()
    [Terminal.Gui.Application]::Shutdown()
}
