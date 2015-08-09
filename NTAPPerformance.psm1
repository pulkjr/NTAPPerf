#NTAPPerformance.psm1
Function Start-NTAPPerformance(){
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
        : 20150719.1 - Collection of data to send to support errors stating missing functionality.
        REQUESTED FUNCTIONALITY FOR FUTURE RELEASES
        - Perfstat Collection
        - CMPG Setup and Collection
    #>
    
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [OutputType([System.Management.Automation.PSObject])]
    param (
        [Parameter(ParameterSetName = 'Name', Mandatory = $false, Position = 0, ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'The name(s) of the system to gather the data from.')]
        [ValidateNotNullOrEmpty()]
        [Alias('ClusterName')]
        [Alias('SystemName')]
        [string[]]$Name
        ,
        [Parameter(ParameterSetName = 'Name', Mandatory = $false, Position = 1, HelpMessage = 'This is the path to the directory for the Log files.')]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo]$LogPath
        ,
        [Parameter(ParameterSetName = 'Name', Mandatory = $false, Position = 1, HelpMessage = 'This is the path to the Counter Definition File.')]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$CounterMetaPath = (Get-Module NTAPPerformance).ModuleBase + "\Resources\CounterMeta.csv"
    )
    Begin{
        Function New-PeformanceObject(){
            $PerformanceArray=@()
            if(Test-Path -Path $CounterMetaPath){
                $CounterMeta = Import-Csv -Path $CounterMetaPath
                foreach($ObjName in  (($CounterMeta | select -Unique ObjName).ObjName)){
                    $instances = Get-NcPerfInstance -Name $ObjName
                    if($instances){
                        foreach($Counter in ($CounterMeta | ?{$_.ObjName -eq $ObjName})){
                            $CustomObject = New-Object -TypeName PSObject -Property @{Name=$ObjName; Instances=$instances; Counters=$Counter.name;USE=$Counter.USE;Description=$Counter.Desc;Values=$()}
                            $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Data')
                            $PerformanceArray += $CustomObject

                        }
                    }
                }
            }
            else{
                Log-Error -ErrorDesc "Counter Meta File Inaccessible. Please ensure $CounterMetaPath is accessible." -Code 308 -category ObjectNotFound -ExitGracefully

            }
            return $PerformanceArray
        }
        Function Start-NcPerfPull{
            param($PerformanceArray)

            foreach($ObjName in ($PerformanceArray | Select -Unique Name)){
                $Perf = Get-NcPerfData -Name $ObjName.Name -Instance ($PerformanceArray | ?{$_.Name -eq $ObjName.Name}).Instances.name -Counter ($PerformanceArray | ?{$_.Name -eq $ObjName.Name}).Counters 
            }
            
        }
    }
    Process{
        $ModuleVersion = (Get-Module NTAPPerformance).Version
        Initialize-NTAPLogs -ModuleVersion $ModuleVersion -logPath $LogPath

        if(!$NTAPCustomer)
        {
            Write-Verbose "Missing Customer Data"
            $NTAPCustomer = New-PeformanceObject
        }
        if($NTAPCustomer)
        {
            Write-Host -ForegroundColor green "Step 2 - Polling Cluster Performance using USE Model: [#---------]"
            $PerformanceArray = New-PeformanceObject
            if($PerformanceArray){

            }
            Else{
                Log-Error -ErrorDesc "The Array of Performance Counters is missing or there are not valid instances." -Code 309 -Category ObjectNotFound -ExitGracefully
            }
        }
        else{
            Log-Error -ErrorDesc "Customer Object Missing. Please run the Command Again" -Code 307 -Category ObjectNotFound -ExitGracefully
        }
    
    }
}

Function Stop-NTAPPerformance(){

}

Function Get-NcAutosupportPerf(){
    [CmdletBinding(DefaultParameterSetName="Auto", SupportsShouldProcess=$false, ConfirmImpact='low')]
    PARAM(
    [parameter(ParameterSetName="Auto", Mandatory=$True)]
    [System.IO.FileInfo]$XML
    ,
    [System.IO.FileInfo]$XSL
    ,
    [System.IO.FileInfo]$DestinationPath =  "C:\scripts\clusterinfo.xml"
    ,
    [String[]]$Controllers
    ,
    [Parameter(ParameterSetName='Auto', Mandatory=$false, HelpMessage='Credentials for connecting to the system via SPI web interface.')]
    [Alias('Cred')]
    [System.Management.Automation.PSCredential]$Credential
    )
    if(!$Controllers)
    {
        if(!$global:CurrentNcController)
        {
            throw "This commandlet must either have a controller specified or be connected to a cluster."
        }
        else
        {
            $ManagementInterfaces = Get-NcNetInterface -Role node_mgmt
        }
    }
    else
    {
        $ManagementInterfaces = Get-NcNetInterface -Role node_mgmt -vserver $Controllers
    }
    if(!$ManagementInterfaces)
    {
        throw "No Management interfaces were found. Configure the nodes with interfaces that have the role node_mgmt."
    }
    $Yesterday = ((get-date).AddDays(-1))
    $PerformanceASUP = Get-NcAutoSupportHistory -Trigger callhome.performance.data -Destination http | ?{$_.LastModificationTimestampDT -gt $Yesterday}

    $Yesterday = ((get-date).AddDays(-1)).ToString("yyyyMMdd")
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    foreach($ManagementInterface in $ManagementInterfaces)
    {
        if($PerformanceASUP.NodeName -contains $ManagementInterface.Vserver)
        {
        $url = "https://$($ManagementInterface.Address)/spi/$($ManagementInterface.Vserver)/etc/log/autosupport/"
        $website = Invoke-WebRequest -UseBasicParsing -Uri "https://$($ManagementInterface.Address)/spi/$($ManagementInterface.Vserver)/etc/log/autosupport/" -Credential $cred
        $PerfLink = ($website.Links | ?{$_.HREF -match $yesterday -and $_.HREF -match "1\.0\.files"}).HREF
        $url = $url + $PerfLink + "CLUSTER-INFO.xml"
        $browser = New-Object System.Net.WebClient
        $browser.Credentials = $Credential
        $url
    
        #$browser.DownloadFile($url, $DestinationPath)
        }
    }
    [net.servicepointmanager]::ServerCertificateValidationCallback = $null
    [xml]$zapi = "<perf-archive-get-oldest-timestamp/>"
    $result = Invoke-NcSystemApi -RequestXML $zapi

    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xslt.Load($xsl)

    try
    {
        $xslt.Transform($xml,$ouput)
        if(Test-Path $ouput)
        {
            Write-Host -ForegroundColor Green "The Transformation was successful"
        }
    }
    catch
    {
    
    }
}


