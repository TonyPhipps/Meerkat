function Get-THR_TCPConnections {
    <#
    .SYNOPSIS
        Gets the active TCP connections for the given computer(s).

    .DESCRIPTION
        Gets the active TCP connections for the given computer(s).

    .PARAMETER Computer
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE
        Get-THR_TCPConnections 
        Get-THR_TCPConnections SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_TCPConnections
        Get-THR_TCPConnections -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_TCPConnections

    .NOTES
        Updated: 2018-08-05

        Contributing Authors:
            Jeremy Arnold
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
        https://github.com/TonyPhipps/THRecon/wiki/TCPConnections
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

        class TCPConnection
        {
            [String] $Computer
            [string] $DateScanned

            [String] $LocalAddress
            [String] $LocalPort
            [String] $RemoteAddress
            [String] $RemotePort
            [String] $State
            [String] $AppliedSetting
            [String] $OwningProcessID
            [String] $OwningProcessPath
        }

        $Command = {
            $TCPConnectionArray = Get-NetTCPConnection -State Listen, Established
        
            foreach ($TCPConnection in $TCPConnectionArray){
                $TCPConnection | Add-Member -MemberType NoteProperty -Name Path -Value ((Get-Process -Id $TCPConnection.OwningProcess).Path)
            }

            return $TCPConnectionArray
        }
	}

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present
        
        Write-Verbose ("{0}: Querying remote system" -f $Computer)

        if ($Computer -eq $env:COMPUTERNAME){
            
            $ResultsArray = & $Command 
        } 
        else {

            $ResultsArray = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock $Command
        }
        
        if ($ResultsArray) {

            $OutputArray = foreach ($TCPConnection in $ResultsArray) {

                $output = $null
                $output = [TCPConnection]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format o
                
                $output.LocalAddress = $TCPConnection.LocalAddress
                $output.LocalPort = $TCPConnection.LocalPort
                $output.RemoteAddress = $TCPConnection.RemoteAddress
                $output.RemotePort = $TCPConnection.RemotePort
                $output.State = $TCPConnection.State
                $output.AppliedSetting = $TCPConnection.AppliedSetting
                $output.OwningProcessID = $TCPConnection.OwningProcess
                $output.OwningProcessPath = $TCPConnection.Path
                
                $output
            }
        
            $total++
            return $OutputArray
        }        
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $Result = $null
            $Result = [TCPConnection]::new()

            $Result.Computer = $Computer
            $Result.DateScanned = Get-Date -Format u
            
            $total++
            return $Result
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Started at {0}" -f $DateScanned)
        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}