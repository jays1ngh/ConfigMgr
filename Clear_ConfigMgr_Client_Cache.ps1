<#
.SYNOPSIS
    Clear ConfigMgr Client Cache
.DESCRIPTION
    Clear ConfigMgr Client Cache and logs in the %ProgramData%\CCM\Logs\ClearConfigMgrCache.log
.NOTES
    Filename: Clear-ConfigMgr-Client-Cache.ps1
    Version: 1.0
    Author: Jay Singh
    Blog: www.blog.masteringmdm.com
    Twitter: @thisisjaysingh
#>

# Check for administrative rights
if (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning -Message "The script requires elevation"
    break
}

# Create Write-Log function
function Write-Log {

    [CmdletBinding()]
     param(
     [Parameter()]
     [ValidateNotNullOrEmpty()]
     [string]$Message,
     [Parameter(Mandatory=$false)]
     [string]$LogFile = "$env:ProgramData\CCM\Logs\ClearConfigMgrCache.log",
     [parameter(Mandatory=$false)]
     [String]$Component = "",
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

        if ((Test-Path $LogFile)) {
            $LogSize = (Get-Item -Path $LogFile).Length/1MB
            $maxLogSize = 5
            }

            # Check for file size of the log. If greater than 5MB, it will create a new one and delete the old.
        if ((Test-Path $LogFile) -AND $LogSize -gt $MaxLogSize) {
            Write-Error "Log file $LogFile already exists. Deleting $LogFile and creating new one"
            Remove-Item $LogFile -Force
            New-Item -Path $LogFile -ItemType File -Force
            }

            # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif(-not(Test-Path $LogFile))
            {
            Write-Verbose "Creating $LogFile"
            New-Item -Path $LogFile -ItemType File -Force
            }

    $LogTime = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $LogDate = (Get-Date -Format MM-dd-yyyy)
    $LogEntry = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LogFormat = $Message, $LogTime, $LogDate, $Component, $Type
    $LogEntry = $LogEntry -f $LogFormat
    # Out-File -InputObject $LogLine -Append -NoClobber -Encoding Default -FilePath $LogFile -WhatIf:$False
    Out-File -InputObject $LogEntry -Append -NoClobber -Encoding default -FilePath $LogFile
    }

    End {
    }
} #End function Write-Log

function Write-TotalClientCacheLog {
    [CmdletBinding()]
    param (
    )

    Begin {
        #create a new object from UIResource.UIResourceMgr
        try {
            $resman= New-Object -ComObject "UIResource.UIResourceMgr"
        }

        catch [System.Exception] {
            Write-Log "*******************************" -Type Info
            Write-Log -Message "Failed to create object UIResource.UIResourceMgr" -Type Error
            Write-Warning "Failed to create object UIResource.UIResourceMgr"
            Write-Log -Message "$($_.Exception.Message)" -Component "Clear_ConfigMgr_Client_Cache.ps1" -Type Error
            Write-Host "*******************************"
            Write-Host "Check logs for more information" -ForegroundColor Yellow
            }

        # Create CacheInfo property and calculate total free cache size
        try {
            $CacheInfo=$resman.GetCacheInfo()
            $CacheSize = $CacheInfo.TotalSize
            }

        catch [System.Exception] {
            Write-Log -Message "Failed to create variable CacheInfo and cannot continue to calculate Total Cache Size" -Type Error
            Write-Warning "Failed to create variable CacheInfo and cannot continue to calculate Total Cache Size"
            Write-Log -Message "$($_.Exception.Message)" -Component "Clear_ConfigMgr_Client_Cache.ps1" -Type Error
            Write-Host "*******************************"
            Write-Host "Check logs for more information" -ForegroundColor Yellow
            Break
            }

    }

    Process {

        Write-Log -Message "Total client cache Size is $CacheSize MB" -Component "ClientCache - CacheSize" -Type Info
    }

    End {
    }

} # End function Write-TotalClientCacheLog
function Write-FreeClientCacheLog {
    [CmdletBinding()]
    param (
    )

    Begin {
        # Create a new object from UIResource.UIResourceMgr
        $resman= New-Object -ComObject "UIResource.UIResourceMgr"
        # CacheInfo property
        $CacheInfo=$resman.GetCacheInfo()
    }

    Process {
        # Log Free Client Cache size
        $CacheFree = $CacheInfo.FreeSize
        Write-Log -Message "Free client cache Size is $CacheFree MB" -Component "ClientCache - CacheSize" -Type Info
    }

    End {
    }

} # End function Write-FreeClientCacheLog

function Write-ExpectedFreeClientCacheLog {
    [CmdletBinding()]
    param (
    )

    Begin {
        # Create a new object from UIResource.UIResourceMgr
        $resman= New-Object -ComObject "UIResource.UIResourceMgr"
        # CacheInfo property
        $CacheInfo=$resman.GetCacheInfo()
    }

    Process {
        #Log Expected Free Client Cache size
        $CacheSize = $CacheInfo.TotalSize
        $CacheFree = $CacheInfo.FreeSize
        $CacheFreeExpected = $CacheSize - $CacheFree
        Write-Log -Message "Clear-ConfigMgr-Client-Cache will remove approx $CacheFreeExpected MB" -Component "ClientCache" -Type Info
    }

    End {
    }

} # End function Write-ExpectedFreeClientCacheLog

function Clear-ClientCache {
    [CmdletBinding()]
    param (
    )

    Begin {
        # create a new object from UIResource.UIResourceMgr
        $resman= New-Object -ComObject "UIResource.UIResourceMgr"
        # cacheInfo property
        $CacheInfo=$resman.GetCacheInfo()
    }

    Process {
        # Clear client cache
        $CacheInfo.GetCacheElements()  | ForEach-Object {$CacheInfo.DeleteCacheElement($_.CacheElementID)}
    }

    End {
    }
} # End function Clear-ClientCache

# Log Client Cache size
Write-TotalClientCacheLog
Write-FreeClientCacheLog

# Clear cache try 1
Write-Log -Message "Clearing ConfigMgr client cache try 1..." -Component "ClientCache" -Type Info
Write-Verbose "Deleting ConfigMgr client cache"
Write-ExpectedFreeClientCacheLog
Clear-ClientCache

# Wait for 15 seconds
Write-Log -Message "Clear client cache will run second try in 15 seconds" -Component "ClientCache" -Type Info
Start-Sleep -Seconds 15

# Clear cache try 2
Write-Log -Message "Clearing ConfigMgr client cache try 2..." -Component "ClientCache" -Type Info
Write-Verbose "Deleting ConfigMgr client cache"
Write-ExpectedFreeClientCacheLog
Clear-ClientCache

# Log Client Cache size
Write-TotalClientCacheLog
Write-FreeClientCacheLog

# Log script is finished
Write-Log -Message "Clear-ConfigMgr-Client-Cache scpript has finished" -Component "ClientCache" -Type Info
