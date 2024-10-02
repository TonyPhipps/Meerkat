function Get-Disks {
    <#
    .SYNOPSIS 
        Collects information on each disk attached to the system.

    .DESCRIPTION 
        Collects information on each disk attached to the system.
       
    .EXAMPLE 
        Get-Disks

    .EXAMPLE
        Get-Disks | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
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
        Updated: 2024-06-03

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

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-Disks at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $ResultsArray = Get-CIMInstance -Class Win32_DiskDrive | ForEach-Object {
            $disk = $_
            $partitions = "ASSOCIATORS OF " +
                          "{Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} " +
                          "WHERE AssocClass = Win32_DiskDriveToDiskPartition"
          
            Get-CIMInstance -Query $partitions | ForEach-Object {
                $partition = $_
                $drives = "ASSOCIATORS OF " +
                            "{Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} " +
                            "WHERE AssocClass = Win32_LogicalDiskToPartition"
                
                Get-CIMInstance -Query $drives | ForEach-Object {
                    New-Object -Type PSCustomObject -Property @{
                        Host          = $env:COMPUTERNAME
                        DateScanned   = $DateScanned
                        DiskID        = $disk.DeviceID
                        DiskSize      = [math]::round($disk.Size / 1024 / 1024 / 1024, 2)
                        DiskModel     = $disk.Model
                        DiskSerial    = $_.VolumeSerialNumber
                        Partition     = $partition.Name
                        PartitionSize = [math]::round($partition.Size / 1024 / 1024 / 1024, 2)
                        VolDeviceID   = $_.DeviceID
                        VolumeName    = $_.VolumeName
                        VolumeSize    = [math]::round($_.Size / 1024 / 1024 / 1024, 2)
                        VolumeFree    = [math]::round($_.FreeSpace / 1024 / 1024 / 1024, 2)
                        VolPercUsed   = try{ [math]::round(($_.Size - $_.FreeSpace) / $_.Size * 100, 2) } catch { 0 }
                    }
                }
            }
        }
        
        return $ResultsArray | Select-Object Host, DateScanned, DiskID, DiskSize, DiskModel, DiskSerial, Partition, PartitionSize, VolDeviceID, VolumeName, VolumeSize, VolumeFree, VolPercUsed
    }
    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ"))
    }
}
