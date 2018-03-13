function Get-THR_Services {
    <#
    .SYNOPSIS 
        Queries the services on a given hostname, FQDN, or IP address.

    .DESCRIPTION 
        Queries the services on a given hostname, FQDN, or IP address.

    .PARAMETER Computer  
        Queries the services on a given hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Services 
        Get-THR_Services SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Services
        Get-THR_Services $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Services

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
        https://attack.mitre.org/wiki/Technique/T1031
        https://attack.mitre.org/wiki/Technique/T1050
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $DateScanned = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class Service {
			[String] $Computer
            [Datetime] $DateScanned
            
            [bool] $AcceptPause
            [bool] $AcceptStop
            [string] $Caption
            [uint32] $CheckPoint
            [bool] $DelayedAutoStart
            [string] $Description
            [bool] $DesktopInteract
            [uint32] $DisconnectedSessions
            [string] $DisplayName
            [string] $ErrorControl
            [uint32] $ExitCode
            [datetime] $InstallDate
            [string] $Name
            [string] $PathName
            [uint32] $ProcessId
            [uint32] $ServiceSpecificExitCode
            [string] $ServiceType
            [bool] $Started
            [string] $StartMode
            [string] $StartName
            [string] $State
            [string] $SystemName
            [uint32] $TagId
            [uint32] $TotalSessions
            [uint32] $WaitHint
		}
	}

    process{        
                
        $Computer = $Computer.Replace('"', '')

        Write-Verbose ("{0}: Querying remote system" -f $Computer) 
        $Services = Get-CIMinstance -class Win32_Service -Filter "Caption LIKE '%'" -ComputerName $Computer -ErrorAction SilentlyContinue
        # Odd filter explanation: http://itknowledgeexchange.techtarget.com/powershell/cim-session-oddity/

        if ($Services){
                
            $Services | ForEach-Object {
                
				$output = $null
				$output = [Service]::new()
				
				$output.Computer = $Computer
				$output.DateScanned = Get-Date -Format u
                
				$output.AcceptPause = $_.AcceptPause
                $output.AcceptStop = $_.AcceptStop
                $output.Caption = $_.Caption
                $output.CheckPoint = $_.CheckPoint
                $output.DelayedAutoStart = $_.DelayedAutoStart
                $output.DESCRIPTION = $_.DESCRIPTION
                $output.DesktopInteract = $_.DesktopInteract
                $output.DisconnectedSessions = $_.DisconnectedSessions
                $output.DisplayName = $_.DisplayName
                $output.ErrorControl = $_.ErrorControl
                $output.ExitCode = $_.ExitCode
                if ($_.InstallDate) {
                    $output.InstallDate = $_.InstallDate
                }
                $output.Name = $_.Name
                $output.PathName = $_.PathName
                $output.ProcessId = $_.ProcessId
                $output.ServiceSpecificExitCode = $_.ServiceSpecificExitCode
                $output.ServiceType = $_.ServiceType
                $output.Started = $_.Started
                $output.StartMode = $_.StartMode
                $output.StartName = $_.StartName
                $output.State = $_.State
                $output.SystemName = $_.SystemName
                $output.TagId = $_.TagId
                $output.TotalSessions = $_.TotalSessions
                $output.WaitHint = $_.WaitHint
                    
                $total++
                return $output 
            }
        }
        else {
                
            $output = $null
            $output = [Service]::new()

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