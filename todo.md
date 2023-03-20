NOTE: Some lines will be messed up due to markdown, be sure to grab raw file, not copy/paste while displaying as markdown!

# Higher Priority

- Update Get-USBHistory to not throw an error when the USBSTOR key does not exist (like on virtual boxes)
- Update Get-EventsUserManagement to not throw an error when no matching events are present
- Update Get-Defender to not throw an error when no Quarantine folder exists
- Update Get-Defender to not throw an error if Get-MpComputerStatus fails due to not having Defender installed
- Create a diff script to identify differences between the "current" scan results and a "baseline" set of results.

# Lower Priority

- Look into https://github.com/ForensicArtifacts/artifacts

- Update Get-Registry to include 
  - Key='HKLM\SOFTWARE\Microsoft\Wbem\CIMON', Value='Autorecover MOFs', Data=*
    - https://0xdf.gitlab.io/2018/11/03/htb-dropzone.html
  - "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Servers"
    - recent RDP Client activity from registry

- Important file listings
  - FullName, CreationTimeUtc, LastAccesstimeUtc, LastWriteTimeUtc
  - c:\windows\prefetch 
  - c:\windows\system32\wbem\*.mof
  - c:\windows\system32\wbem\autorecover\
  - c:\windows\system32\wbem\repository\index.btr

- ShimCache entries
  - HKLM\SYSTEM\CurrentControlSet\Control\SessionManager\AppCompatCache\AppCompatCache
  - ref https://github.com/mandiant/ShimCacheParser

- Pull artifact files
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
