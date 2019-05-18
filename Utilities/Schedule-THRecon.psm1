# Run THRecon with highest rights every hour
# This setup includes creating a secure .ps1 file, then running the below code to create the scheduled task and reference said script file.

$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -File "C:\Scripts\THRecon.ps1"'
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval  (New-TimeSpan -Minutes 60)
$Principal = New-ScheduledTaskPrincipal -UserID "Administrator" -RunLevel Highest
Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName "THRecon Collection" -Description "https://github.com/TonyPhipps/THRecon"


# C:\THRecon.ps1 would contain something like:
# Import-Module D:\Tony\Projects\Github\THRecon\THRecon.psm1 -Force
# Invoke-THR -Output C:\THRecon

