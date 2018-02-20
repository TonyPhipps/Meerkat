function Get-THR_Ports {
    <#
    .SYNOPSIS
        Gets the active ports for the given computer(s).

    .DESCRIPTION
        Gets the active ports for the given computer(s) and returns a PS Object.

    .PARAMETER Computer
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Path
        Resolve owning PID to process path. Increases hunt time per system.       

    .PARAMETER Fails
        Provide a path to save failed systems to.

    .EXAMPLE
        Get-THR_Ports 
        Get-THR_Ports SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Ports
        Get-THR_Ports -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Ports

    .NOTES
        Updated: 2018-02-19

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
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $total = 0

        class TCPConnection
        {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $LocalAddress
            [String] $LocalPort
            [String] $RemoteAddress
            [String] $RemotePort
            [String] $State
            [String] $AppliedSetting
            [String] $OwningProcessID
            [String] $OwningProcessPath
        }
	}

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present
        
        $TCPConnections = $null
        $TCPConnections = Invoke-Command -ComputerName $Computer -ScriptBlock {
            $TCPConnections = Get-NetTCPConnection -State Listen, Established
        
            foreach ($TCPConnection in $TCPConnections){
                $TCPConnection | Add-Member -MemberType NoteProperty -Name Path -Value ((Get-Process -Id $TCPConnection.OwningProcess).Path)
            }

            return $TCPConnections
        }
        
        if ($TCPConnections) {

            Write-Verbose ("{0}: Parsing results." -f $Computer)
            $OutputArray = @()
          
            foreach ($TCPConnection in $TCPConnections) {

                $output = $null
                $output = [TCPConnection]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u
                
                $output.LocalAddress = $TCPConnection.LocalAddress
                $output.LocalPort = $TCPConnection.LocalPort
                $output.RemoteAddress = $TCPConnection.RemoteAddress
                $output.RemotePort = $TCPConnection.RemotePort
                $output.State = $TCPConnection.State
                $output.AppliedSetting = $TCPConnection.AppliedSetting
                $output.OwningProcessID = $TCPConnection.OwningProcess
                $output.OwningProcessPath = $TCPConnection.Path
                
                $OutputArray += $output
            }
        
            $total++
            return $OutputArray
        }        
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $Result = $null
            $Result = [TCPConnection]::new()

            $Result.Computer = $Computer
            $Result.DateScanned = $DateScanned
            
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