NOTE: Some lines will be messed up due to markdown, be sure to grab raw file, not copy/paste while displaying as markdown!

# Higher Priority

- Update Get-ComputerDetails
  - Add "System Role"
  - Add "License Status"
  - Add "Up Time"
  - - Add "USB Storage Lock"
  - reg query HKLM\SYSTEM\CurrentControlSet\Services\USBStor /V Start

- Update Get-GroupMembers
  - Last Login DateTime
  - Account Disabled
  - Password Required
  - Password Expired
  - User Can Change Password
  - Last Password Change

- Update AuditPolicy
  - dumpsec.exe /rpt=policy
    - Minimum Password Length

- Update Get-NetAdapters
  - Sniffing NICs
    - wmic /namespace:\\root\wmi PATH MSNdis_CurrentPacketFilter GET
      - With NdisCurrentPacketFilter >= 32

- Add Get-WindowsDefender
  - Product
  - Version
  - RealTime Scan Enabled
  - Virus Signature Version/Date
  - IPS SIgnature Version/Date
  - Last Scan Datetime


- Add Get-EventLogs
  - Log Name
  - Earliest Log Date

- Add Get-LoginFailures
  - (last 60 days)
  - Account Name
  - Total Failed Logins

- Add Get-UserGroupPermissionChanges
  - (Filtered on Event IDs 4720, 4726, 4732, 4733, 4781)
  - Timestamp
  - User Name
  - User SID
  - Domain/Group
  - Message
  - Event Code
  - Record Number

- Add Get-WindowsFirewall
  - Rule Name
  - Enabled
  - Direction
  - Profiles
  - Grouping
  - Local IP
  - Remote IP
  - Protocol
  - Local Port
  - Remote Port
  - Action

- Add Get-USBHistory
  - reg query HKLM\SYSTEM\CurrentControlSet\Enum\USBStor
  - (replace & and _ with space)

- Add Get-Disks
  - Get-WmiObject -Class Win32_LogicalDisk -Namespace "root\cimv2"
  - Disk Description
  - Device ID
  - File System
  - Disk Size
  - Free Space
  - Percent Used




# Lower Priority

- c:\windows\prefetch file listing
  - FullName, CreationTimeUtc, LastAccesstimeUtc, LastWriteTimeUtc
- ShimCache entries
  - HKLM\SYSTEM\CurrentControlSet\Control\SessionManager\AppCompatCache\AppCompatCache
  - ref https://github.com/mandiant/ShimCacheParser
- Pull recent RDP Client activity from registry
  - "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Servers"
- Build module(s) to pull files
  - C:\Users\username\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
  - \%SystemRoot%\AppCompat\Programs\Amcache.hve
  - logs
    - c:\Windows\System32\winevt\Logs\*.evtx
    - c:\windows\system32\LogFiles\Firewall\pfirewall.log
    - c:\Users\*\Documents\*\PowerShell_trascript*.txt
  - memory
    - c:\hiberfil.sys
    - c:\pagefile.sys
    - c:\swapfile.sys
    - c:\windows\memory.dmp
    - c:\Windows\LiveKernelReports\*.dmp
  - Registry
    - c:\users\*\ntuser.dat
  - Scheduled Tasks
    - c:\windows\tasks\*.job
  - Browser history artifacts.
    - c:\Users\*\AppData\Local\Microsoft\Windows\History\History.IE5\index.dat
    - c:\Users\*\AppData\Local\Microsoft\Windows\History\History.IE5\MSHist*\index.dat
    - c:\Users\*\AppData\Local\Microsoft\Windows\History\Low\History.IE5\index.dat
    - c:\Users\*\AppData\Local\Microsoft\Windows\History\Low\History.IE5\MSHist*\index.dat
    - c:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.IE5\index.dat
    - c:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\Low\Content.IE5\index.dat
    - c:\Users\*\AppData\Roaming\Microsoft\Windows\Cookies\index.dat
    - c:\Users\*\AppData\Roaming\Microsoft\Windows\Cookies\Low\index.dat
    - c:\Users\*\AppData\Local\Microsoft\Internet Explorer\Recovery\*\*.dat
    - c:\Users\*\AppData\Local\Microsoft\Internet Explorer\Recovery\Immersive\*\*.dat
    - c:\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\*.sqlite
    - c:\Users\*\AppData\Local\Microsoft\Windows\WebCache\*.dat
    - c:\Users\*\AppData\Local\Google\Chrome\User Data\*\History
    - c:\Users\*\AppData\Local\Google\Chrome\User Data\*\Current Session
    - c:\Users\*\AppData\Local\Google\Chrome\User Data\*\Last Session
    - c:\Users\*\AppData\Local\Google\Chrome\User Data\*\Current Tabs
    - c:\Users\*\AppData\Local\Google\Chrome\User Data\*\Last Tabs
    - c:\Users\*\AppData\Roaming\Macromedia\FlashPlayer\#SharedObjects\*\*\*.sol
    - c:\Documents And Settings\*\Local Settings\History\History.IE5\index.dat
    - c:\Documents And Settings\*\Local Settings\History\History.IE5\MSHist*\index.dat
    - c:\Documents And Settings\*\Local Settings\Temporary Internet Files\Content.IE5\index.dat
    - c:\Documents And Settings\*\Cookies\index.dat
    - c:\Documents And Settings\*\Application Data\Mozilla\Firefox\Profiles\*\*.sqlite
    - c:\Documents And Settings\*\Local Settings\Application Data\Google\Chrome\User Data\*\History
    - c:\Documents And Settings\*\Local Settings\Application Data\Google\Chrome\*
- Build module for prefetch file info
  - c:\Windows\Prefetch\*.pf
