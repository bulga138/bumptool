function Set-ClipboardHelper {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Content
    )
    $nc = $env:NO_CLIP
    if ($null -ne $nc -and ('1', 'true', 'yes' -contains $nc.ToLower())) {
        return $true
    }
    try {
        $Content | Set-Clipboard -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Failed to copy to clipboard. $_"
        return $false
    }
}