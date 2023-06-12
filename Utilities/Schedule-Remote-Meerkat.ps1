# Executing this script will create a Scheduled Task that runs another .ps1 using an MSA account and highest runlevel every hour.
# Tweak the following as needed BEFORE execution:
# The contents of the sample Meerkat-Task.ps1 to ensure proper arguments are used.
# Edit MSAName to define which name should be used for the managed service account.
# Edit $Server to define Which server will be running the service.
# Edit $ScriptName to point to the full path to the .ps1 script.
# Edit $AtTime to specify when the schedule should start.
# The Repetition Duration and Repetition Interval, both defined within $Trigger
# Verify Task runs by Right Clicking > Run in Task Sscheduler Library
# Ensure the new account has local admin rights on all target systems. 
# Review the results in the Windows Task Scheduler


$MSAName = "svcMSA-Meerkat"
$Server = "ServerName"
$ScriptName = "C:\Meerkat-Task.ps1"
$AtTime = "1/30/2023 1:01:00 AM"

# Create the MSA
Add-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDirectory
Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))

$Identity = Get-ADComputer -identity $Server
New-ADServiceAccount -Name $MSAName -Enabled $true -RestrictToSingleComputer -KerberosEncryptionType AES256
Add-ADComputerServiceAccount -Identity $Identity -ServiceAccount $MSAName

Install-ADServiceAccount -Identity ($MSAName + "$")

# Create the Scheduled Task

$Action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-ExecutionPolicy Bypass -Windowstyle Hidden -File `"$ScriptName`""
$Trigger = New-ScheduledTaskTrigger -Once -At $AtTime -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval  (New-TimeSpan -Minutes 60)
$Principal = New-ScheduledTaskPrincipal -UserId ($MSAName + "$") -RunLevel Highest -LogonType Password

Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName "Meerkat Remote Collection" -Description "https://github.com/TonyPhipps/Meerkat/"
