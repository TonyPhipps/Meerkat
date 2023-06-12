# Run Meerkat with highest rights every hour
# Edit the parameters here and for the example Meerkat-Task.ps1, then save the Meerkat-Task.ps1 somewhere acessible by the serivce.

$MSAName = "svcMSA-Meerkat"
$Server = "ServerName"
$ScriptName = "C:\Meerkat-Task.ps1"
$AtTime = "1/30/2023 2:00:00 AM"

$Action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-ExecutionPolicy Bypass -Windowstyle Hidden -File `"$ScriptName`""
$Trigger = New-ScheduledTaskTrigger -Once -At $AtTime -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval (New-TimeSpan -Minutes 60)
$Principal = New-ScheduledTaskPrincipal -UserId ($MSAName + "$") -RunLevel Highest -LogonType Password

Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName "Meerkat Collection" -Description "https://github.com/TonyPhipps/Meerkat"

<#
Meerkat-Task.ps1 would contain something like:

    #Set-ExecutionPolicy -ExecutionPolicy Bypass
    Import-Module "C:\Program Files\WindowsPowerShell\Modules\Meerkat\Meerkat.psm1" -Force
    $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd")
    Invoke-Meerkat -Output "D:\Logs\Meerkat\$DateScanned"

    # Get target computers from AD, filtering on Enabled objects
    #Get-ADComputer -Filter {Enabled -eq $true} | Select-Object Name -ExpandProperty Name | Invoke-REC -Output "D:\Logs\Meerkat\$DateScanned"

    # Get target computers from a curated list stored in a file with one computer name per line.
    #Get-Item "c:\hosts.txt" | Invoke-Meerkat -Output "D:\Logs\Meerkat\$DateScanned"

    # Purge files older than 30d
    #Get-ChildItem -Path "D:\Logs\Meerkat\" -Recurse | where {$_.LastWriteTime -le $(Get-Date).AddDays(-30)} | Remove-Item -Recurse -Force
--#>
