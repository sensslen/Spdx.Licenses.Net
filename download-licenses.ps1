# Accept output folder as a command line parameter
param(
    [string]$outputDir = "SpdxLicenseData"
)

# Define URLs and output directory
$licensesUrl = "https://spdx.org/licenses/licenses.json"
$licensesDirectory = "Licenses"

# Create output directory if it doesn't exist
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}
Push-Location $outputDir

# Download licenses.json
$licensesJsonFile = "licenses.json"
Invoke-WebRequest -Uri $licensesUrl -OutFile $licensesJsonFile

# Parse licenses.json
$licensesData = Get-Content $licensesJsonFile | ConvertFrom-Json

# Create license output directory if it doesn't exist
if (!(Test-Path $licensesDirectory)) {
    New-Item -ItemType Directory -Path $licensesDirectory | Out-Null
}
Push-Location $licensesDirectory

# Download details for each license
foreach ($license in $licensesData.licenses) {
    $licenseId = $license.licenseId
    $detailsUrl = $license.detailsUrl

    # Download and save license details
    try {
        Invoke-WebRequest -Uri $detailsUrl -OutFile "$licenseId.json"
        Write-Host "Downloaded $licenseId"
    } catch {
        Write-Host "Failed to download $licenseId from $detailsUrl"
    }
}

Pop-Location
Pop-Location
