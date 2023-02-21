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
$ProcessingParameter = 0

foreach ($Line in Get-Content $FilePath) {
    if ($Line.Trim().StartsWith("param")) {
        $ProcessingParameter = 1
    } elseif ($Line.Trim().StartsWith(")")) {
        $ProcessingParameter = 0
        $Line = ""
    }

    if ($ProcessingParameter -gt 0) {
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
            }
        }
    }

    $Line = $Line.Replace(" = ", "=")
    $Line = $Line.Replace('`', '\')

    Write-Output $Line
    Add-Content $OutFilePath $Line
}