# THRecon
-Threat Hunting Reconnaissance Toolkit-

Collect pertitent information for cyber threat hunting on your systems using this toolkit. Alternatively, ingest the output into an analysis tool like ELK or Splunk to quickly pinpoint anomolous systems. Requires Powershell 5.0 or above on the "scanning" device (requirements vary on target devices per tool).

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

