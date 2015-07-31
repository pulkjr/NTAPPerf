Function New-NTAPCustomerObject(){
    $CustomObject = New-Object -TypeName PSObject -Property @{SendToSupport="";KnowTheProtocol="";PerceivedLatentProtocol="";Cluster=""}
    $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Customer')
    $CustomObject.Cluster = New-Object -TypeName psobject -Property @{Hostname=$null;IPAddress=$null;Credentials=$null;Connection=$null}

    return $CustomObject
}

function New-NTAPCustomer(){
    New-Variable -Name NTAPCustomer -Value (New-NTAPCustomerObject)
    Get-NTAPCustomerInfo -NTAPCustomer $NTAPCustomer
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
    $message = "Are you able to send data to support or is this a secured environment?"

    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Yes this is a secured environment and I am can NOT send data to support."

    $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "No, I CAN send data to support."

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
                Write-host "Hostname Specified"
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

            if(!$NTAPCustomer.Cluster.IPAddress)
            {
                $IPAddress = $Host.UI.Prompt( "NetApp Cluster Information", "Type the cluster information so the script can connect to it and pull support and statistic information.", $IPQuestion )
                if(-not (Test-Connection ($IPAddress.IPAddress) -Count 2 -Quiet))
                {
                    Log-Error -Code 302 -ErrorDesc "Unable to Ping IP Address: $($IPAddress.IPAddress)"
                    $NTAPCustomer.Cluster.IPAddress = $null
                }
                else
                {
                    $NTAPCustomer.Cluster.IPAddress = $($IPAddress.IPAddress)
                    $NTAPCustomer.Cluster.IPAddress
                }
            }

            if(!$NTAPCustomer.Cluster.Credentials)
            {
                $cred = $Host.UI.Prompt( "NetApp Cluster Information", "Type the cluster information so the script can connect to it and pull support and statistic information.", $CredentialQuestion )
                $NTAPCustomer.Cluster.Credentials = $cred.Credentials

            }
        }While(!$NTAPCustomer.Cluster.IPAddress -and !$NTAPCustomer.Cluster.Credentials)
        

    }

    Write-Host -ForegroundColor green "Step 2 - Polling Cluster Performance using USE Model: [#---------]"

}