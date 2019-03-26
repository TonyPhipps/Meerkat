Function Get-THR_Computer {
    <#
    .SYNOPSIS
        Gets general system information on a given system.

    .DESCRIPTION
        Gets general system information on a given system. Includes data from 
        Win32_ComputerSystem, Win32_OperatingSystem, and win32_BIOS.

    .PARAMETER Computer
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE
        Get-THR_Computer 
        Get-THR_Computer SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Computer
        Get-THR_Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Computer

    .NOTES
        Updated: 2019-03-25

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
       https://github.com/TonyPhipps/THRecon/wiki/Computer
       
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

        # class Computer {
        #     [String] $Computer
        #     [string] $DateScanned

        #     # Win32_OperatingSystem
        #     [String] $BootDevice
        #     [String] $BuildNumber
        #     [String] $Caption
        #     [int16] $CurrentTimeZone
        #     [bool] $DataExecutionPrevention_32BitApplications
        #     [bool] $DataExecutionPrevention_Available
        #     [bool] $DataExecutionPrevention_Drivers
        #     [bool] $DataExecutionPrevention_SupportPolicy
        #     [bool] $Debug
        #     [String] $Description
        #     [bool] $Distributed
        #     [bool] $EncryptionLevel
        #     [datetime] $InstallDate
        #     [datetime] $LastBootUpTime
        #     [datetime] $LocalDateTime
        #     [String] $MUILanguages
        #     [String] $OSArchitecture
        #     [uint32] $OSProductSuite
        #     [uint16] $OSType
        #     [uint32] $OperatingSystemSKU
        #     [String] $Organization
        #     [String] $OtherTypeDescription
        #     [bool] $PortableOperatingSystem
        #     [uint32] $ProductType
        #     [String] $RegisteredUser
        #     [uint32] $ServicePackMajorVersion
        #     [uint32] $ServicePackMinorVersion
        #     [String] $Status
        #     [uint32] $SuiteMask
        #     [String] $SystemDevice
        #     [String] $SystemDirectory
        #     [String] $SystemDrive
        #     [String] $Version
        #     [String] $WindowsDirectory
            
        #     # Win32_ComputerSystem
        #     [uint16] $AdminPasswordStatus
        #     [bool] $BootROMSupported
        #     [String] $BootupState
        #     [uint16] $ChassisBootupState
        #     [String] $DNSHostName
        #     [bool] $DaylightInEffect
        #     [String] $Domain
        #     [uint16] $DomainRole
        #     [bool] $EnableDaylightSavingsTime
        #     [bool] $HypervisorPresent
        #     [String] $Manufacturer
        #     [String] $Model
        #     [bool] $NetworkServerModeEnabled
        #     [String] $PrimaryOwnerContact
        #     [String] $PrimaryOwnerName
        #     [String] $SupportContactDescription
        #     [String] $SystemSKUNumber
        #     [uint16] $ThermalState
        #     [String] $UserName

        #     # Win32_BIOS
        #     [String] $BIOSVersion
        #     [datetime] $BIOSInstallDate
        #     [String] $BIOSManufacturer
        #     [bool] $PrimaryBIOS
        #     [datetime] $BIOSReleaseDate
        #     [String] $SMBIOSBIOSVersion
        #     [uint16] $SMBIOSMajorVersion
        #     [uint16] $SMBIOSMinorVersion
        #     [bool] $SMBIOSPresent
        #     [String] $SerialNumber
        #     [uint16] $SystemBiosMajorVersion
        #     [uint16] $SystemBiosMinorVersion

        #     # Win32_Processor
        #     [String] $VirtualizationFirmwareEnabled
        # }

        # $Command = {

            
        # }
    }

    process{

        # $Computer = $Computer.Replace('"', '')
        
        # Write-Verbose ("{0}: Querying remote system" -f $Computer)
        
        # if ($Computer -eq $env:COMPUTERNAME){
            
        #     $Result = & $Command 
        # } 
        # else {

            # $Result = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock $Command
        # }

            $Win32_OperatingSystem = Get-CIMinstance -class Win32_OperatingSystem
            $Win32_ComputerSystem = Get-CimInstance -class Win32_ComputerSystem
            $Win32_BIOS = Get-CIMinstance -class Win32_BIOS
            $Win32_Processor = Get-CIMinstance -class Win32_Processor

            $Computer = New-Object -TypeName PSObject

            foreach ($Property in $Win32_OperatingSystem.PSObject.Properties) {
                $Computer | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.value -ErrorAction SilentlyContinue
            }            

            foreach ($Property in $Win32_ComputerSystem.PSObject.Properties) {
                $Computer | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.value -ErrorAction SilentlyContinue
            }
                
            foreach ($Property in $Win32_Processor.PSObject.Properties) {
                $Computer | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.value -ErrorAction SilentlyContinue
            }

            foreach ($Property in $Win32_BIOS.PSObject.Properties) {
                $Computer | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.value -ErrorAction SilentlyContinue
            }

            $Computer | Add-Member -MemberType NoteProperty -Name BIOSInstallDate -Value $Win32_BIOS.InstallDate -ErrorAction SilentlyContinue # Resolves InstallDate conflict with Win32_OperatingSystem

            $Computer | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Computer | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned

            return $Computer | Select-Object Host, DateScanned, BootDevice, BuildNumber, Caption, CurrentTimeZone, DataExecutionPrevention_32BitApplications, DataExecutionPrevention_Available, DataExecutionPrevention_Drivers, DataExecutionPrevention_SupportPolicy, Debug, Description, Distributed, EncryptionLevel, InstallDate, LastBootUpTime, LocalDateTime, MUILanguages, OSArchitecture, OSProductSuite, OSType, OperatingSystemSKU, Organization, OtherTypeDescription, PortableOperatingSystem, ProductType, RegisteredUser, ServicePackMajorVersion, ServicePackMinorVersion, Status, SuiteMask, SystemDevice, SystemDirectory, SystemDrive, Version, WindowsDirectory, AdminPasswordStatus, BootROMSupported, BootupState, ChassisBootupState, DNSHostName, DaylightInEffect, Domain, DomainRole, EnableDaylightSavingsTime, HypervisorPresent, Manufacturer, Model, NetworkServerModeEnabled, PrimaryOwnerContact, PrimaryOwnerName, SupportContactDescription, SystemSKUNumber, ThermalState, UserName, BIOSVersion, BIOSInstallDate, BIOSManufacturer, PrimaryBIOS, BIOSReleaseDate, SMBIOSBIOSVersion, SMBIOSMajorVersion, SMBIOSMinorVersion, SMBIOSPresent, SerialNumber, SystemBiosMajorVersion, SystemBiosMinorVersion, VirtualizationFirmwareEnabled
        
        
        # if ($Result) {

        #     $output = $null
        #     $output = [Computer]::new()

        #     $output.Computer = $Computer
        #     $output.DateScanned = Get-Date -Format o

        #     # Win32_OperatingSystem
        #     $output.BootDevice = $Result.BootDevice
        #     $output.BuildNumber = $Result.BuildNumber
        #     $output.Caption = $Result.Caption
        #     $output.CurrentTimeZone = $Result.CurrentTimeZone
        #     $output.DataExecutionPrevention_32BitApplications = $Result.DataExecutionPrevention_32BitApplications
        #     $output.DataExecutionPrevention_Available = $Result.DataExecutionPrevention_Available
        #     $output.DataExecutionPrevention_Drivers = $Result.DataExecutionPrevention_Drivers
        #     $output.DataExecutionPrevention_SupportPolicy = $Result.DataExecutionPrevention_SupportPolicy
        #     $output.Debug = $Result.Debug
        #     $output.Distributed = $Result.Distributed
        #     $output.EncryptionLevel = $Result.EncryptionLevel
        #     $output.InstallDate = $Result.InstallDate
        #     $output.LastBootUpTime = $Result.LastBootUpTime
        #     $output.LocalDateTime = $Result.LocalDateTime
        #     $output.MUILanguages = $Result.MUILanguages
        #     $output.OSArchitecture = $Result.OSArchitecture
        #     $output.OSProductSuite = $Result.OSProductSuite
        #     $output.OSType = $Result.OSType
        #     $output.OperatingSystemSKU = $Result.OperatingSystemSKU
        #     $output.Organization = $Result.Organization
        #     $output.OtherTypeDescription = $Result.OtherTypeDescription
        #     $output.PortableOperatingSystem = $Result.PortableOperatingSystem
        #     $output.ProductType = $Result.ProductType
        #     $output.RegisteredUser = $Result.RegisteredUser
        #     $output.ServicePackMajorVersion = $Result.ServicePackMajorVersion
        #     $output.ServicePackMinorVersion = $Result.ServicePackMinorVersion
        #     $output.Status = $Result.Status
        #     $output.SuiteMask = $Result.SuiteMask
        #     $output.SystemDevice = $Result.SystemDevice
        #     $output.SystemDirectory = $Result.SystemDirectory
        #     $output.SystemDrive = $Result.SystemDrive
        #     $output.Version = $Result.Version
        #     $output.WindowsDirectory = $Result.WindowsDirectory

        #     # Win32_ComputerSystem
        #     $output.AdminPasswordStatus = $Result.AdminPasswordStatus
        #     $output.BootROMSupported = $Result.BootROMSupported
        #     $output.BootupState = $Result.BootupState
        #     $output.ChassisBootupState = $Result.ChassisBootupState
        #     $output.DNSHostName = $Result.DNSHostName
        #     $output.DaylightInEffect = $Result.DaylightInEffect
        #     $output.Description = $Result.ComputerSystemDescription
        #     $output.Domain = $Result.Domain
        #     $output.DomainRole = $Result.DomainRole
        #     $output.EnableDaylightSavingsTime = $Result.EnableDaylightSavingsTime
        #     $output.HypervisorPresent = $Result.HypervisorPresent
        #     $output.Manufacturer = $Result.ComputerSystemManufacturer
        #     $output.Model = $Result.Model
        #     $output.NetworkServerModeEnabled = $Result.NetworkServerModeEnabled
        #     $output.PrimaryOwnerContact = $Result.PrimaryOwnerContact
        #     $output.PrimaryOwnerName = $Result.PrimaryOwnerName
        #     $output.SupportContactDescription = $Result.SupportContactDescription
        #     $output.SystemSKUNumber = $Result.SystemSKUNumber
        #     $output.ThermalState = $Result.ThermalState
        #     $output.UserName = $Result.UserName

        #     # Win32_BIOS
        #     $output.BIOSVersion = $Result.BIOSVersion
        #     try {$output.BIOSInstallDate = $Result.BIOSInstallDate} catch{}
        #     $output.BIOSManufacturer = $Result.Manufacturer
        #     $output.PrimaryBIOS = $Result.PrimaryBIOS
        #     $output.BIOSReleaseDate = $Result.ReleaseDate
        #     $output.SMBIOSBIOSVersion = $Result.SMBIOSBIOSVersion
        #     $output.SMBIOSMajorVersion = $Result.SMBIOSMajorVersion
        #     $output.SMBIOSMinorVersion = $Result.SMBIOSMinorVersion
        #     $output.SMBIOSPresent = $Result.SMBIOSPresent
        #     $output.SerialNumber = $Result.SerialNumber
        #     $output.SystemBiosMajorVersion = $Result.SystemBiosMajorVersion
        #     $output.SystemBiosMinorVersion = $Result.SystemBiosMinorVersion

        #     # Win32_Processor
        #     $output.VirtualizationFirmwareEnabled = $Result.VirtualizationFirmwareEnabled

        #     $total++
        #     return $output 
        # }
        # else {
                
        #     $output = $null
        #     $output = [Computer]::new()

        #     $output.Computer = $Computer
        #     $output.DateScanned = Get-Date -Format o
            
        #     $total++
        #     return $output
        # }
    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}