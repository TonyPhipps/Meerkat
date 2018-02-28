function Get-THR_SCCM_LogicalDisks {
    <#
    .SYNOPSIS 
        Queries SCCM for a given hostname, FQDN, or IP address.

    .DESCRIPTION 
        Queries SCCM for a given hostname, FQDN, or IP address.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER CIM
        Use Get-CIMInstance rather than Get-WMIObject. CIM cmdlets use WSMAN (WinRM)
        to connect to remote machines, and has better standardized output (e.g. 
        datetime format). CIM cmdlets require the querying user to be a member of 
        Administrators or WinRMRemoteWMIUsers_ on the target system. Get-WMIObject 
        is the default due to lower permission requirements, but can be blocked by 
        firewalls in some environments.

    .EXAMPLE 
        Get-THR_SCCM_LogicalDisks 
        Get-THR_SCCM_LogicalDisks SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_SCCM_LogicalDisks
        Get-THR_SCCM_LogicalDisks $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_SCCM_LogicalDisks

    .NOTES 
        Updated: 2018-02-07

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

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer,
        [Parameter()]
        $SiteName="A1",

        [Parameter()]
        $SCCMServer="server.domain.com",
        
        [Parameter()]
        [switch]$CIM
    )

	begin{
        $SCCMNameSpace="root\sms\site_$SiteName"

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $datetime)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0
	}

    process{        
                
        if ($Computer -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){ # is this an IP address?
            
            $fqdn = [System.Net.Dns]::GetHostByAddress($Computer).Hostname
            $ThisComputer = $fqdn.Split(".")[0]
        }
        
        else{ # Convert any FQDN into just hostname
            
            $ThisComputer = $Computer.Split(".")[0].Replace('"', '')
        }

        $output = [PSCustomObject]@{
            Name = $ThisComputer
            ResourceNames = ""
            Caption = ""
            Compressed = ""
            Description = ""
            DeviceID = ""
            DriveType = ""
            ErrorDescription = ""
            FileSystem = ""
            FreeSpace = ""
            InstallDate = ""
            LastErrorCode = ""
            DiskName = ""
            Size = ""
            Status = ""
            StatusInfo = ""
            VolumeName = ""
            VolumeSerialNumber = ""
            Timestamp = ""
        }

        if ($CIM){
            
            $SMS_R_System = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceNames, ResourceID from SMS_R_System where name='$ThisComputer'"
            $ResourceID = $SMS_R_System.ResourceID # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
            $SMS_G_System_LOGICAL_DISK = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select Caption, Compressed, Description, DeviceID, DriveType, ErrorDescription, FileSystem, FreeSpace, InstallDate, LastErrorCode, Name, Size, Status, StatusInfo, TimeStamp, VolumeName, VolumeSerialNumber from SMS_G_System_LOGICAL_DISK where ResourceID='$ResourceID'"
        }
        else {

            $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceNames, ResourceID from SMS_R_System where name='$ThisComputer'"
            $ResourceID = $SMS_R_System.ResourceID # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
            $SMS_G_System_LOGICAL_DISK = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select Caption, Compressed, Description, DeviceID, DriveType, ErrorDescription, FileSystem, FreeSpace, InstallDate, LastErrorCode, Name, Size, Status, StatusInfo, TimeStamp, VolumeName, VolumeSerialNumber from SMS_G_System_LOGICAL_DISK where ResourceID='$ResourceID'"
        }

        if ($SMS_G_System_LOGICAL_DISK){
                
            $SMS_G_System_LOGICAL_DISK | ForEach-Object {
                
                $output.ResourceNames = $SMS_R_System.ResourceNames[0]

                $output.Caption = $_.Caption
                $output.Compressed = $_.Compressed
                $output.DESCRIPTION = $_.DESCRIPTION
                $output.DeviceID = $_.DeviceID
                $output.DriveType = $_.DriveType
                $output.ErrorDescription = $_.ErrorDescription
                $output.FileSystem = $_.FileSystem
                $output.FreeSpace = $_.FreeSpace
                $output.InstallDate = $_.InstallDate
                $output.LastErrorCode = $_.LastErrorCode
                $output.DiskName = $_.Name
                $output.Size = $_.Size
                $output.Status = $_.Status
                $output.StatusInfo = $_.StatusInfo
                $output.VolumeName = $_.VolumeName
                $output.VolumeSerialNumber = $_.VolumeSerialNumber
                    
                $output.Timestamp = $_.Timestamp
                    
                return $output
                $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)} 
            }
        }
        else {

            return $output
            $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)} 
        }

        $elapsed = $stopwatch.Elapsed
        $total = $total+1
            
        Write-Verbose -Message "System $total `t $ThisComputer `t Time Elapsed: $elapsed"

    }

    end{
        $elapsed = $stopwatch.Elapsed
        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed"
	}
}


