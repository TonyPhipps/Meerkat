function Get-Disks {
    <#
    .SYNOPSIS 
        Gets information on all disks.

    .DESCRIPTION 
        Gets information on all disks.
       
    .EXAMPLE 
        Get-Disks

    .EXAMPLE
        Get-Disks | 
        Export-Csv -NoTypeInformation ("c:\temp\Disks.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Disks} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Disks.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-Disks} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_Disks.csv")
        }

    .NOTES 
        Updated: 2024-04-15

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2024
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
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-Disks at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $ResultsArray = Get-CIMinstance -Class Win32_LogicalDisk -Namespace "root\cimv2"

        if ($ResultsArray) {

            foreach ($Result in $ResultsArray) {

                $Used = $Result.Size - $Result.FreeSpace
                if (($Result.size -eq 0) -or ($null -eq $Result.size)) {
                    $PercentUsed = 0   
                } else {
                    $PercentUsed = $Used / $Result.Size * 100
                    $PercentUsed = [math]::round($PercentUsed, 2)   
                }

                $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
                $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
                $Result | Add-Member -MemberType NoteProperty -Name "PercentUsed" -Value $PercentUsed
            }

            return $ResultsArray | Select-Object Host, DateScanned, Description, DeviceID, FileSystem, Size, FreeSpace, PercentUsed
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}
