function Get-THR_Sessions {
    <#
    .SYNOPSIS 
        Gets the login sessions for the given computer(s).

    .DESCRIPTION 
        Gets the login sessions for the given computer(s) utizling the builtin "qwinsta.exe" tool.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Sessions 
        Get-THR_Sessions SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Sessions
        Get-THR_Sessions -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Sessions

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

        class LoginSession {
            [string] $Computer
            [string] $DateScanned  

            [String] $SessionName
            [String] $UserName
            [String] $Id
            [String] $State
            [String] $Type
            [String] $Device
        }

        $Command = {
            qwinsta /server:$Computer 2> $null | Foreach-Object { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv
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
            
            $OutputArray = foreach ($Session in $ResultsArray) {
             
                $output = $null
                $output = [LoginSession]::new()
                
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format o

                $output.SessionName = $Session.SESSIONNAME
                
                if ($Session.State -eq $null) {
                    $output.Id = $Session.USERNAME
                    $output.State = $Session.ID
                    $output.Type = $Session.STATE
                }
                else {
                    $output.UserName = $Session.USERNAME
                    $output.Id = $Session.ID
                    $output.State = $Session.STATE
                    $output.Type = $Session.TYPE
                    $output.Device = $Session.DEVICE
                }

                $output
            }

            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [LoginSession]::new()

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