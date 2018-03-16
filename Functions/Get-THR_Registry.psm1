function Get-THR_Registry {
    <#
    .SYNOPSIS 
        Gets a list of registry keys that may be used to achieve persistence or clear tracks.

    .DESCRIPTION 
        Gets a list of registry keys that may be used to achieve persistence or clear tracks.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Registry
        Get-THR_Registry SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Registry
        Get-THR_Registry $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Registry

    .NOTES 
        Updated: 2018-03-11

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
       https://github.com/TonyPhipps/THRecon/wiki/Registry
       https://blog.cylance.com/windows-registry-persistence-part-2-the-run-keys-and-search-order
       http://resources.infosecinstitute.com/common-malware-persistence-mechanisms/
       https://andreafortuna.org/cybersecurity/windows-registry-in-forensic-analysis/
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

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
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\ShellServiceObjectDelayLoad",
            "HKEY_LOCAL_MACHINE\SYSTEM\MountedDevices"

            $UserKeys =
            "\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce",
            "\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunServicesOnce",
            "\Software\Microsoft\Windows\CurrentVersion\RunServices",
            "\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell",
            "\Software\Microsoft\Windows\CurrentVersion\Run",
            "\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",            
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders",
            "\Software\Microsoft\Windows NT\CurrentVersion\Windows\load"

            $MachineValues = 
            "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\UserInit",
            "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell",
            "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Windows\AppInit_DLLs",
            "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify",
            "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\system.ini\boot\Shell"
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\ClearPagefileAtShutdown"

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

            # Regex pattern for SIDs
            $PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
            
            # Get all users' Username, SID, and location of ntuser.dat
            $UserArray = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | 
                Where-Object {$_.PSChildName -match $PatternSID} | 
                Select-Object  @{name="SID";expression={$_.PSChildName}}, 
                    @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
                    @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}
            
            $LoadedHives = Get-ChildItem Registry::HKEY_USERS | 
                Where-Object {$_.PSChildname -match $PatternSID} | 
                Select-Object @{name="SID";expression={$_.PSChildName}}
            
            $UnloadedHives = Compare-Object $UserArray.SID $LoadedHives.SID | 
                Select-Object @{name="SID";expression={$_.InputObject}}, UserHive, Username

            Foreach ($User in $UserArray) {
                
                If ($User.SID -in $UnloadedHives.SID) {

                    reg load HKU\$($User.SID) $($User.UserHive) | Out-Null
                }

                foreach ($Key in $UserKeys){

                    $Key = "Registry::HKEY_USERS\$($User.SID)" + $Key

                    if (Test-Path $Key){

                        $KeyObject = Get-Item $Key
                                
                        $Properties = $KeyObject.Property
                                
                        if ($Properties) { 
                                
                            foreach ($Property in $Properties){
                                
                                $OutputArray += [pscustomobject] @{
                                    Key = $Key.Split(":")[2]
                                    Value = $Property 
                                    Data = $KeyObject.GetValue($Property)
                                }
                            }  
                        }
                    }
                }
                
                If ($User.SID -in $UnloadedHives.SID) {
                    ### Garbage collection and closing of ntuser.dat ###

                    [gc]::Collect()
                    reg unload HKU\$($User.SID) | Out-Null
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

            $OutputArray = $OutputArray | Where-Object {$_.Data -ne ""}
            return $OutputArray
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $Result = $null
            $Result = [RegistryKey]::new()

            $Result.Computer = $Computer
            $Result.DateScanned = Get-Date -Format u
            
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