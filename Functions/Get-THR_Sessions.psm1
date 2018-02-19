function Get-THR_Sessions {
    <#
    .SYNOPSIS 
        Gets the login sessions for the given computer(s).

    .DESCRIPTION 
        Gets the login sessions for the given computer(s) utizling the builtin "qwinsta.exe" tool.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Fails  
        Provide a path to save failed systems to.

    .EXAMPLE 
        Get-THR_Sessions 
        Get-THR_Sessions SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Sessions
        Get-THR_Sessions -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Sessions

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
        $Fails
    )

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Verbose ("Started at {0}" -f $datetime)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $total = 0

        class LoginSession {
            [string] $Computer
            [Datetime] $DateScanned  

            [String] $SessionName
            [String] $UserName
            [String] $Id
            [String] $State
            [String] $Type
            [String] $Device
        }
    }

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present
        
        Write-Verbose ("{0}: Querying remote system" -f $Computer) 
        $sessions = $null
        $sessions = (qwinsta /server:$Computer 2> $null | Foreach-Object { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv)
       
        if ($sessions) { 
            
            $OutputArray = @()

            Write-Verbose ("{0}: Looping through retrived results" -f $Computer)
            foreach ($session in $sessions) {
             
                $output = $null
                $output = [LoginSession]::new()
                
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $output.SessionName = $session.SESSIONNAME
                
                if ($session.STATE -eq $null) {
                    $output.Id = $session.USERNAME
                    $output.State = $session.ID
                    $output.Type = $session.STATE
                }
                else {
                    $output.UserName = $session.USERNAME
                    $output.Id = $session.ID
                    $output.State = $session.STATE
                    $output.Type = $session.TYPE
                    $output.Device = $session.DEVICE
                }

                $OutputArray += $output
            }

            $elapsed = $stopwatch.Elapsed
            $total = $total + 1
            
            Write-Verbose ("System {0} complete: `t {1} `t Total Time Elapsed: {2}" -f $total, $Computer, $elapsed)

            $total = $total+1
            Return $OutputArray
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            if ($Fails) {
                
                $total++
                Add-Content -Path $Fails -Value ("$Computer")
            }
            else {
                
                $output = $null
                $output = [LoginSession]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u
                
                $total++
                return $output
            }
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}