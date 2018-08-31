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

  * [Quick Start](#quick-start)
  * [Usage](#usage)
    * [Requirements](#requirements)
    * [Installation](#installation)
    * [General Syntax](#general-syntax)
    * [Analysis](#analysis)
  * [Troubleshooting](#troubleshooting)
  * [Screenshots](#screenshots)
  
______________________________________________________

## Quick Start

### Requirements

* Requires Powershell 5.0 or above on the "scanning" device.
* Requires Powershell 3.0 or higher on target systems (2.0 may be adequate in some cases).
* When scanning a remote machine without the psexec wrapper (Invoke-THR_PSExec), requires WinRM service on remote machine.

After install, a new Powershell window will provide access to the functions.

### Install with [Git](https://gitforwindows.org/)

```
git clone https://github.com/TonyPhipps/THRecon C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon
```

To update, use

```
cd C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon
git pull
```

### Install with PowerShell
```
$Modules = "C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\"
New-Item -ItemType Directory $Modules\THRecon\ -force
Invoke-WebRequest https://github.com/TonyPhipps/THRecon/archive/master.zip -OutFile $Modules\master.zip
Expand-Archive $Modules\master.zip -DestinationPath $Modules
Copy-Item $Modules\THRecon-master\* $Modules\THRecon\ -Force -Recurse
Remove-Item  $Modules\THRecon-master -Recurse -Force
```
To update, simply run the same block of commands again.

### Run Invoke-THR

This command will output results of a scan against localhost to c:\temp\

```
Invoke-THR -Quick -Output c:\temp\
```

## Usage

All functions take full advantage of the built in comment-based help system. Use Get-Help cmdlet to review detailed syntax and documentation on each individual function included, e.g. `get-help get-thr_computer -full`.

### Requirements

By default, all modules will run against remote systems utilizing PowerShell's Invoke-Command cmdlet, which in turn requires the WinRM service to be enabled on the target system AND administrative rights (WinRM, by default, uses ports 5985 for http or 5986 for https). Utilizing Run-As with a privileged domain account to open powershell.exe or powershell_ise.exe is typically the method used. In the absence of a domain, a local administrator on the target system would be required.

Running modules locally does not require WinRM, as Invoke-Command is skipped. The Invoke-THR_PSexec function combined with this fact provides a workaround when WinRM is not an option. Invoke-THR_PSexec requires [Sysinternals psexec](https://docs.microsoft.com/en-us/sysinternals/downloads/psexec) and a slightly different syntax (details via `get-help Invoke-THR_PSexec -Full`).


### Installation

This toolkit consists of multiple functions deployed within a module. The installation of the entire module is recommended, but other options are available. The [Quick Start](#quick-start) provides multiple install methods. The per-user installation method was purposefully used in the Quick-Install scripts, rather than installing for all users. Non-privileged use of the scripts will provide abnormal or no results.

Optionally, functions can be installed as modules via `Import-Module Get-THR_FunctionName.psm1 -Force`. This can be useful if a small modification is required, such as adding a data field or other easily-adjusted code.

Lastly, functions can be installed by opening the .psm1 file and copy-pasting its entire contents into a PowerSell prompt.

### General Syntax

When running a single function against a single endpoint, the typical sytnax is `Get-THR_[ModuleName] -Computer [ComputerName]`, which returns objects relevant to the function called. All modules support the pipeline, which means results can be exported. For example, `Get-THR_[ModuleName] -Computer [ComputerName] | export-csv "c:\temp\results.csv -notypeinformation` will utilize PowerShell's built-in csv export function (details via `get-help get-thr_[function] -Full`).

Invoke-THR takes advantage of the `export-csv` cmdlet in this way by exporting ALL enabled modules to csv. The basic syntax is `Invoke-THR -Computer [Computername] -Modules [Module1, Module2, etc.]` (details via `get-help Invoke-THR -Full`).

Invoke-THR_PSexec is provided as a wrapper to simplify working with PSExec, since typical psexec use does not include deploying a function, importing it, running it, storing results, retrieving results, and removing results. 

1. The basic syntax for Invoke-THR_PSExec is `Invoke-THR-PSExec -Computer WorkComputer`, which runs a default collection. Customization of the collection requires adjusting the -Command parameter: `Invoke-thr_psexec -Computer WorkComputer -Command 'Invoke-THR -Mod Computer, MAC'`

2. The syntax for a single function is `Invoke-thr_psexec -Computer WorkComputer -Command 'Get-THR_[function] | export-csv c:\temp\MAC.csv -notypeinformation'`.

3. More details via `get-help Invoke-THR_PSexec -Full`

### Analysis

Analysis methodologies and techniques are provided in the [Wiki pages](https://github.com/TonyPhipps/THRecon/wiki).

## Troubleshooting
[Installing a Powershell Module](https://msdn.microsoft.com/en-us/library/dd878350(v=vs.85).aspx)

If your system does not automatically load modules in your user [profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-6), you may need to [import the module manually](https://msdn.microsoft.com/en-us/library/dd878284(v=vs.85).aspx).

```
cd C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon\
Import-Module THRecon.psm1
```

## Screenshots

Output of Command "Invoke-THR"

![Output of Command "invoke-thr -verbose"](https://i.imgur.com/zcmra0v.png)

Output Files

![Output Files](https://i.imgur.com/D3kpjun.png)
