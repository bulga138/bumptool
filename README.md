# BumpTool

A powerful PowerShell utility for automating `package.json` version bumps with customizable commit messages, optional Git integration, and smart branch parsing.

BumpTool seamlessly blends the convenience of CLI aliases (`bump-patch`, `bump-minor`, `bump-major`) with an intuitive Text-based User Interface (TUI) to configure behavior — no manual script editing required.

---

## Features

- Fast Aliases: Use `bump-patch`, `bump-minor`, or `bump-major` directly in your project root
- Configurable TUI: Easily customize settings via `Set-BumpConfig` using a simple terminal GUI
- Smart Branch Parsing: Automatically extract ticket numbers (e.g., `PROJ-123`) from current branch names using Regex
- Conventional Commit Messages: Customize how commit messages are formatted using a flexible template engine
- Full Automation: Optionally auto-commit and auto-tag each bump for consistent release workflows
- Package Manager Support: Compatible with both npm and yarn

---

## Installation

### Prerequisites

Install the TUI framework dependency first:

```powershell
Install-Module Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser
```

> Note: This module is required for BumpTool's TUI functionality.

### Option A: Manual Install (From Source)

1. Clone this repository or download the ZIP archive
2. Place the entire `BumpTool` folder (containing `BumpTool.psd1`) into one of your PowerShell module paths, such as:
   - Windows: `C:\Users\<YourUser>\Documents\PowerShell\Modules\`
3. Unblock the files to avoid execution policy issues:
   ```powershell
   Get-ChildItem -Path "$env:USERPROFILE\Documents\PowerShell\Modules\BumpTool" -Recurse | Unblock-File
   ```
4. Test the installation by importing the module:
   ```powershell
   Import-Module BumpTool
   ```

### Option B: PowerShell Gallery (Coming Soon)

Once published, BumpTool will be available via:

```powershell
Install-Module BumpTool -Scope CurrentUser
```

---

## Usage Guide

### Step 1: Configure Settings (Initial Setup)

Run the interactive configuration UI at least once before use:

```powershell
Set-BumpConfig
```

Use the TUI to adjust templates, regex patterns, package manager, and automation options. Save to persist settings.
> Tip: Press `Ctrl + Q` to exit the configuration screen.

### Step 2: Daily Workflow

Navigate to your Node.js project directory and run any of the bump commands:

```powershell
# Increment patch version (1.2.3 → 1.2.4)
bump-patch

# Increment minor version (1.2.3 → 1.3.0)
bump-minor

# Increment major version (1.2.3 → 2.0.0)
bump-major
```

#### What happens when you bump?

Each bump performs the following steps:

1. Reads the current version from `package.json`
2. Updates the version using `npm version` or `yarn version`
3. Extracts a ticket reference (e.g., `PROJ-123`) from the current branch name
4. Formats a customizable commit message using the extracted ticket
5. Copies the message to clipboard for manual review or commits automatically if enabled
6. Optionally runs `git add`, `git commit`, and `git tag`

### Step 3: Advanced Usage (Flags & Overrides)

Override default behavior on a per-command basis:

```powershell
# Force commit and tag for this operation only
bump-minor -Commit -Tag

# Perform a dry run to preview changes without applying them
bump-patch -WhatIf

# Explicitly disable commit/tag even if enabled globally
bump-patch -Commit:$false -Tag:$false
```

---

## Configuration Reference

Settings are saved in `config.json` and edited using `Set-BumpConfig`.

### Configuration Options

| Setting | Description |
|---------|-------------|
| Branch Regex Pattern | RegEx used to extract ticket IDs (e.g., `PROJ-123`) from Git branches. Default: `([A-Z]+-\d+)` — matches standard Jira-style tickets |
| Commit Message Template | Template for generated Git commit messages. Available placeholders: `{ticket}` – extracted ticket ID, `{type}` – bump type (`patch`, `minor`, `major`), `{from}` – old version number, `{to}` – new version number, `{name}` – name from `package.json`. Default: `feat({ticket}): bump version {from} to {to} ({type})` |
| Package Manager | Choose between `npm` and `yarn`. Default: `npm` |
| Auto-Commit | Enables automatic `git add . && git commit -m "..."`. Default: false |
| Auto-Tag | Enables automatic `git tag v<new-version>` after bumping. Default: false |

---

## License

This project is licensed under the MIT License. See LICENSE for details.
