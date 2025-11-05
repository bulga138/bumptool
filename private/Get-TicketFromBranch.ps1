# File: ./BumpTool/private/Get-TicketFromBranch.ps1
function Get-TicketFromBranch {
    param (
        [string]$Branch,
        [string]$Pattern
    )
    
    if ([string]::IsNullOrEmpty($Branch)) { return "" }
    
    $match = [regex]::Match($Branch, $Pattern)
    if ($match.Success) {
        # Return the first capture group, or the full match if no group
        if ($match.Groups.Count -gt 1) {
            return $match.Groups[1].Value
        }
        else {
            return $match.Value
        }
    }
    return "" # No match
}