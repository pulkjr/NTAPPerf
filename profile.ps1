function prompt(){"ps >"}

Import-Module Dataontap
Import-Module "\\vmware-host\Shared Folders\NTAPPerf\NTAPPerf\NTAPPerformance.psd1"

cd "\\vmware-host\Shared Folders\NTAPPerf\NTAPPerf\"

function global:prompt{
    "PS > "
    $host.UI.RawUI.WindowTitle = "NTAPPerf $(pwd)"
}