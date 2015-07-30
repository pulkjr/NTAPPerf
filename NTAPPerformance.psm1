#NTAPPerformance.psm1
Function New-NTAPData()
{
    $CustomObject = New-Object -TypeName PSObject -Property @{Name=""; Version=""; }
    $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Data')
    return $CustomObject
}

Function New-CustomerInfo()
{
    $CustomObject = New-Object -TypeName PSObject -Property @{Name=""; Reference=""; ConditionSets=@()}
    $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Customer')
    return $CustomObject
}

Export-ModuleMember -Function test