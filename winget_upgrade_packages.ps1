param (
    [string]$excludeStartsWith = "Sonic"
)

# Function to check if a string starts with the specified prefix
function StartsWithPrefix($packageName, $prefix) {
    return $packageName.StartsWith($prefix)
}

# Get list of upgradeable packages using winget
$upgradeablePackages = winget upgrade

# Define the regex pattern
$regexPattern = '^.*[\s]([\w\.]+)[\s]+[\d\.]+[\s]+[\d\.]+[\s]+winget$'

# Extract package names using regex
$packageNames = $upgradeablePackages -split "`n" | ForEach-Object {
    if ($_ -match $regexPattern) {
        $matches[1]
    }
}

# Iterate through each package name
foreach ($packageName in $packageNames) {
    # Write-Host "parsed: $packageName"
    # Check if package name starts with the specified prefix
    if (StartsWithPrefix $packageName $excludeStartsWith) {
        Write-Host "Skipping upgrade for package: $packageName (starts with '$excludeStartsWith')"
    } else {
        Write-Host "Upgrading package: $packageName"
        # Perform upgrade using winget
        winget upgrade $packageName
    }
}