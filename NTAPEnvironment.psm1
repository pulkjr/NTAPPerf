Function New-EnvironmentObject(){
    $CustomObject = New-Object -TypeName PSObject -Property @{Name=$null; Version=$null; Nodes=@();NodeManagementInt=@();AutoSupportConfig=@();ClusterManagementInt=@() }
    $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Environment.Info')
    return $CustomObject
}

Function Get-NTAPEnvironment{
    $Environment = New-EnvironmentObject
    $Environment.Name = (Get-NcCluster).ClusterName
    $Environment.Version = (Get-NcSystemImage | ?{$_.IsCurrent -eq $true} | sort Version | select -first 1).version
    $Environment.Nodes = Get-NcNode
    $Environment.NodeManagementInt = Get-NcNetInterface -Role node_mgmt
    $Environment.AutoSupportConfig = Get-NcAutoSupportConfig
    $Environment.ClusterManagementInt = Get-NcNetInterface -Role cluster_mgmt
    return $Environment
}