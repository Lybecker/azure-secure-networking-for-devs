# Store-EnvVars.ps1

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$EnvVarsToStore
)

# Convert the environment variables to a hashtable
$EnvVarsHashtable = @{}
foreach ($key in $EnvVarsToStore.Keys) {
    $EnvVarsHashtable[$key] = $EnvVarsToStore[$key]
}

# Check if the env-vars.json file exists
if (Test-Path -Path "env.json" -PathType Leaf -ErrorAction SilentlyContinue) {
    $fileContent = Get-Content -Raw -Path "env.json"
    if ($fileContent -ne "") {
        # Load existing environment variables from the file
        $existingEnvVars = $fileContent | ConvertFrom-Json
        # Merge new environment variables with existing ones
        $mergedEnvVars = [ordered]@{}
        $existingEnvVars.PSObject.Properties.Name | ForEach-Object { $mergedEnvVars[$_] = $existingEnvVars.$_ }
        $EnvVarsHashtable.Keys | ForEach-Object { $mergedEnvVars[$_] = $EnvVarsHashtable[$_] }
    } else {
        $mergedEnvVars = $EnvVarsHashtable
    }
} else {
    $mergedEnvVars = $EnvVarsHashtable
}

# Write merged environment variables to the file
$mergedEnvVars | ConvertTo-Json | Out-File -FilePath "env.json"

Write-Output "`nEnvironment variables stored in env.json"