function Get-THR_SCCM_Computer {
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
        Get-THR_SCCM_Computer 
        Get-THR_SCCM_Computer SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_SCCM_Computer
        Get-THR_SCCM_Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_SCCM_Computer

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
        $Computer = $env:COMPUTERNAME,
        
        [Parameter()]
        $SiteName="A1",

        [Parameter()]
        $SCCMServer="server.domain.com",

        [Parameter()]
        [switch]$CIM
    )

	begin{
        $SCCMNameSpace="root\sms\site_$SiteName"

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        
        class SCCMComputer {
            [String] $Computer
            [DateTime] $DateScanned
            
            [String] $Domain
            [String] $DistinguishedName
            [String] $ResourceNames
            [String] $IsVirtualMachine
            [String] $LastLogonTimestamp
            [String] $LastLogonUserDomain
            [String] $LastLogonUserName
            [String] $IPAddress
            [String] $IPSubnet
            [String] $MACAddress
            [String] $ResourceID
            [String] $CPUType
            [String] $LastSCCMHeartBeat
            [String] $OperatingSystemNameandVersion
            [String] $Manufacturer
            [String] $Model
            [String] $SystemType
            [String] $UserName
            [String] $CurrentTimeZone
            [String] $DomainRole
            [String] $NumberOfProcessors
            [String] $TimeStamp
            [String] $SerialNumber
            [String] $ChassisTypes
            [String] $BIOSManufacturer
            [String] $BIOSName
            [String] $BIOSVersion
            [String] $BIOSReleaseDate
            [String] $InstallDate
            [String] $LastBootUpTime
            [String] $Caption
            [String] $CSDVersion
        }
	}

    process{        
                
        if ($Computer -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){ # is this an IP address?
            $fqdn = [System.Net.Dns]::GetHostByAddress($Computer).Hostname
            $ThisComputer = $fqdn.Split(".")[0]
        }
        
        else{ # Convert any FQDN into just hostname
            $ThisComputer = $Computer.Split(".")[0].Replace('"', '')
        }

        if ($CIM){
            
            $SMS_R_System = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames, IPAddresses, IPSubnets, AgentTime, ResourceID, CPUType, DistinguishedName from SMS_R_System where name='$ThisComputer'"
            
            if ($SMS_R_System) {
                $ResourceID = $SMS_R_System.ResourceID # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
                $SMS_G_System_Computer_System = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Model, Domain, SystemType, UserName, CurrentTimeZone, DomainRole, NumberOfProcessors, TimeStamp from SMS_G_System_Computer_System where ResourceID='$ResourceID'"
                $SMS_G_System_SYSTEM_ENCLOSURE = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, SerialNumber, ChassisTypes from SMS_G_System_SYSTEM_ENCLOSURE where ResourceID='$ResourceID'"
                $SMS_G_System_PC_BIOS = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Name, SMBIOSBIOSVersion, ReleaseDate from SMS_G_System_PC_BIOS where ResourceID='$ResourceID'"
                $SMS_G_System_OPERATING_SYSTEM = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select InstallDate, LastBootUpTime, Caption, CSDVersion from SMS_G_System_OPERATING_SYSTEM where ResourceID='$ResourceID'"
            }
        }
            
        else{
            
            $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select IsVirtualMachine, LastLogonTimestamp, LastLogonUserDomain, LastLogonUserName, MACAddresses, OperatingSystemNameandVersion, ResourceNames, IPAddresses, IPSubnets, AgentTime, ResourceID, CPUType, DistinguishedName from SMS_R_System where name='$ThisComputer'"
            
            if ($SMS_R_System) {
                $ResourceID = $SMS_R_System.ResourceID # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
                $SMS_G_System_Computer_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Model, Domain, SystemType, UserName, CurrentTimeZone, DomainRole, NumberOfProcessors, TimeStamp from SMS_G_System_Computer_System where ResourceID='$ResourceID'"
                $SMS_G_System_SYSTEM_ENCLOSURE = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, SerialNumber, ChassisTypes from SMS_G_System_SYSTEM_ENCLOSURE where ResourceID='$ResourceID'"
                $SMS_G_System_PC_BIOS = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceID, Manufacturer, Name, SMBIOSBIOSVersion, ReleaseDate from SMS_G_System_PC_BIOS where ResourceID='$ResourceID'"
                $SMS_G_System_OPERATING_SYSTEM = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select InstallDate, LastBootUpTime, Caption, CSDVersion from SMS_G_System_OPERATING_SYSTEM where ResourceID='$ResourceID'"
            }
        }
            
        
        $output = $null
		$output = [SCCMComputer]::new()
   
        $output.Computer = $Computer
        $output.DateScanned = Get-Date -Format u
            
        if ($SMS_R_System){
            
            $output.Domain = $SMS_G_System_Computer_System.Domain
            $output.DistinguishedName = $SMS_R_System.DistinguishedName
            $output.ResourceNames = $SMS_R_System.ResourceNames[0]
            $output.IsVirtualMachine = $SMS_R_System.IsVirtualMachine
            $output.LastLogonTimestamp = $SMS_R_System.LastLogonTimestamp
            $output.LastLogonUserDomain = $SMS_R_System.LastLogonUserDomain
            $output.LastLogonUserName = $SMS_R_System.LastLogonUserName
            $output.IPAddress = ($SMS_R_System.IPAddresses -join " ").Split(" ")[0]
            $output.IPSubnet = ($SMS_R_System.IPSubnets -join " ").Split(" ")[0]
            $output.MACAddress = ($SMS_R_System.MACAddresses -join " ").Split(" ")[0]
            $output.ResourceID = $SMS_R_System.ResourceID
            $output.CPUType = $SMS_R_System.CPUType
            if ($SMS_R_System.AgentTime[3]) { # Sometimes fails
                $output.LastSCCMHeartBeat = $SMS_R_System.AgentTime[3]
            }
            $output.OperatingSystemNameandVersion = $SMS_R_System.OperatingSystemNameandVersion

            if ($SMS_G_System_Computer_System){
            
                $output.Manufacturer = $SMS_G_System_Computer_System.Manufacturer
                $output.Model = $SMS_G_System_Computer_System.Model
                $output.SystemType = $SMS_G_System_Computer_System.SystemType
                $output.UserName = $SMS_G_System_Computer_System.UserName
                $output.CurrentTimeZone = $SMS_G_System_Computer_System.CurrentTimeZone
                $output.DomainRole = $SMS_G_System_Computer_System.DomainRole
                $output.NumberOfProcessors = $SMS_G_System_Computer_System.NumberOfProcessors
                $output.TimeStamp = $SMS_G_System_Computer_System.TimeStamp
            } 

            if ($SMS_G_System_SYSTEM_ENCLOSURE){
            
                $output.SerialNumber = $SMS_G_System_SYSTEM_ENCLOSURE.SerialNumber
                $output.ChassisTypes = $SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes
            }

            if ($SMS_G_System_PC_BIOS){
            
                $output.BIOSManufacturer = $SMS_G_System_PC_BIOS.Manufacturer
                $output.BIOSName = $SMS_G_System_PC_BIOS.Name
                $output.BIOSVersion = $SMS_G_System_PC_BIOS.SMBIOSBIOSVersion
                $output.BIOSReleaseDate = $SMS_G_System_PC_BIOS.ReleaseDate
            }

            if ($SMS_G_System_OPERATING_SYSTEM){
            
                $output.InstallDate = $SMS_G_System_OPERATING_SYSTEM.InstallDate
                $output.LastBootUpTime = $SMS_G_System_OPERATING_SYSTEM.LastBootUpTime
                $output.Caption = $SMS_G_System_OPERATING_SYSTEM.Caption
                $output.CSDVersion = $SMS_G_System_OPERATING_SYSTEM.CSDVersion
            }
            

            $elapsed = $stopwatch.Elapsed
            $total = $total+1
            

            Write-Verbose -Message "System $total `t $ThisComputer `t Time Elapsed: $elapsed"

            return $output
        
        }

        else { # System was not reachable

            if ($Fails) { # -Fails switch was used
                Add-Content -Path $Fails -Value ("$Computer")
            }

            else{ # -Fails switch not used
                            
                $output = $null
                $output = [SCCMComputer]::new()
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $total = $total+1
                return $output
            }
        }

    }

    end{
        $elapsed = $stopwatch.Elapsed
        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed"
	}
}


