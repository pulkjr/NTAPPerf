Function New-EnvironmentObject()
{
    $CustomObject = New-Object -TypeName PSObject -Property @{Name=""; Version=""; }
    $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Data')
    return $CustomObject
}