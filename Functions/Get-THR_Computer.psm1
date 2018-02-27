Function Get-THR_Computer {
    <#
    .SYNOPSIS
        Gets general system information on a given system.

    .DESCRIPTION
        Gets general system information on a given system. Includes data from 
        Win32_ComputerSystem, Win32_OperatingSystem, and win32_BIOS. Begins 
        with CIM and falls back to WMI.

    .PARAMETER Computer
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE
        Get-THR_Computer 
        Get-THR_Computer SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Computer
        Get-THR_Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Computer

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

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME
    )

    begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Verbose ("Started at {0}" -f $datetime)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class Computer {
            [String] $Computer
            [DateTime] $DateScanned

            # Win32_OperatingSystem
            [String] $BootDevice
            [String] $BuildNumber
            [String] $Caption
            [int16] $CurrentTimeZone
            [bool] $DataExecutionPrevention_32BitApplications
            [bool] $DataExecutionPrevention_Available
            [bool] $DataExecutionPrevention_Drivers
            [bool] $DataExecutionPrevention_SupportPolicy
            [bool] $Debug
            [String] $Description
            [bool] $Distributed
            [bool] $EncryptionLevel
            [datetime] $InstallDate
            [datetime] $LastBootUpTime
            [datetime] $LocalDateTime
            [String] $MUILanguages
            [String] $OSArchitecture
            [uint32] $OSProductSuite
            [uint16] $OSType
            [uint32] $OperatingSystemSKU
            [String] $Organization
            [String] $OtherTypeDescription
            [bool] $PortableOperatingSystem
            [uint32] $ProductType
            [String] $RegisteredUser
            [uint32] $ServicePackMajorVersion
            [uint32] $ServicePackMinorVersion
            [String] $Status
            [uint32] $SuiteMask
            [String] $SystemDevice
            [String] $SystemDirectory
            [String] $SystemDrive
            [String] $Version
            [String] $WindowsDirectory
            
            # Win32_ComputerSystem
            [uint16] $AdminPasswordStatus
            [bool] $BootROMSupported
            [String] $BootupState
            [uint16] $ChassisBootupState
            [String] $DNSHostName
            [bool] $DaylightInEffect
            [String] $Domain
            [uint16] $DomainRole
            [bool] $EnableDaylightSavingsTime
            [bool] $HypervisorPresent
            [String] $Manufacturer
            [String] $Model
            [bool] $NetworkServerModeEnabled
            [String] $PrimaryOwnerContact
            [String] $PrimaryOwnerName
            [String] $SupportContactDescription
            [String] $SystemSKUNumber
            [uint16] $ThermalState
            [String] $UserName

            # Win32_BIOS
            [String] $BIOSVersion
            [datetime] $BIOSInstallDate
            [String] $BIOSManufacturer
            [bool] $PrimaryBIOS
            [datetime] $BIOSReleaseDate
            [String] $SMBIOSBIOSVersion
            [uint16] $SMBIOSMajorVersion
            [uint16] $SMBIOSMinorVersion
            [bool] $SMBIOSPresent
            [String] $SerialNumber
            [uint16] $SystemBiosMajorVersion
            [uint16] $SystemBiosMinorVersion
        }
    }

    process{

        $Computer = $Computer.Replace('"', '')
        
        Write-Verbose ("{0}: Querying remote system" -f $Computer) 
            $Win32_OperatingSystem = Get-CIMinstance -class Win32_OperatingSystem -ComputerName $Computer -ErrorAction SilentlyContinue
            if (!$Win32_OperatingSystem) { $Win32_OperatingSystem = Get-WmiObject -class Win32_OperatingSystem -ComputerName $Computer -ErrorAction SilentlyContinue }
        
        if ($Win32_OperatingSystem) {
            
            $Win32_ComputerSystem = Get-CimInstance -class Win32_ComputerSystem -ComputerName $Computer -ErrorAction SilentlyContinue
            if (!$Win32_ComputerSystem) { $Win32_ComputerSystem = Get-WmiObject -class Win32_ComputerSystem -ComputerName $Computer -ErrorAction SilentlyContinue }

            $Win32_BIOS = Get-CIMinstance -class Win32_BIOS -ComputerName $Computer -ErrorAction SilentlyContinue
            if (!$Win32_BIOS) { $Win32_BIOS = Get-WmiObject -class Win32_BIOS -ComputerName $Computer -ErrorAction SilentlyContinue }

            $output = $null
            $output = [Computer]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format u

            # Win32_OperatingSystem
            $output.BootDevice = $Win32_OperatingSystem.BootDevice
            $output.BuildNumber = $Win32_OperatingSystem.BuildNumber
            $output.Caption = $Win32_OperatingSystem.Caption
            $output.CurrentTimeZone = $Win32_OperatingSystem.CurrentTimeZone
            $output.DataExecutionPrevention_32BitApplications = $Win32_OperatingSystem.DataExecutionPrevention_32BitApplications
            $output.DataExecutionPrevention_Available = $Win32_OperatingSystem.DataExecutionPrevention_Available
            $output.DataExecutionPrevention_Drivers = $Win32_OperatingSystem.DataExecutionPrevention_Drivers
            $output.DataExecutionPrevention_SupportPolicy = $Win32_OperatingSystem.DataExecutionPrevention_SupportPolicy
            $output.Debug = $Win32_OperatingSystem.Debug
            $output.DESCRIPTION = $Win32_OperatingSystem.DESCRIPTION
            $output.Distributed = $Win32_OperatingSystem.Distributed
            $output.EncryptionLevel = $Win32_OperatingSystem.EncryptionLevel
            $output.InstallDate = $Win32_OperatingSystem.InstallDate
            $output.LastBootUpTime = $Win32_OperatingSystem.LastBootUpTime
            $output.LocalDateTime = $Win32_OperatingSystem.LocalDateTime
            $output.MUILanguages = $Win32_OperatingSystem.MUILanguages
            $output.OSArchitecture = $Win32_OperatingSystem.OSArchitecture
            $output.OSProductSuite = $Win32_OperatingSystem.OSProductSuite
            $output.OSType = $Win32_OperatingSystem.OSType
            $output.OperatingSystemSKU = $Win32_OperatingSystem.OperatingSystemSKU
            $output.Organization = $Win32_OperatingSystem.Organization
            $output.OtherTypeDescription = $Win32_OperatingSystem.OtherTypeDescription
            $output.PortableOperatingSystem = $Win32_OperatingSystem.PortableOperatingSystem
            $output.ProductType = $Win32_OperatingSystem.ProductType
            $output.RegisteredUser = $Win32_OperatingSystem.RegisteredUser
            $output.ServicePackMajorVersion = $Win32_OperatingSystem.ServicePackMajorVersion
            $output.ServicePackMinorVersion = $Win32_OperatingSystem.ServicePackMinorVersion
            $output.Status = $Win32_OperatingSystem.Status
            $output.SuiteMask = $Win32_OperatingSystem.SuiteMask
            $output.SystemDevice = $Win32_OperatingSystem.SystemDevice
            $output.SystemDirectory = $Win32_OperatingSystem.SystemDirectory
            $output.SystemDrive = $Win32_OperatingSystem.SystemDrive
            $output.Version = $Win32_OperatingSystem.Version
            $output.WindowsDirectory = $Win32_OperatingSystem.WindowsDirectory

            # Win32_ComputerSystem
            $output.AdminPasswordStatus = $Win32_ComputerSystem.AdminPasswordStatus
            $output.BootROMSupported = $Win32_ComputerSystem.BootROMSupported
            $output.BootupState = $Win32_ComputerSystem.BootupState
            $output.ChassisBootupState = $Win32_ComputerSystem.ChassisBootupState
            $output.DNSHostName = $Win32_ComputerSystem.DNSHostName
            $output.DaylightInEffect = $Win32_ComputerSystem.DaylightInEffect
            $output.DESCRIPTION = $Win32_ComputerSystem.DESCRIPTION
            $output.Domain = $Win32_ComputerSystem.Domain
            $output.DomainRole = $Win32_ComputerSystem.DomainRole
            $output.EnableDaylightSavingsTime = $Win32_ComputerSystem.EnableDaylightSavingsTime
            $output.HypervisorPresent = $Win32_ComputerSystem.HypervisorPresent
            $output.Manufacturer = $Win32_ComputerSystem.Manufacturer
            $output.Model = $Win32_ComputerSystem.Model
            $output.NetworkServerModeEnabled = $Win32_ComputerSystem.NetworkServerModeEnabled
            $output.PrimaryOwnerContact = $Win32_ComputerSystem.PrimaryOwnerContact
            $output.PrimaryOwnerName = $Win32_ComputerSystem.PrimaryOwnerName
            $output.SupportContactDescription = $Win32_ComputerSystem.SupportContactDescription
            $output.SystemSKUNumber = $Win32_ComputerSystem.SystemSKUNumber
            $output.ThermalState = $Win32_ComputerSystem.ThermalState
            $output.UserName = $Win32_ComputerSystem.UserName

            # Add BIOS Version
            $output.BIOSVersion = $Win32_BIOS.BIOSVersion
            if ($Win32_BIOS.InstallDate) { $output.BIOSInstallDate = $Win32_BIOS.InstallDate }
            $output.BIOSManufacturer = $Win32_BIOS.Manufacturer
            $output.PrimaryBIOS = $Win32_BIOS.PrimaryBIOS
            $output.BIOSReleaseDate = $Win32_BIOS.ReleaseDate
            $output.SMBIOSBIOSVersion = $Win32_BIOS.SMBIOSBIOSVersion
            $output.SMBIOSMajorVersion = $Win32_BIOS.SMBIOSMajorVersion
            $output.SMBIOSMinorVersion = $Win32_BIOS.SMBIOSMinorVersion
            $output.SMBIOSPresent = $Win32_BIOS.SMBIOSPresent
            $output.SerialNumber = $Win32_BIOS.SerialNumber
            $output.SystemBiosMajorVersion = $Win32_BIOS.SystemBiosMajorVersion
            $output.SystemBiosMinorVersion = $Win32_BIOS.SystemBiosMinorVersion

            $total++
            return $output 
        }
        else {
                
            $output = $null
            $output = [Computer]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format u
            
            $total++
            return $output
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}