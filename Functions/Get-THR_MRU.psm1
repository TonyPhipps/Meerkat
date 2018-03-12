function Get-THR_MRU {
    <#
    .SYNOPSIS 
        Gets a Most Recently Used information from various locations.

    .DESCRIPTION 
        Gets a Most Recently Used information from various locations.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_MRU
        Get-THR_MRU SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_MRU
        Get-THR_MRU $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_MRU

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
       https://andreafortuna.org/cybersecurity/windows-registry-in-forensic-analysis/
        https://gbhackers.com/windows-registry-analysis-tracking-everything-you-do-on-the-system/

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

        class RegistryItem
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
            ""

            $UserKeys =
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSaveMRU",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedMRU",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRULegacy",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\CIDSizeMRU",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
            "\Software\Microsoft\Internet Explorer\TypedURLs",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist",
            "\Software\Microsoft\Search Assistant\ACMru",
            "\Software\Microsoft\Currentversion\Search\RecentApps",
            "\Software\Microsoft\Office\13.0\Access\File MRU",
            "\Software\Microsoft\Office\14.0\Access\File MRU",
            "\Software\Microsoft\Office\15.0\Access\File MRU",
            "\Software\Microsoft\Office\16.0\Access\File MRU",
            "\Software\Microsoft\Office\13.0\Excel\File MRU",
            "\Software\Microsoft\Office\14.0\Excel\File MRU",
            "\Software\Microsoft\Office\15.0\Excel\File MRU",
            "\Software\Microsoft\Office\16.0\Excel\File MRU",
            "\Software\Microsoft\Office\13.0\Powerpoint\File MRU",
            "\Software\Microsoft\Office\14.0\Powerpoint\File MRU",
            "\Software\Microsoft\Office\15.0\Powerpoint\File MRU"
            "\Software\Microsoft\Office\16.0\Powerpoint\File MRU"
            "\Software\Microsoft\Office\13.0\Word\File MRU",
            "\Software\Microsoft\Office\14.0\Word\File MRU",
            "\Software\Microsoft\Office\15.0\Word\File MRU",
            "\Software\Microsoft\Office\16.0\Word\File MRU",
            "\Software\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List",
            "\Software\Microsoft\Microsoft Management Console\Recent File List",
            "\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
            
            

            $MachineValues = 
            ""


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
                $Output = [RegistryItem]::new()
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
            $Result = [RegistryItem]::new()

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