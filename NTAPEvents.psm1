function Get-DefinedNTAPEvents()
{
    <#
        .SYNOPSIS
        Gathers performance data from cDOT storage systems.
        
        .DESCRIPTION
        Uses the Data ONTAP PowerShell toolkit to gather performance and configuration about a system. 
        
        .PARAMETER Name
        The system name or IP address of the cluster admin SVM to gather the data from.

        .EXAMPLE
        PS C:\> Start-NTAPPerformance
        
        .LINK
        https://none
        
        .INPUTS
        [System.String[]] or [NetApp.Ontapi.AbstractController[]]
        
        .OUTPUTS
        []
        
        .NOTES
        AUTHOR : Joseph Pulk
        REQUIRES
        : PowerShell 2.0
        : Data ONTAP PowerShell Toolkit 3.2.1
        BURTS
        : 
    #>
    
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [OutputType([System.Management.Automation.PSObject])]
    param (
        [Parameter(ParameterSetName = 'Name', Mandatory = $false, Position = 0, ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'The name(s) of the system to gather the data from.')]
        [ValidateNotNullOrEmpty()]
        [Alias('ClusterName')]
        [Alias('SystemName')]
        [string[]]$Name
    )
    function New-NTAPPEventObject{
        param(
            $ID,$Name,$Definition,$Command
        )
        $NTAPPEventObjectObj = New-Object -TypeName Psobject -Property @{ID=$ID;Name=$Name;Definition=$Definition;Command=$Command}

    }
    $NTAPPEventObjects = @()
    #Process Milestones - 000 - 99

    #Informational Alerts - 100 - 199
    $NTAPPEventObjects += New-NTAPPEventObject -ID 101 -Name UsingRealtimeStats -Definition "User Opted to use realtime Statistics instead of past CM Stats." -Command "Get-NcAutoSupportPerf"
    $NTAPPEventObjects += New-NTAPPEventObject -ID 106 -Name ConnectingtoCluster -Definition "No Connection to Cluster Present, Attempting to Connect to cluster" -Command "Get-NTAPCustomerInfo"
    #Warnings - 200 -299
    $NTAPPEventObjects += New-NTAPPEventObject -ID 201 -Name AutoSupportPerfDisabled -Definition "AutoSupport Configuration for Performance Collection is disabled." -Command "Get-NcAutoSupportPerf"
    #Errors - 300+
    $NTAPPEventObjects += New-NTAPPEventObject -ID 301 -Name ResolveHostName -Definition "Unable to Resolve IP Address for hostname"
    $NTAPPEventObjects += New-NTAPPEventObject -ID 302 -Name InaccessibleIP -Definition "Unable to Ping IP Address"
    $NTAPPEventObjects += New-NTAPPEventObject -ID 303 -Name IPVariableMissing -Definition "IP Adress still not specified. Please run the Start-NTAPPerformance command again."
    $NTAPPEventObjects += New-NTAPPEventObject -ID 304 -Name MissingASUP -Definition "No Performance ASUP was found on the cluster for the specified time period." -Command "Get-NcAutoSupportPerf"
    $NTAPPEventObjects += New-NTAPPEventObject -ID 305 -Name MissingClusterConnection -Definition "The command required a connection to a NetApp cluster." -Command "Get-NcAutoSupportPerf"
    $NTAPPEventObjects += New-NTAPPEventObject -ID 306 -Name MissingClusterConnection -Definition "No Management interfaces were found. Configure the nodes with interfaces that have the role node_mgmt." -Command "Get-NcAutoSupportPerf"
    $NTAPPEventObjects += New-NTAPPEventObject -ID 307 -Name MissingCustomerObject -Definition "Customer Object Missing. Please run the Command Again" -Command "Start-NTAPPerformance"
    $NTAPPEventObjects += New-NTAPPEventObject -ID 308 -Name MissingPerfMetaFile -Definition "Counter Meta File Inaccessible. Please ensure file is accessible." -Command "Start-NTAPPerformance"
    $NTAPPEventObjects += New-NTAPPEventObject -ID 309 -Name MissingPerfCouterArray -Definition "The Array of Performance Counters is missing or there are not valid instances."  -Command "Start-NTAPPerformance"
}

function Register-NTAPEvents()
{

}

function Initialize-NTAPLogs()
{
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory = $false)]
        $logPath,
        [Parameter(ParameterSetName = 'Name', Mandatory = $false)]
        $logName = "NTAPPerformance_Messages_$('{0:yyyyMMdd}' -f ([datetime]::Now)).log",
        [Parameter(ParameterSetName = 'Name', Mandatory = $true)]
        $ModuleVersion

    )
    try
    {
        New-EventLog -Source NTAPPerformance -LogName Application -MessageResourceFile TestApp.dll -ErrorAction stop
        New-Variable -Name NTAPPerformanceLog -Value "Application" 
    }
    catch
    {
        if(!$logPath){
            $logPath = pwd
        }

        Write-Verbose -Message "The account running this script does not have rights to use the Application log."
        Log-Start -LogPath $logPath -LogName $logName  -ModuleVersion $ModuleVersion
    }
}

Function Log-Start{
  <#
  .SYNOPSIS
    Creates log file


  .DESCRIPTION
    Creates log file with path and name that is passed. Checks if log file exists, and if it does deletes it and creates a new one.
    Once created, writes initial logging data

  .PARAMETER LogPath
    Mandatory. Path of where log is to be created. Example: C:\Windows\Temp

  .PARAMETER LogName
    Mandatory. Name of log file to be created. Example: Test_Script.log

  .PARAMETER ScriptVersion
    Mandatory. Version of the running script which will be written in the log. Example: 1.5

  .NOTES
    Version:        1.0
    Author:         Luca Sturlese
    Creation Date:  10/05/12
    Purpose/Change: Initial function development

    Version:        1.1
    Author:         Luca Sturlese
    Creation Date:  19/05/12
    Purpose/Change: Added debug mode support

  .EXAMPLE

    Log-Start -LogPath "C:\Windows\Temp" -LogName "Test_Script.log" -ScriptVersion "1.5"

  #>
  [CmdletBinding()]

  Param (
  [Parameter(Mandatory=$true)]
  [string]$LogPath
  , 
  [Parameter(Mandatory=$true)]
  [string]$LogName
  , 
  [Parameter(Mandatory=$true)]
  [string]$ModuleVersion
  )
 

  Process{

    $sFullPath = $LogPath + "\" + $LogName
    
    #Check if file exists and delete if it does

    If((Test-Path -Path $sFullPath)){

      Remove-Item -Path $sFullPath -Force

    }
   
    $LocalSystemInfo = [System.Net.DNS]::GetHostByName($null)
    
    #Create file and start logging

    Add-Content -Path $sFullPath -Value "***************************************************************************************************"

    Add-Content -Path $sFullPath -Value "Started processing at [$([DateTime]::Now)]."
    Add-Content -Path $sFullPath -Value "Hostname: $($LocalSystemInfo.HostName)"
    Add-Content -Path $sFullPath -Value "IP: $($LocalSystemInfo | select -first 1 -ExpandProperty AddressList)"
    Add-Content -Path $sFullPath -Value "***************************************************************************************************"

    Add-Content -Path $sFullPath -Value ""

    Add-Content -Path $sFullPath -Value "Running module version [$ModuleVersion]."

    Add-Content -Path $sFullPath -Value ""

    Add-Content -Path $sFullPath -Value "***************************************************************************************************"

    Add-Content -Path $sFullPath -Value "Date Time : Code : Severity : Log Entry"
    if($script:LogPath)
    {
        Remove-Variable -Name LogPath -Scope script
    }
    New-Variable -Name LogPath -Scope script -Value $sFullPath
  }
    
}

Function Log-Write(){
  [CmdletBinding()]
  Param (
  [Parameter(Mandatory=$true)]
  [string]$LineValue
  ,
  [Parameter(Mandatory=$true)]
  [int]$Code
  , 
  [Parameter(Mandatory=$true)]
  [ValidateSet('SUCCESS','INFORMATIONAL','WARNING')]
  [string]$Severity
  )

  Process{
    if($Severity.length -gt 8)
    {
        $tab = ""
    }
    else
    {
        $tab = "`t`t"
    }

    Add-Content -Path $script:LogPath -Value "[$([DateTime]::Now)]: $Code : $Severity$tab : $LineValue"

    #Write to screen for debug mode

    Write-Debug $LineValue

  }

}

Function Log-Error{
  [CmdletBinding()]
  Param ( 
  [Parameter(Mandatory=$true)]
  [string]$ErrorDesc
  , 
  [Parameter(Mandatory=$true)]
  [string]$Code
  , 
  $category
  ,
  [Parameter(Mandatory=$false)]
  [switch]$ExitGracefully
  )
  
  Process{
    if($category){
        Write-Error -ErrorId $Code -Message $ErrorDesc -Category $category
    }
    else{
        Write-Error -ErrorId $Code -Message $ErrorDesc
    }
    Add-Content -Path $script:LogPath -Value "[$([DateTime]::Now)]: $Code : ERROR`t`t : $ErrorDesc"

    if($script:ErrorCode){
        $script:ErrorCode = $Code
    }
    else{
        New-Variable -Name ErrorCode -Value $code -Scope script
    }
    #If $ExitGracefully = True then run Log-Finish and exit script

    If ($ExitGracefully){
      
      Log-Finish

    }

  }

}

Function Log-Finish{
  [CmdletBinding()]

  Param ([Parameter(Mandatory=$false)][string]$NoExit)

  Process{
    
    if(!$script:errorcode)
    {
        $script:errorcode = 0
    }

    Add-Content -Path $script:LogPath -Value ""

    Add-Content -Path $script:LogPath -Value "***************************************************************************************************"

    Add-Content -Path $script:LogPath -Value "Finished processing at [$([DateTime]::Now)]."
    
    Add-Content -Path $script:LogPath -Value "Script Completed with code: $script:ErrorCode"

    Add-Content -Path $script:LogPath -Value "***************************************************************************************************"

    If(!($NoExit) -or ($NoExit -eq $False)){

      Throw "Command Completed"

    }    

  }

}

function Add-NTAPLogEntry()
{

}

function New-NTAPEvent()
{

}

function Get-NTAPEvent()
{

}

function Remove-NTAPEvent()
{

}