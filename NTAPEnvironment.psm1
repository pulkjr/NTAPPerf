Function New-EnvironmentObject(){
    $CustomObject = New-Object -TypeName PSObject -Property @{Name=$null; Version=$null; Nodes=@() }
    $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Data')
    return $CustomObject
}

Function Get-NTAPEnvironment{
    $Environment = New-EnvironmentObject
    $Environment.Name = (Get-NcCluster).ClusterName
    $Environment.Version = (Get-NcSystemImage | ?{$_.IsCurrent -eq $true} | sort Version | select -first 1).version
    $Environment.Nodes = Get-NcNode
}