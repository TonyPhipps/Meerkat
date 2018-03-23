function Get-THR_SCCM_EnvVars {
    <#
    .SYNOPSIS 
        Queries SCCM for a given hostname, FQDN, or IP address.

    .DESCRIPTION 
        Queries SCCM for a given hostname, FQDN, or IP address. 
        !!WARNING: Long VariableValues vay be truncated using SCCM as a source!!

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
        Get-THR_SCCM_EnvVars 
        Get-THR_SCCM_EnvVars SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_SCCM_EnvVars
        Get-THR_SCCM_EnvVars $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_SCCM_EnvVars

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

        class Environment {
            [String] $Computer
            [DateTime] $DateScanned
            [String] $ResourceNames
            [String] $Username
            [String] $SystemVariable
            [String] $VariableValue
            [String] $Caption
            [String] $Description
            [String] $Timestamp
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

            $SMS_R_System = $Null
            $SMS_R_System = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceNames, ResourceID from SMS_R_System where name='$ThisComputer'"
            
            if ($SMS_R_System) {
                $ResourceID = $SMS_R_System.ResourceID # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
                $SMS_G_System_ENVIRONMENT = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select Name, VariableValue, SystemVariable, Username, Timestamp, Caption, Description from SMS_G_System_ENVIRONMENT where ResourceID='$ResourceID'"
            }
        }
        else{

            $SMS_R_System = $Null
            $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceNames, ResourceID from SMS_R_System where name='$ThisComputer'"
            
            if ($SMS_R_System) {
                
                $ResourceID = $SMS_R_System.ResourceID # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
                $SMS_G_System_ENVIRONMENT = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select Name, VariableValue, SystemVariable, Username, Timestamp, Caption, Description from SMS_G_System_ENVIRONMENT where ResourceID='$ResourceID'"
            }
        }

        if ($SMS_G_System_ENVIRONMENT){
                
            $SMS_G_System_ENVIRONMENT | ForEach-Object {
                
                $output = $null
                $output = [Environment]::new()
   
                $output.Computer = $ThisComputer
                $output.DateScanned = Get-Date -Format u

                $output.ResourceNames = $SMS_R_System.ResourceNames[0]
                $output.VariableValue = $_.VariableValue # "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" contains remainder of values above 255 characters!
                $output.SystemVariable = $_.SystemVariable
                $output.Username = $_.Username
                $output.Timestamp = $_.Timestamp
                    
                if ($_.Caption.Split("\")[2]){ # These values have variable \'s present until the relevant content.
                    $output.Caption = $_.Caption.Split("\")[2]
                    $output.DESCRIPTION = $_.DESCRIPTION.Split("\")[2]
                }
                else{
                    $output.Caption = $_.Caption.Split("\")[1]
                    $output.DESCRIPTION = $_.DESCRIPTION.Split("\")[1]
                }


                return $output
            
            }
        }
        else {

            $output = $null
            $output = [Environment]::new()
            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format u
            
            $elapsed = $stopwatch.Elapsed
            $total = $total+1
           
            return $output
        }
    }

    end{
        $elapsed = $stopwatch.Elapsed
        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed"
    }
}
