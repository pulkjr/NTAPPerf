#NTAPPerformance.psm1
Function New-PeformanceObject()
{
    $CustomObject = New-Object -TypeName PSObject -Property @{Name=""; Version=""; }
    $CustomObject.PsObject.TypeNames.Add('NetApp.Performance.Data')
    return $CustomObject
}

Function Start-NTAPPerformance()
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
    )
    $ModuleVersion = (Get-Module NTAPPerformance).Version
    Initialize-NTAPLogs -ModuleVersion $ModuleVersion

    if(!$NTAPCustomer)
    {
        Write-Verbose "Missing Customer Data"
        $NTAPCustomer = New-NTAPCustomer
    }
    
    
}

Function Stop-NTAPPerformance()
{

}

