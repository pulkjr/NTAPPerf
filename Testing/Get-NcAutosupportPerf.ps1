    [CmdletBinding(DefaultParameterSetName="Auto", SupportsShouldProcess=$false, ConfirmImpact='low')]
    PARAM(
    [parameter(ParameterSetName="Auto", Mandatory=$false)]
    [System.IO.FileInfo]$XML
    ,
    [System.IO.FileInfo]$XSL
    ,
    [System.IO.FileInfo]$DestinationPath =  "C:\scripts\clusterinfo.xml"
    ,
    [parameter(ParameterSetName="Auto", Mandatory=$true)]
    $Environment
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
            Log-Error -ErrorDesc "This commandlet must either have a controller specified or be connected to a cluster." -Code 305 -Category ConnectionError -ExitGracefully
        }
        else
        {
            Write-Verbose "Pulling Node Management interface."
            $ManagementInterfaces = $Environment.NodeManagementInt
        }
    }
    else
    {
        $ManagementInterfaces = $Environment.NodeManagementInt | ?{$_.vserver -match $Controllers} #Need to test
    }
    if(!$ManagementInterfaces)
    {
        Log-Error -ErrorDesc "No Management interfaces were found. Configure the nodes with interfaces that have the role node_mgmt." -Code 306 -Category NotImplemented
    }
    $Yesterday = ((get-date).AddDays(-1))
    $PerformanceASUP = Get-NcAutoSupportHistory -Trigger callhome.performance.data -Destination http | ?{$_.LastModificationTimestampDT -gt $Yesterday}
    if(!$PerformanceASUP){
        Log-Error -ErrorDesc "No Performance ASUP's were found on the cluster for the specified time period." -Code 304 -Category ObjectNotFound
        $title = "Missing Performance ASUP"
        $message = "There is a Missing Performance ASUP. Would you like to generate one?"

        $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
            "I would like to invoke a new Autosupport on the system that is missing one."

        $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
            "No I would like to use the statistics command to pull live stats from the Cluster. This will drastically change the time to run."

        $options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

        $PerformanceASUPResponse = $host.ui.PromptForChoice($title, $message, $options, 0) 
        if($PerformanceASUPResponse -eq 0){

        }
        else{
            Log-Write -LineValue "User Opted to use realtime Statistics instead of past CM Stats." -Code 101 -Severity INFORMATIONAL
        }

    }
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