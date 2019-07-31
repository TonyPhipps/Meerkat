# Run HAMER with highest rights every hour
# This setup includes creating a secure .ps1 file, then running the below code to create the scheduled task and reference said script file.

$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -File "C:\Scripts\HAMER.ps1"'
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval  (New-TimeSpan -Minutes 60)
$Principal = New-ScheduledTaskPrincipal -UserID "Administrator" -RunLevel Highest
Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName "HAMER Collection" -Description "https://github.com/TonyPhipps/HAMER"


# C:\HAMER.ps1 would contain something like:
# Import-Module D:\Tony\Projects\Github\HAMER\HAMER.psm1 -Force
# Invoke-HAMER -Output C:\HAMER

