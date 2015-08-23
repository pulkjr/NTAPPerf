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
            param($EnvironmentObj)
            $PerformanceArray=@()
            foreach($instance in ($EnvironmentObj.performance.instances | sort -Unique Uuid)){
                $instanceObj = New-Object -TypeName psobject -Property @{Instance=$instance.name;uuid=$instance.uuid;PerfObjects=@()}
                foreach($ObjName in ($EnvironmentObj.performance | ?{$_.instances.uuid -eq $instanceObj.uuid}))
                {
                    $instanceObj.PerfObjects = New-Object -TypeName psobject -Property @{Name=$ObjName.Name;Counters=@()}
                }
                $PerformanceArray += $instanceObj
            }
            
            return $PerformanceArray
        }
        Function New-EnvironmentObject(){
            $EnvironmentObj = New-Object -TypeName PSObject -Property @{Name=$null; Version=$null; Nodes=@();NodeManagementInt=@();AutoSupportConfig=@();ClusterManagementInt=@();Performance=@() }
            $EnvironmentObj.PsObject.TypeNames.Add('NetApp.Performance.Environment')
            return $EnvironmentObj
        }

        Function Get-NTAPEnvironment{
            $EnvironmentObj = New-EnvironmentObject
            $EnvironmentObj.Name = (Get-NcCluster).ClusterName
            $EnvironmentObj.Version = (Get-NcSystemImage | ?{$_.IsCurrent -eq $true} | sort Version | select -first 1).version
            $EnvironmentObj.Nodes = Get-NcNode
            $EnvironmentObj.NodeManagementInt = Get-NcNetInterface -Role node_mgmt
            $EnvironmentObj.AutoSupportConfig = Get-NcAutoSupportConfig
            $EnvironmentObj.ClusterManagementInt = Get-NcNetInterface -Role cluster_mgmt
            if(Test-Path -Path $CounterMetaPath){
                $CounterMeta = Import-Csv -Path $CounterMetaPath
                foreach($ObjName in  (($CounterMeta | select -Unique ObjName).ObjName)){
                    $instances = Get-NcPerfInstance -Name $ObjName
                    if($instances){
                        foreach($Counter in ($CounterMeta | ?{$_.ObjName -eq $ObjName})){
                            $CustomObject = New-Object -TypeName PSObject -Property @{Name=$ObjName; Instances=$instances; Counters=$Counter.name;USE=$Counter.USE;Description=$Counter.Desc;Values=$()}
                            $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Environment.Counters')
                            $EnvironmentObj.Performance += $CustomObject

                        }
                    }
                }
            }
            else{
                Log-Error -ErrorDesc "Counter Meta File Inaccessible. Please ensure $CounterMetaPath is accessible." -Code 308 -category ObjectNotFound -ExitGracefully

            }

            return $EnvironmentObj
        }

        Function Start-NcPerfPull{
            param($EnvironmentObj,$PerformanceArray)

            foreach($ObjName in ($EnvironmentObj.Performance | Select -Unique Name)){
                $PerformanceValues = Get-NcPerfData -Name $ObjName.Name -Instance ($EnvironmentObj.Performance | ?{$_.Name -eq $ObjName.Name} |select -first 1).Instances.name -Counter ($EnvironmentObj.Performance | ?{$_.Name -eq $ObjName.Name}).Counters 
                foreach($performanceValue in $PerformanceValues){
                    
                    ($PerformanceArray | ?{$_.uuid -eq $performanceValue.uuid}).PerfObjects.Counters += $performanceValue.Counters

                }
            }
            
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
        Function New-NTAPCustomer(){
            Function New-NTAPCustomerObject(){
                $CustomObject = New-Object -TypeName PSObject -Property @{SendToSupport="";KnowTheProtocol="";PerceivedLatentProtocol="";Cluster=""}
                $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Customer')
                $CustomObject.Cluster = New-Object -TypeName psobject -Property @{Hostname=$null;IPAddress=$null;Credentials=$null;Connection=$null}

                return $CustomObject
            }

            New-Variable -Name NTAPCustomer -Value (New-NTAPCustomerObject)
            $NTAPCustomer = Get-NTAPCustomerInfo -NTAPCustomer $NTAPCustomer
            return $NTAPCustomer
        }
        function Get-NTAPCustomerInfo(){
            param(
                $NTAPCustomer
            )
            #region - Opening Question
            CLS
            Write-Host "NetApp Clustered Data OnTap Performance Collection Tool"
            Write-Host "This utility is intended for the collection of performance statistics from a Clusterd Data OnTap Controller.`n"
            Write-Host -ForegroundColor green "Step 1 - Progress - Initial User Input: [#---------]"

            $title = "Support"
            $message = "Are you able to send data to support?"

            $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                "Yes, I can send data to support."

            $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                "No, this is a secured environment and I am NOT able or authorized to send data to support."

            $options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

            $NTAPCustomer.SendToSupport = $host.ui.PromptForChoice($title, $message, $options, 1) 

            if($NTAPCustomer.SendToSupport -ne 1)
            {
                Log-Error -ErrorDesc "Utilize PerfStat for collecting data for Support. This functionality will be added in latter release." -Code "20150719.1" -Category "CloseError" -ExitGracefully
            }
            #endregion
            #region - Q1
            CLS
            Write-Host -ForegroundColor green "Progress - Initial User Input: [##--------]"

            $title = "Protocol"
            $message = "Do you know the protocol that is experiencing latency or performance degridation?"

            $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                "I understand the protocol that is experiencing latency (e.g. cifs, nfs, fcp, isci)"

            $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                "I am not sure the protocol causing latency"

            $options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

            $NTAPCustomer.KnowTheProtocol = $host.ui.PromptForChoice($title, $message, $options, 0) 
            #endregion
            #region - Q2
            CLS
            Write-Host -ForegroundColor green "Progress - Initial User Input: [###-------]"
            if($NTAPCustomer.KnowTheProtocol -eq 0)
            {
                $title = "Protocol"
                $message = "What protocol are you experiencing latency?"

                $CIFS = New-Object System.Management.Automation.Host.ChoiceDescription "&CIFS", `
                    "A NAS connection via SMB is experiencing latency. (e.g. User Shares, Hyper-V Datastore...)."

                $NFS = New-Object System.Management.Automation.Host.ChoiceDescription "&NFS", `
                    "A NAS connection via NFS is experiencing latency (e.g. Linux share, VMware Datastore...)"

                $iSCSI = New-Object System.Management.Automation.Host.ChoiceDescription "&iSCSI", `
                    "A SAN connection via iSCSI is experiencing latency (e.g. LUN, Physical Server, Virtual Server ...)"
    
                $FCP = New-Object System.Management.Automation.Host.ChoiceDescription "&FCP", `
                    "A SAN connection via FCP is experiencing latency (e.g. LUN, Physical Server, Virtual Server ...)"
    
                $FCoE = New-Object System.Management.Automation.Host.ChoiceDescription "FCo&E", `
                    "A SAN connection via FCoE is experiencing latency (e.g. LUN, Physical Server, Virtual Server ...)"
    
                $options = [System.Management.Automation.Host.ChoiceDescription[]]($CIFS, $NFS, $iSCSI, $FCP, $FCoE)

                $response = $host.ui.PromptForChoice($title, $message, $options, [int[]](0)) 

                switch ($response)
                    {
                        0 {$NTAPCustomer.PerceivedLatentProtocol = "cifs"}
                        1 {$NTAPCustomer.PerceivedLatentProtocol = "nfs"}
                        2 {$NTAPCustomer.PerceivedLatentProtocol = "iscsi"}
                        3 {$NTAPCustomer.PerceivedLatentProtocol = "fcp"}
                        4 {$NTAPCustomer.PerceivedLatentProtocol = "fcoe"}
                    }
            }
            #endregion

            if($global:CurrentNcController.name){
                #region - Q3
                CLS
                Write-Host -ForegroundColor green "Progress - Initial User Input: [##--------]"

                $title = "System"
                $message = "Is $($global:CurrentNcController.name) the NetApp Cluster where the latent IO is witnessed?"

                $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                    "Yes a device connected to $($global:CurrentNcController.name) is experiencing latency"

                $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                    "No $($global:CurrentNcController.name) is not the system, I would like to specify another system."

                $options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

                $response = $host.ui.PromptForChoice($title, $message, $options, 0) 
                if($response -eq 0)
                {
                    $NTAPCustomer.Cluster.Connection = $global:CurrentNcController
                }
                #endregion
            }
            if(!$NTAPCustomer.Cluster.Connection){
                $HostnameQuestion = new-object "System.Collections.ObjectModel.Collection``1[[System.Management.Automation.Host.FieldDescription]]"

                $f = New-Object System.Management.Automation.Host.FieldDescription "Hostname"
                $f.SetparameterType( [String] )
                $f.HelpMessage  = "Type the hostname of the cluster management port. If it is not known leave blank and use the next prompt for IP address."
                $f.Label = "&Hostname"
                $HostnameQuestion.Add($f)

                $CredentialQuestion = new-object "System.Collections.ObjectModel.Collection``1[[System.Management.Automation.Host.FieldDescription]]"

                $f = New-Object System.Management.Automation.Host.FieldDescription "Credentials"
                $f.SetparameterType( [System.Management.Automation.PSCredential] )
                $f.HelpMessage  = "Type the credentials for an account with readonly rights to the clusters. This is to pull support and statistical information"
                $f.Label = "&Credentials"
                $CredentialQuestion.Add($f)

                $IPQuestion = new-object "System.Collections.ObjectModel.Collection``1[[System.Management.Automation.Host.FieldDescription]]"

                $f = New-Object System.Management.Automation.Host.FieldDescription "IPAddress"
                $f.SetparameterType( [System.Net.IPAddress] )
                $f.HelpMessage  = "The IP address of the Cluster management port. If it is not known ensure the previous hostname is used."
                $f.Label = "&IPAddress"
                $IPQuestion.Add($f)
                do
                {
            
                    CLS
                    if((!$NTAPCustomer.Cluster.Hostname -and !$NTAPCustomer.Cluster.IPAddress) -and $ranOnce -eq 1)
                    {
                        Write-Host -ForegroundColor red "Please specify an IP Address or a Hostname to continue"
                    }
                    $ranOnce = 1
                    Write-Host -ForegroundColor green "Progress - Initial User Input Discovery: [#######---]"
                    $Hostname = $Host.UI.Prompt( "NetApp Cluster Information", "Type the cluster information so the script can connect to it and pull support and statistic information.", $HostnameQuestion )

                    if($Hostname.Hostname)
                    {
                        Write-Verbose "Hostname Specified"
                        try
                        {
                            $IPAddress = [System.Net.DNS]::GetHostAddresses($Hostname.Hostname) | select -First 1 -ErrorAction SilentlyContinue
                        }
                        catch
                        {
                            Log-Error -Code 301 -ErrorDesc "Unable to Resolve IP Address for hostname: $($Hostname.Hostname)"
                            $IPAddress = $null
                        }
                        if($Hostname.Hostname)
                        {
                            $NTAPCustomer.Cluster.Hostname = $($Hostname.Hostname)
                        }
                        if($IPAddress)
                        {
                            $NTAPCustomer.Cluster.IPAddress = $IPAddress
                        }
                    }

                    if(!$NTAPCustomer.Cluster.IPAddress){
                        $IPAddress = $Host.UI.Prompt( "NetApp Cluster Information", "Type the cluster information so the script can connect to it and pull support and statistic information.", $IPQuestion )
                        if(-not (Test-Connection ($IPAddress.IPAddress) -Count 2 -Quiet)){
                            Log-Error -Code 302 -ErrorDesc "Unable to Ping IP Address: $($IPAddress.IPAddress)"
                            $NTAPCustomer.Cluster.IPAddress = $null
                        }
                        else{
                            $NTAPCustomer.Cluster.IPAddress = $($IPAddress.IPAddress)
                            $NTAPCustomer.Cluster.IPAddress
                        }
                    }

                    if(!$NTAPCustomer.Cluster.Credentials){
                        $cred = $Host.UI.Prompt( "NetApp Cluster Information", "Type the cluster information so the script can connect to it and pull support and statistic information.", $CredentialQuestion )
                        $NTAPCustomer.Cluster.Credentials = $cred.Credentials

                    }
                }While(!$NTAPCustomer.Cluster.IPAddress -and !$NTAPCustomer.Cluster.Credentials)
        
                if(!$NTAPCustomer.Cluster.Connection){
                    Log-Write -LineValue "No Connection to Cluster Present, Attempting to Connect to: $($NTAPCustomer.Cluster.IPAddress)" -Code 106 -Severity INFORMATIONAL
                    if($NTAPCustomer.Cluster.IPAddress){
                        $NTAPCustomer.Cluster.Connection = Connect-NcController ($NTAPCustomer.Cluster.IPAddress) -Credential ($NTAPCustomer.Cluster.Credentials)
                        if($NTAPCustomer.Cluster.Connection.name -eq $NTAPCustomer.Cluster.IPAddress){
                            Log-Write -LineValue "Connection to cluster $($NTAPCustomer.Cluster.IPAddress) Successful" -Code 107 -Severity INFORMATIONAL
                        }
                    }
                    else{
                        Log-Error -Code 303 -ErrorDesc "IP Adress still not specified. Please run the Start-NTAPPerformance command again." -ExitGracefully
                    }

                }

            }

            return $NTAPCustomer


        }
    }
    Process{
        $ModuleVersion = (Get-Module NTAPPerformance).Version
    
        Initialize-NTAPLogs -ModuleVersion $ModuleVersion -logPath $LogPath

        if(!$NTAPCustomer)
        {
            Write-Verbose "Missing Customer Data"
            $NTAPCustomer = New-NTAPCustomer
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




