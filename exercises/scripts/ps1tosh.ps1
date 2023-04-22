# Very dumb script to create Bash scripts from veeeery simple PowerShell scripts

param(
    [Parameter(Mandatory=$True)][string]$FilePath
)

if (-not ($FilePath -Match ".ps1")) {
    Write-Error "File path missing .ps1 filename extension"
    exit 1
}

$OutFilePath = $FilePath.Replace("ps1", "sh")
Set-Content $OutFilePath "#!/bin/bash"
Add-Content $OutFilePath "set -e"
$ProcessingParameter = 0
$MandatoryParameters = @()

foreach ($Line in Get-Content $FilePath) {
    if ($Line.Trim().StartsWith("param")) {
        $ProcessingParameter = 1
    } elseif ($Line.Trim().StartsWith(")")) {
        $ProcessingParameter = 0

        foreach ($MandatoryParameter in $MandatoryParameters) {
            $VariableCheck = "if [ -z `"`$${MandatoryParameter}`" ]; then`n  echo >&2 `"Required parameter \`"${MandatoryParameter}\`" missing`"`n  exit 1`nfi"
            Write-Output $VariableCheck
            Add-Content $OutFilePath $VariableCheck
        }

        $Line = ""
    }

    if ($ProcessingParameter -gt 0) {
        $Mandatory = $Line.ToLower() -Match 'mandatory'
        $ParameterFound = $Line -Match ']\$(?<ParameterName>.+)$'
        $Line = ""

        if ($ParameterFound) {
            $ParameterName = $Matches.ParameterName.Replace(',', '')

            if ($ParameterName -Match "=") {
                $ParameterName = $ParameterName.Replace(' ', '')
                $Line = "`$${ParameterName}"
            } else {
                $Line = "`$${ParameterName}=`$${ProcessingParameter}"
                $ProcessingParameter = $ProcessingParameter + 1

                if ($Mandatory) {
                    $MandatoryParameters += $ParameterName
                }
            }
        }
    }

    $Line = $Line -Replace "^\$", ""
    $Line = $Line.Replace(" = ", "=")
    $Line = $Line.Replace('`', '\')
    $Line = $Line.Replace("Write-Output", "echo -e")
    $Line = $Line.Replace("Start-Sleep -Seconds", "sleep")

    # TODO:
    # - if statements
    # - string.ToLower() => echo "$string" | tr '[:upper:]' '[:lower:]'
    # - Invoke-Expression => ???
    # - foreach
    # - string.Replace() => ???
    # - string ends with

    Write-Output $Line
    Add-Content $OutFilePath $Line
}