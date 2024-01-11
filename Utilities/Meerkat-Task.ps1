<# The MSA will need permission to run as a service and as a batch job on the system performing the scan.
  - Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment
    - Log on as a batch job
    - Log on as a service
The MSA will need local admin privileges on all target sytems.
WinRM will need to be enabled on all target systems. This can be done via GPO
  - https://troubleshootingsql.com/2014/11/17/gotcha-executing-powershell-scripts-using-scheduled-tasks/
#>


Set-ExecutionPolicy -ExecutionPolicy Bypass
$DailyInputFile = "c:\hosts.txt"
$DailyModules = "AuditPolicy", "Autoruns", "BitLocker", "ComputerDetails", "Disks", "DomainInfo", "Drivers", "EventLogsMetadata", "Hardware", "Hotfixes", "NetAdapters", "RecycleBin", "Registry", "RegistryMRU"
$DailyOutput = "c:\Meerkat-Output"

$DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd")
Import-Module "C:\Program Files\WindowsPowerShell\Modules\Meerkat\Meerkat.psm1" -Force

# OPTION 1 (Local Scan)
#Invoke-Meerkat -Service -Modules $DailyModules -Output "$DailyOutput\$DateScanned"

# OPTION 2 (Remote Scan directly against Active Directory computer objects. Limited modules are included, assuming an hourly task collects the remaining modules.)
#Get-ADComputer -Filter {Enabled -eq $true} | Select-Object Name -ExpandProperty Name | Invoke-Meerkat -Service -Modules $DailyModules -Output "$DailyOutput\$DateScanned"

# OPTION 3 (Remote Scan hosts found in a .txt file)
#Get-Content $DailyInputFile | Invoke-Meerkat -Service -Modules $DailyModules -Output "$DailyOutput\$DateScanned"

# Purge files older than 30d
Get-ChildItem -Path "$DailyOutput\" -Recurse | Where-Object {$_.LastWriteTime -le $(Get-Date).AddDays(-30)} | Remove-Item -Recurse -Force
