# Executing this script will create a Scheduled Task that runs another .ps1 using an MSA account and highest runlevel daily.
# Tweak the following as needed BEFORE execution:
# The contents of the sample Meerkat-Daily-Task.ps1 to ensure proper arguments are used.
#   Edit $MSAName to define which name should be used for the managed service account.
#   Edit $Server to define Which server will be running the service.
#   Edit $ScriptName to point to the full path to the .ps1 script.
#   Edit $AtTime to specify when the schedule should start.
# Verify Task runs by Right Clicking > Run in Task Sscheduler Library
# Ensure the new account has local admin rights on all target systems (usually via GPO).
# Review the results in the Windows Task Scheduler, History tab

$MSAName = "svcMSA-Name"
$Server = "ServerName"
$ScriptName = "C:\Program Files\WindowsPowerShell\Modules\Meerkat\Utilities\Meerkat-Daily-Task.ps1"
$AtTime = "1/30/2023 2:00:00 AM"

# Create the MSA
$Identity = Get-ADComputer -identity $Server
try {
    Get-ADServiceAccount -Identity $MSAName
    $MSAExists = $true
}
catch {
    $MSAExists = $false
}

try {
    Test-ADServiceAccount -Identity $MSAName
    $MSAInstalled = $true
}
catch {
    $MSAInstalled = $false
}

if(-not $MSAExists) {
    Add-WindowsFeature RSAT-AD-PowerShell
    Import-Module ActiveDirectory
    
    $KDSKeys = Get-KdsRootKey

    if ($null -ne $KDSKeys -and $KDSKeys.Count -gt 0 ) {
        Write-Information -InformationAction Continue -MessageData ("'{0}' KDS Root Key(s) exists already, skipping KdsRootKey creation." -f $KDSKeyCount)
    }
    elseif ($null -eq $KDSKeys) {
        Write-Information -InformationAction Continue -MessageData ("Permissions not available. Skipping KdsRootKey creation." -f $KDSKeyCount)
    }
    else {
        Write-Information -InformationAction Continue -MessageData ("No KDS Root Key found. Creating KdsRootKey")
        Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))
    }

    New-ADServiceAccount -Name $MSAName -Enabled $true -RestrictToSingleComputer -KerberosEncryptionType AES256
} 
else { 
    Write-Information -InformationAction Continue -MessageData ("MSA '{0}' is exists and is installed already, skipping creation." -f $MSAName)
}

if(-not $MSAInstalled) {
    Add-ADComputerServiceAccount -Identity $Identity -ServiceAccount $MSAName
    Install-ADServiceAccount -Identity ($MSAName + "$")
}

$HostServiceAccountBL = (Get-ADServiceAccount $MSAName -Properties msDS-HostServiceAccountBL) | Select-Object msDS-HostServiceAccountBL -ExpandProperty msDS-HostServiceAccountBL

Write-Information -InformationAction Continue -MessageData ("`n Computer accounts with access to {0}:`n `t{1}`n" -f $MSAName, $HostServiceAccountBL)

# Create the Scheduled Task

$Action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-ExecutionPolicy Bypass -Windowstyle Hidden -File `"$ScriptName`""
$Trigger = New-ScheduledTaskTrigger -Daily -At $AtTime
$Settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit "23:55:00"
$Principal = New-ScheduledTaskPrincipal -UserId ($MSAName + "$") -RunLevel Highest -LogonType Password

Register-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -TaskName "Meerkat Daily Collection" -Description "https://github.com/TonyPhipps/Meerkat"
