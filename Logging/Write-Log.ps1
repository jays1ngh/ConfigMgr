
function Write-Log {
    [CmdletBinding()]
     param(
     [Parameter()]
     [ValidateNotNullOrEmpty()]
     [string]$Message,
     [parameter(Mandatory=$true)]
     [String]$Component,
     [Parameter(Mandatory=$true)]
     [ValidateSet("Info", "Warning", "Error")]
     [String]$Type
     )

     switch ($Type) {
        "Info" { [int]$Type = 1 }
        "Warning" { [int]$Type = 2 }
        "Error" { [int]$Type = 3 }
        }

$ProgramDataPath = ($env:ProgramData)
$LogFile = "$ProgramDataPath\CCMCache\Logs\CCMCache.log"

if(-not(Test-Path $LogFile))
    {
        New-Item -Name CCMCache.log -ItemType File `
        -Path "$ProgramDataPath\CCMCache\Logs\" -Force
    }
    
    $LogTime = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $LogDate = (Get-Date -Format MM-dd-yyyy)
    $LogEntry = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LogFormat = $Message, $LogTime, $LogDate, $Component, $Type
    $LogEntry = $LogEntry -f $LogFormat
    Add-Content -Value $LogEntry -Path $LogFile

} #write-Log
