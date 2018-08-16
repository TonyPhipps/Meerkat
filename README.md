# THRecon
-Threat Hunting Reconnaissance Toolkit-

Collect endpoint information for use in incident response, threat hunting, live forensics, baseline monitoring, etc.

| [Host Info](https://github.com/TonyPhipps/THRecon/wiki/Computer) | [Processes](https://github.com/TonyPhipps/THRecon/wiki/Processes)* | [Services](https://github.com/TonyPhipps/THRecon/wiki/Services) | [Autoruns](https://github.com/TonyPhipps/THRecon/wiki/Autoruns) | [Drivers](https://github.com/TonyPhipps/THRecon/wiki/Drivers) |
| :---: | :---: | :---: | :---: | :---: |
| ARP | [DLLs](https://github.com/TonyPhipps/THRecon/wiki/DLLs)* | EnvVars | Hosts File | ADS |
| [DNS](https://github.com/TonyPhipps/THRecon/wiki/DNS) | Strings* | [Users & Groups](https://github.com/TonyPhipps/THRecon/wiki/GroupMembers) | [Ports](https://github.com/TonyPhipps/THRecon/wiki/Ports) | [Select Registry](https://github.com/TonyPhipps/THRecon/wiki/Registry) |
| Hotfixes | Handles* | Sofware | Hardware | [Event Logs](https://github.com/TonyPhipps/THRecon/wiki/EventLogs) |
| Net Adapters | Net Routes | Sessions | Shares | [Certificates](https://github.com/TonyPhipps/THRecon/wiki/Certificates) | 
| [Scheduled Tasks](https://github.com/TonyPhipps/THRecon/wiki/ScheduledTasks) | TPM | Bitlocker | Recycle Bin | User Files |

\* Info pulled from current running processes or their executables on disk.

Use one of the methods below to analyze for potential compromise/adversary activity leveraging the [Mitre Attack Framework](https://attack.mitre.org/wiki/Main_Page) or other threat hunting methods:
* Pull a snapshot from a single system into a list of easy-to-analyze csv files
* Ingest using your SIEM of choice (_Check out [THRecon-Elasticstack](https://github.com/TonyPhipps/THRecon-Elasticstack) and [SIEM Tactics](https://github.com/TonyPhipps/SIEM)_)
* Pull directly into Powershell objects for further enrichment

______________________________________________________

## Index

  * [Requirements](#requirements)
  * [Quick Install](#quick-install)
  * [Quick Test Use](#quick-test-use)
  * [Troubleshooting](#troubleshooting)
  * [Screenshots](#screenshots)
  
______________________________________________________

### Requirements

* Requires Powershell 5.0 or above on the "scanning" device.
* Requires Powershell 3.0 or higher on target systems (2.0 may be adequate in some cases).
* When scanning a remote machine without the psexec wrapper (Invoke-THR_PSExec), requires WinRM service on remote machine.

### Quick Install

After install, a new Powershell window will provide access to the modules.

#### With [Git](https://gitforwindows.org/)

```
git clone https://github.com/TonyPhipps/THRecon C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon
```

To update, use

```
cd C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon
git pull
```

#### Without Git
```
$Modules = "C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\"
New-Item -ItemType Directory $Modules\THRecon\ -force
Invoke-WebRequest https://github.com/TonyPhipps/THRecon/archive/master.zip -OutFile $Modules\master.zip
Expand-Archive $Modules\master.zip -DestinationPath $Modules
Copy-Item $Modules\THRecon-master\* $Modules\THRecon\ -Force -Recurse
Remove-Item  $Modules\THRecon-master -Recurse -Force
```
Commands above can be ran again to update

### Quick Test Use

This command will output results of a scan against localhost to c:\temp\

```
Invoke-THR -Quick
```

### Screenshots

Output of Command "Invoke-THR"

![Output of Command "invoke-thr -verbose"](https://i.imgur.com/zcmra0v.png)

Output Files

![Output Files](https://i.imgur.com/D3kpjun.png)
