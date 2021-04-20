<#
.SYNOPSIS
Writes log in a format compatible with CMTrace log tool.
.DESCRIPTION
This function saves log file as CCM.log in $ProgramDataPath\CCM\Logs directory in a specific
format so that it can be easily read by Configuration Manager Trace Log Tool.
.PARAMETER Message
Adds message in the log file.
.PARAMETER Component
Specifies component name relative to the message saved.
.PARAMETER Type
Valid values: Info, Warning or Error. Will display the message according to 
the type of message. Info has a standard colour. Warning and Error has a 
yello and red colour background respectively.
.EXAMPLE
Write-Log -Message "Cache Size is 100MB" -Component "CacheSize" -Type Info
This example will add an Informational log line with a message listed above
and it will add Component name in the Component Column.
.NOTES
    Filename: Write-Log.ps1
    Version: 1.0
    Author: Jay Singh
    Blog: www.blog.masteringmdm.com
    Twitter: @thisisjaysingh
    Version history:
    1.0   -   Script created  

#>
function Write-Log {
    [CmdletBinding()]
     param(
     [Parameter()]
     [ValidateNotNullOrEmpty()]
     [string]$Message,
     [Parameter(Mandatory=$false)]
     [string]$LogFile = "$env:ProgramData\CCM\Logs\CCM.log",
     [parameter(Mandatory=$true)]
     [String]$Component,
     [Parameter(Mandatory=$true)]
     [ValidateSet("Info", "Warning", "Error")]
     [String]$Type
     )


    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $verbosePreference = 'Continue'
        }
    
    Process {
    
        switch ($Type) {
            "Info" { [int]$Type = 1 }
            "Warning" { [int]$Type = 2 }
            "Error" { [int]$Type = 3 }
            }
    if(-not(Test-Path $LogFile))
    {
        New-Item -Name CCM.log -ItemType File `
        -Path "$ProgramDataPath\CCM\Logs\" -Force
    }
    
    $LogTime = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $LogDate = (Get-Date -Format MM-dd-yyyy)
    $LogEntry = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LogFormat = $Message, $LogTime, $LogDate, $Component, $Type
    $LogEntry = $LogEntry -f $LogFormat
    Add-Content -Value $LogEntry -Path $LogFile
    }

    End {   
    }
}