function Get-USBHistory {
    <#
    .SYNOPSIS 
        Returns list of USB devices previously connected to target system from the registry.

    .DESCRIPTION 
        Returns list of USB devices previously connected to target system from the registry. Each device entry contains metadata for each device. 

    .EXAMPLE 
        Get-USBHistory

    .EXAMPLE
        Get-USBHistory | 
        Export-Csv -NoTypeInformation ("c:\temp\USBHistory.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-USBHistory} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\USBHistory.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-USBHistory} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_USBHistory.csv")
        }

    .NOTES 
        Updated: 2023-05-11

        Contributing Authors:
            Anthony Phipps, Jack Smith
            
        LEGAL: Copyright (C) 2023
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
       https://github.com/TonyPhipps/Meerkat
       https://github.com/TonyPhipps/Meerkat/wiki/USBHistory
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started Get-USBHistory at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{
          
        $USBStor = "Registry::HKLM\SYSTEM\CurrentControlSet\Enum\USBStor\"

        $DeviceTypes = Get-ChildItem $USBStor -ErrorAction SilentlyContinue | Out-Null

        $DeviceKeys = foreach ($DeviceType in $DeviceTypes) {
            Get-ChildItem ("Registry::" + $DeviceType.Name + "\*")
        }

        $Devices = foreach ($Device in $DeviceKeys){
            $keyObject = Get-Item ("Registry::" + $Device.Name)
            
            $Properties = $keyObject.Property
        
           foreach ($Property in $Properties){
                $Device | Add-Member -MemberType NoteProperty -Name $Property -Value $keyObject.GetValue($Property)
            }
        
           $Device
        }
        
        $ResultsArray = foreach ($Result in $Devices) {

            $Result.CompatibleIDs = ($Result.CompatibleIDs -join ", ")
            $Result.HardwareID = ($Result.HardwareID -join ", ")
            $Result | Add-Member -MemberType NoteProperty -Name "WindowsID" -Value $Result.PSParentPath.split("\")[-1]
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
            $Result
        }
        
        return $ResultsArray | Select-Object Host, DateScanned, Name, FriendlyName, WindowsID, Address, Capabilities, ClassGUID, CompatibleIDs, ConfigFlags, ContainerID, DeviceDesc, Driver, HardwareID, Mfg, Service
    }
    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}