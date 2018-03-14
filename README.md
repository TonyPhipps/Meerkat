# THRecon
-Threat Hunting Reconnaissance Toolkit-

Collect endpoint information for use in incident response triage / threat hunting / live forensics using this toolkit. When a security alert raises concern over a managed system, this toolkit aims to empower the analyst with as much relevant information as possible to help [determine](https://attack.mitre.org/wiki/Main_Page) if a compromise occurred.

Alternatively, the output of this tool may be ingested into an analysis tool like [ELK](https://www.elastic.co/elk-stack), [Graylog](https://www.graylog.org/), or [Splunk](https://www.splunk.com/) to quickly pinpoint anomolous results. For example, a single instance of a process path across all your endpoints would be considered suspicious, waranting investigation.

Requires Powershell 5.0 or above on the "scanning" device (in most cases, Powershell 3.0 or higher on target systems).

## Information Collected
| Host Info | Processes* | Services | Autoruns | Drivers |
| :---: | :---: | :---: | :---: | :---: |
| ARP | DLLs* | EnvVars | Hosts File | ADS |
| DNS | Strings* | Group Members | Ports | Select Registry |
| Hotfixes | Handles* | Sofware | Hardware | Event Logs (24h) |
| Net Adapters | Net Routes | Sessions | Shares | | 
| Scheduled Tasks | TPM | Bitlocker | Recycle Bin | |

\* Info pulled from current running processes, or their executables.
  
## Quick Install
Run this command in Powershell with [git](https://gitforwindows.org/) installed, then open a new Powershell session.
```
git clone https://github.com/TonyPhipps/THRecon C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon

```
Without git... make the folder, then drop all the contents of this project into it. Then open a new Powershell session.
```
mkdir C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon
```
## Quick Test Use
To run a "quick" scan on your own system...
```
mkdir c:\temp\test
cd c:\temp\test
Invoke-THR -All -Quick
```

## Troubleshooting
[Installing a Powershell Module](https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx)

