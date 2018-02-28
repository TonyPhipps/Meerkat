# THRecon
-Threat Hunting Reconnaissance Toolkit-

Collect pertitent information for cyber threat hunting on your systems using this toolkit. Alternatively, ingest the output into an analysis tool like ELK or Splunk to quickly pinpoint anomolous systems.

## Information Collected
| Host Info | Processes | Services | Autoruns |
| :---: | :---: | :---: | :---: |
| ARP | DNS | EnvVars | Hosts File | 
| DLLs | Drivers | Group Members | Handles |
| Hardware | Sofware | Hotfixes | Ports |
| Net Adapters | Net Routes | Sessions | Shares |
| Scheduled Tasks | TPM | Bitlocker | Recycle Bin |
  
## Quick Install
Run this command in Powershell with [git](https://gitforwindows.org/) installed, then open a new Powershell session.
```
git clone https://github.com/TonyPhipps/THRecon C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon

```
Without git... make the folder, then drop all the contents of this project into it. Then open a new Powershell session.
```
mkdir C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon
```
