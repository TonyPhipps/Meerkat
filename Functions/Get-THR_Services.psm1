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
        Updated: 2018-08-05

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
        https://github.com/TonyPhipps/THRecon/wiki/Services
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class Service {
			[String] $Computer
            [string] $DateScanned
            
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
        
        $Command = {
            Get-CIMinstance -class Win32_Service -Filter "Caption LIKE '%'"
            # Odd filter explanation: http://itknowledgeexchange.techtarget.com/powershell/cim-session-oddity/
        }
	}

    process{        
                
        $Computer = $Computer.Replace('"', '')

        Write-Verbose ("{0}: Querying remote system" -f $Computer)

        if ($Computer -eq $env:COMPUTERNAME){
            
            $ResultsArray = & $Command 
        } 
        else {

            $ResultsArray = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock $Command
        }
        

        if ($ResultsArray){
                
            $OutputArray = foreach($Entry in $ResultsArray) {
                
				$output = $null
				$output = [Service]::new()
				
				$output.Computer = $Computer
				$output.DateScanned = Get-Date -Format o
                
				$output.AcceptPause = $Entry.AcceptPause
                $output.AcceptStop = $Entry.AcceptStop
                $output.Caption = $Entry.Caption
                $output.CheckPoint = $Entry.CheckPoint
                $output.DelayedAutoStart = $Entry.DelayedAutoStart
                $output.DESCRIPTION = $Entry.DESCRIPTION
                $output.DesktopInteract = $Entry.DesktopInteract
                $output.DisconnectedSessions = $Entry.DisconnectedSessions
                $output.DisplayName = $Entry.DisplayName
                $output.ErrorControl = $Entry.ErrorControl
                $output.ExitCode = $Entry.ExitCode
                if ($Entry.InstallDate) {
                    $output.InstallDate = $Entry.InstallDate
                }
                $output.Name = $Entry.Name
                $output.PathName = $Entry.PathName
                $output.ProcessId = $Entry.ProcessId
                $output.ServiceSpecificExitCode = $Entry.ServiceSpecificExitCode
                $output.ServiceType = $Entry.ServiceType
                $output.Started = $Entry.Started
                $output.StartMode = $Entry.StartMode
                $output.StartName = $Entry.StartName
                $output.State = $Entry.State
                $output.SystemName = $Entry.SystemName
                $output.TagId = $Entry.TagId
                $output.TotalSessions = $Entry.TotalSessions
                $output.WaitHint = $Entry.WaitHint
                    
                $output 
            }

            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [Service]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format o
            
            $total++
            return $output
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}