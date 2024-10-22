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
        Updated: 2024-10-22

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

        Enum DriveType {
            NoRootDirectory = 1
            Removeable = 2
            Local = 3
            Network = 4
            CD = 5       
            RAM = 6
        }
    }

    process{
        $Disks = Get-CIMInstance -Class Win32_DiskDrive
        $ResultsArray = ForEach ($Disk in $Disks) {
            $PartitionsQuery =  "ASSOCIATORS OF " +
                                "{Win32_DiskDrive.DeviceID='$($Disk.DeviceID)'} " +
                                "WHERE AssocClass = Win32_DiskDriveToDiskPartition"
            $Partitions = Get-CIMInstance -Query $PartitionsQuery
            ForEach ($Partition in $Partitions) {
                $DrivesQuery =  "ASSOCIATORS OF " +
                                "{Win32_DiskPartition.DeviceID='$($Partition.DeviceID)'} " +
                                "WHERE AssocClass = Win32_LogicalDiskToPartition"
                $Drives = Get-CIMInstance -Query $DrivesQuery
                ForEach ($Drive in $Drives) {
                    New-Object -Type PSCustomObject -Property @{
                        Host                = $env:COMPUTERNAME
                        DateScanned         = $DateScanned
                        DiskID              = $Disk.DeviceID
                        DiskSizeGB          = [math]::round($Disk.Size / 1024 / 1024 / 1024, 2)
                        DiskModel           = $Disk.Model
                        DiskSerial          = $Drive.VolumeSerialNumber
                        DriveType           = ([DriveType]$Drive.DriveType).ToString()
                        Partition           = $Partition.Name
                        PartitionSizeGB     = [math]::round($Partition.Size / 1024 / 1024 / 1024, 2)
                        VolumeDeviceID      = $Drive.DeviceID
                        VolumeName          = $Drive.VolumeName
                        VolumeSizeGB        = [math]::round($Drive.Size / 1024 / 1024 / 1024, 2)
                        VolumeFreeGB        = [math]::round($Drive.FreeSpace / 1024 / 1024 / 1024, 2)
                        VolumePercentUsed   = try{ [math]::round(($Drive.Size - $Drive.FreeSpace) / $Drive.Size * 100, 2) } catch { 0 }
                    }
                }
            }
        }
        
        $CdDrives = Get-CIMInstance -Class Win32_CDROMDrive
        $ResultsArray += ForEach ($CdDrive in $CdDrives) {
            New-Object -Type PSCustomObject -Property @{
                Host                = $env:COMPUTERNAME
                DateScanned         = $DateScanned
                DiskID              = $CdDrive.DeviceID
                DiskSizeGB            = [math]::round($CdDrive.Size / 1024 / 1024 / 1024, 2)
                DiskModel           = $CdDrive.Name
                DiskSerial          = $CdDrive.VolumeSerialNumber
                DriveType           = ([DriveType]5).ToString() # Only querying CD-Drives here, will always be a CD drive (Property DriveType=5 if queried via Win32_LogicalDisk)
                PartitionSizeGB     = [math]::round($CdDrive.Size / 1024 / 1024 / 1024, 2)
                VolumeDeviceID      = $CdDrive.Id # Drive Letter for CD-Drives
                VolumeName          = $CdDrive.VolumeName # Name of media loaded, if any
                VolumeSizeGB        = [math]::round($CdDrive.Size / 1024 / 1024 / 1024, 2)
                VolumePercentUsed   = 0 # Not a useful metric for a CD drive, but setting this value at 100% would make searches for nearly fully drives require additional filters.
            }
        }
        return $ResultsArray | Select-Object Host, DateScanned, DiskID, DiskSizeGB, DiskModel, DiskSerial, DriveType, Partition, PartitionSizeGB, VolumeDeviceID, VolumeName, VolumeSizeGB, VolumeFreeGB, VolumePercentUsed
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ"))
    }
}
