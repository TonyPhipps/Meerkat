function Get-THR_RegistryKeys {
    <#
    .SYNOPSIS 
        Gets a list of registry keys that aid in threat hunting.

    .DESCRIPTION 
        Gets a list of registry keys that aid in threat hunting.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-Get-THR_RegistryKeys
        Get-Get-THR_RegistryKeys SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_RegistryKeys
        Get-THR_RegistryKeys $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_RegistryKeys

    .NOTES 
        Updated: 2018-02-20

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2018
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.

    .LINK
       https://github.com/TonyPhipps/THRecon
       https://attack.mitre.org/wiki/Technique/T1060
       https://blog.cylance.com/windows-registry-persistence-part-2-the-run-keys-and-search-order
       http://resources.infosecinstitute.com/common-malware-persistence-mechanisms/
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Verbose "Started at $DateScanned"

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class RegistryKey
        {
            [string] $Computer
            [Datetime] $DateScanned = $DateScanned
            
            [String] $Key
            [string] $Value
            [string] $Data
        }
    }

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present
        
        Write-Verbose ("{0}: Querying remote system" -f $Computer) 
        $ResultsArray = $null
        $ResultsArray = Invoke-Command -Computer $Computer -ErrorAction SilentlyContinue -ScriptBlock {
            
            $MachineKeys = 
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\BootExecute",
            "HKEY_LOCAL_MACHINE\SYSTEM\System\CurrentControlSet\Services",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServicesOnce",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunServicesOnce",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunServices",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnceEx",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SharedTaskScheduler",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",            
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects"
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\ShellServiceObjectDelayLoad"

            $UserKeys =
            # Need a loop to parse HKU to gather below keys for each user on the system
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce",
            "HKEY_CURRENT_USER\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunServicesOnce",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunServices",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",            
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders",
            "HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Windows\load"

            $MachineValues = 
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\UserInit",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell",
            "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Windows\AppInit_DLLs",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\IniFileMapping\system.ini\boot\Shell"

            $OutputArray = @()
        
            foreach ($Key in $MachineKeys){
                
                $Key = "Registry::" + $Key

                if (Test-Path $Key){
            
                    $keyObject = Get-Item $Key
            
                    $Properties = $keyObject.Property
            
                    if ($Properties) {
            
                        foreach ($Property in $Properties){
            
                            $OutputArray += [pscustomobject] @{
                                Key = $Key.Split(":")[2]
                                Value = $Property 
                                Data = $keyObject.GetValue($Property)
                            }
                        }
                    }
                    
                }
            }

            foreach ($Key in $MachineValues){
                
                $Key = "Registry::" + $Key
            
                $Value = Split-Path -Path $Key -Leaf
                $Key = Split-Path -Path $Key
            
                if (Test-Path $Key){
                        
                    if (Get-Item $Key){
                        
                        $Data = (Get-Item $Key).GetValue($Value)
                        
                        if ($Data) {
            
                            $OutputArray += [pscustomobject] @{
                                Key = $Key.Split(":")[2]
                                Value = $Value 
                                Data = $Data
                            }
                            
                        }
                    }
                }
            }
            
            return $OutputArray
        }

        if ($ResultsArray){
            
            $OutputArray = @()
            
            foreach ($Result in $ResultsArray){
                $Output = [RegistryKey]::new()
                $Output.Computer = $Computer
                $Output.DateScanned = $DateScanned

                $Output.Key = $Result.Key
                $Output.Value = $Result.Value
                $Output.Data = $Result.Data

                $OutputArray += $Output
            }

            $OutputArray = $OutputArray[1..($OutputArray.Length-1)] # Handles bug where first entry is blank
            return $OutputArray
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $Result = $null
            $Result = [RegistryKey]::new()

            $Result.Computer = $Computer
            $Result.DateScanned = $DateScanned
            
            $total++
            return $Result
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Started at {0}" -f $DateScanned)
        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}