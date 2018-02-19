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
        Updated: 2018-02-18

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
            
            $keys = 
            #Covered by Get-THR-Autoruns
            #"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
            #"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",
            #"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
            #"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
            #"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run",
            #"Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            #"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
            #"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",
            #"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
            #"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run",
            #"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            #"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
            "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
            "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
        
            $OutputArray = @()
        
            foreach ($key in $keys){
        
                if (Test-Path $key){
            
                    if (Get-ItemProperty -Path $key){
            
                        $Properties = Get-ItemProperty -Path $key | 
                            Get-Member -MemberType NoteProperty | 
                            Where-Object {$_.Name -notmatch "PSParentPath|PSPath|PSChildName|PSProvider"} | 
                            Select-Object -ExpandProperty Name
            
                        if ($Properties) {
            
                            foreach ($Property in $Properties){
            
                                $OutputArray += [pscustomobject] @{
                                    Key = $key.Split(":")[2]
                                    Value = $Property 
                                    Data = (Get-ItemProperty -Path $key -Name $Property).$Property
                                }
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