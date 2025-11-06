<#
PowerShell helper to base64-encode a Java keystore for storing as a GitHub secret.
Usage:
  .\encode-keystore.ps1 -KeystorePath C:\path\to\ai_track.jks -OutFile keystore.b64
Or just:
  .\encode-keystore.ps1 -KeystorePath C:\path\to\ai_track.jks
#>
param(
    [Parameter(Mandatory=$true)] [string]$KeystorePath,
    [Parameter(Mandatory=$false)] [string]$OutFile = ""
)

if (-not (Test-Path $KeystorePath)) {
    Write-Error "Keystore not found: $KeystorePath"
    exit 1
}

try {
    $bytes = [System.IO.File]::ReadAllBytes($KeystorePath)
    $base64 = [Convert]::ToBase64String($bytes)
    if ($OutFile -ne "") {
        Set-Content -Path $OutFile -Value $base64 -Encoding ascii
        Write-Output "Wrote base64 to $OutFile"
    } else {
        Write-Output $base64
    }
} catch {
    Write-Error "Failed to read or encode keystore: $_"
    exit 2
}
