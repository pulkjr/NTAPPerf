function Get-NTAPPerfErrors{
    function New-NTAPPerfError{
        param(
            $ID,$Name,$Definition
        )
        $NTAPPerfErrorObj = New-Object -TypeName Psobject -Property @{ID=$ID;Name=$Name;Definition=$Definition}

    }
    $NTAPPerfErrors = @()
    $NTAPPerfErrors += New-NTAPPerfError -ID 301 -Name ResolveHostName -Definition "Unable to Resolve IP Address for hostname"
    $NTAPPerfErrors += New-NTAPPerfError -ID 302 -Name InaccessibleIP -Definition "Unable to Ping IP Address"
    $NTAPPerfErrors += New-NTAPPerfError -ID 303 -Name IPVariableMissing -Definition "IP Adress still not specified. Please run the Start-NTAPPerformance command again."
}
