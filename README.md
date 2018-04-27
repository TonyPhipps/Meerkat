# THRecon
-Threat Hunting Reconnaissance Toolkit-

Collect endpoint information for use in incident response triage / threat hunting / live forensics using this toolkit. When a security alert raises concern over a managed system, this toolkit aims to empower the analyst with as much relevant information as possible to help [determine](https://attack.mitre.org/wiki/Main_Page) if a compromise occurred.

Alternatively, the output of this tool may be ingested into an analysis tool like [ELK](https://www.elastic.co/elk-stack), [Graylog](https://www.graylog.org/), or [Splunk](https://www.splunk.com/) for stack-counting and other analysis techniques.

Requires Powershell 5.0 or above on the "scanning" device.

Requires Powershell 3.0 or higher on target systems (2.0 may be adequate in some cases).

______________________________________________________

  * [Information Collected](#information-collected)
  * [Quick Install](#quick-install)
  * [Quick Test Use](#quick-test-use)
  * [Troubleshooting](#troubleshooting)
  * [Screenshots](#screenshots)
  
______________________________________________________

## Information Collected 

_Linked to Hunt Use Cases_

| [Host Info](https://github.com/TonyPhipps/THRecon/wiki/Computer) | [Processes](https://github.com/TonyPhipps/THRecon/wiki/Processes)* | [Services](https://github.com/TonyPhipps/THRecon/wiki/Services) | [Autoruns](https://github.com/TonyPhipps/THRecon/wiki/Autoruns) | [Drivers](https://github.com/TonyPhipps/THRecon/wiki/Drivers) |
| :---: | :---: | :---: | :---: | :---: |
| ARP | [DLLs](https://github.com/TonyPhipps/THRecon/wiki/DLLs)* | EnvVars | Hosts File | ADS |
| [DNS](https://github.com/TonyPhipps/THRecon/wiki/DNS) | Strings* | [Users & Groups](https://github.com/TonyPhipps/THRecon/wiki/GroupMembers) | [Ports](https://github.com/TonyPhipps/THRecon/wiki/Ports) | [Select Registry](https://github.com/TonyPhipps/THRecon/wiki/Registry) |
| Hotfixes | Handles* | Sofware | Hardware | [Event Logs](https://github.com/TonyPhipps/THRecon/wiki/EventLogs) |
| Net Adapters | Net Routes | Sessions | Shares | [Certificates](https://github.com/TonyPhipps/THRecon/wiki/Certificates) | 
| [Scheduled Tasks](https://github.com/TonyPhipps/THRecon/wiki/ScheduledTasks) | TPM | Bitlocker | Recycle Bin | User Files |

\* Info pulled from current running processes or their executables on disk.
  
## Quick Install
Run this command in Powershell with [git](https://gitforwindows.org/) installed, then open a new Powershell session.
```
git clone https://github.com/TonyPhipps/THRecon C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon

```
Without git... make the folder, then drop all the contents of this project into it. Then open a new Powershell session.
```
mkdir C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon\
```
## Quick Test Use
To run a "quick" scan on your own system, you will need to create a blank folder, then run the cmdlet within that folder, since output defaults to the current working directory.

```
mkdir c:\temp\
cd c:\temp\
Invoke-THR -Quick
```

## Troubleshooting
[Installing a Powershell Module](https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx)

If your system does not automatically load modules in your user [profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-6), you may need to [import the module manually](https://msdn.microsoft.com/en-us/library/dd878284(v=vs.85).aspx).

```
cd C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon\
Import-Module THRecon.psm1
```

### Screenshots

Output of Command "Invoke-THR"

![Output of Command "invoke-thr -verbose"](https://i.imgur.com/zcmra0v.png)

Output Files

![Output Files](https://i.imgur.com/D3kpjun.png)
