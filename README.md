# HAMER

-Hunter's Artifact, Metadata, and Events Recon-

A collection of PowerShell modules designed for artifact gathering and reconnaisance of Windows-based endpoints. Use cases include incident response triage, threat hunting, baseline monitoring, snapshot comparisons, and more.

|       [Host Info](https://github.com/TonyPhipps/HAMER/wiki/Computer)       | [Processes](https://github.com/TonyPhipps/HAMER/wiki/Processes)* |      [Services](https://github.com/TonyPhipps/HAMER/wiki/Services)      | [Autoruns](https://github.com/TonyPhipps/HAMER/wiki/Autoruns) |      [Drivers](https://github.com/TonyPhipps/HAMER/wiki/Drivers)      |
| :--------------------------------------------------------------------------: | :----------------------------------------------------------------: | :-----------------------------------------------------------------------: | :-------------------------------------------------------------: | :---------------------------------------------------------------------: |
|                                     ARP                                      |      [DLLs](https://github.com/TonyPhipps/HAMER/wiki/DLLs)*      |                                  EnvVars                                  |                           Hosts File                            |                                   ADS                                   |
|            [DNS](https://github.com/TonyPhipps/HAMER/wiki/DNS)             |                              Strings*                              | [Users & Groups](https://github.com/TonyPhipps/HAMER/wiki/GroupMembers) |    [Ports](https://github.com/TonyPhipps/HAMER/wiki/Ports)    | [Select Registry](https://github.com/TonyPhipps/HAMER/wiki/Registry)  |
|                                   Hotfixes                                   |                              Handles*                              |                                  Sofware                                  |                            Hardware                             |   [Event Logs](https://github.com/TonyPhipps/HAMER/wiki/EventLogs)    |
|                                 Net Adapters                                 |                             Net Routes                             |                                 Sessions                                  |                             Shares                              | [Certificates](https://github.com/TonyPhipps/HAMER/wiki/Certificates) |
| [Scheduled Tasks](https://github.com/TonyPhipps/HAMER/wiki/ScheduledTasks) |                                TPM                                 |                                 Bitlocker                                 |                           Recycle Bin                           |                               User Files                                |


* Ingest using your SIEM of choice (_Check out the [SIEM](https://github.com/TonyPhipps/SIEM) Repository!_)
______________________________________________________

## Index

  * [Quick Start](#Quick-Start)
  * [Usage](#Usage)
  * [Analysis](#Analysis)
  * [Troubleshooting](#Troubleshooting)
  * [Screenshots](#Screenshots)
  * [Similar Projects](#Similar-Projects)
  
______________________________________________________

## Quick Start

### Requirements

* Requires Powershell 5.0 or above on the "scanning" device.
* Requires Powershell 3.0 or higher on target systems. You can make this further backward compatible to PowerShell 2.0 by replacing instances of "Get-CIMinstance" with "Get-WMIObject"
* Requires [WinRM access](https://github.com/TonyPhipps/Powershell/blob/master/Enable-WinRM.ps1).

### Install with [Git](https://gitforwindows.org/)

In a Command or PowerShell console, type the following...

```
git clone https://github.com/TonyPhipps/HAMER C:\Program Files\WindowsPowerShell\Modules\HAMER
```

To update...

```
cd C:\Program Files\WindowsPowerShell\Modules\HAMER
git pull
```

### Install with PowerShell

Copy/paste this into a PowerShell console

```
$Modules = "C:\Program Files\WindowsPowerShell\Modules\"
New-Item -ItemType Directory $Modules\HAMER\ -force
Invoke-WebRequest https://github.com/TonyPhipps/HAMER/archive/master.zip -OutFile $Modules\master.zip
Expand-Archive $Modules\master.zip -DestinationPath $Modules
Copy-Item $Modules\HAMER-master\* $Modules\HAMER\ -Force -Recurse
Remove-Item  $Modules\HAMER-master -Recurse -Force
```

To update, simply run the same block of commands again.

Functions can also be used by opening the .psm1 file and copy-pasting its entire contents into a PowerSell console.

## Run HAMER

This command will output results to C:\Users\YourName\HAMER\

```
Invoke-HAMER
```

## Analysis

Analysis methodologies and techniques are provided in the [Wiki pages](https://github.com/TonyPhipps/HAMER/wiki).

## Troubleshooting
[Installing a Powershell Module](https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx)

If your system does not automatically load modules in your user [profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-6), you may need to [import the module manually](https://msdn.microsoft.com/en-us/library/dd878284(v=vs.85).aspx).

```
Import-Module C:\Program Files\WindowsPowerShell\Modules\HAMER\HAMER.psm1
```

## Screenshots

Output of Command "Invoke-HAMER"

![Output of Command "Invoke-HAMER"](https://i.imgur.com/gcM2y17.png)

Output Files

![Output Files](https://i.imgur.com/3B4HtXb.png)


## Similar Projects

- https://github.com/Invoke-IR/PowerForensics
- https://github.com/PowerShellMafia/CimSweep
- https://www.crowdstrike.com/resources/community-tools/crowdresponse/
- https://github.com/gfoss/PSRecon/
- https://github.com/n3l5/irCRpull
- https://github.com/davehull/Kansa/
- https://github.com/WiredPulse/PoSh-R2
- https://github.com/google/grr
- https://github.com/diogo-fernan/ir-rescue
- https://github.com/SekoiaLab/Fastir_Collector
- https://github.com/AlmCo/Panorama
- https://github.com/certsocietegenerale/FIR
- https://github.com/securycore/Get-Baseline
- https://github.com/Infocyte/PSHunt
- https://github.com/giMini/NOAH
- https://github.com/A-mIn3/WINspect
- https://learn.duffandphelps.com/kape
- https://www.brimorlabs.com/tools/

What makes HAMER stand out?
- Lightweight. Fits on a floppy disk!
- Very little footprint/impact on targets.
- Leverages Powershell & WMI/CIM.
- Coding style encourages proper code review, learning, and "borrowing."
- No DLLs or compiled components.
- Standardized output - defaults to .csv, and can easily support json, xml, etc.