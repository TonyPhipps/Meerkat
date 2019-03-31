function Get-THR_Hosts {
    <#
    .SYNOPSIS 
        Gets the host file entries.

    .DESCRIPTION 
        Gets the host file entries.

    .EXAMPLE 
        Get-THR_Hosts

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-THR_Hosts} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation "c:\temp\$Target_Hosts.csv"
        }

    .NOTES 
        Updated: 2019-03-30

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2019
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
    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
	}

    process{
            
        $Hosts = Join-Path -Path $($env:windir) -ChildPath "system32\drivers\etc\hosts"

        [regex]$nonwhitespace = "\S"

        $HostsArray = Get-Content $Hosts | 
            Where-Object { (($nonwhitespace.Match($_)).value -ne "#") -and ($_ -notmatch "^\s+$") -and ($_.Length -gt 0) } # exlcude full-line comments and blank lines

        if ($HostsArray){

            $ResultsArray = foreach($Entry in $HostsArray) {

                $Entry -match "(?<IP>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(?<HOSTNAME>\S+)" | Out-Null

                $IP = $matches.IP
                $HostName = $matches.HostName

                if ($Entry.contains("#")) {
                    
                    $Comment = $Entry.substring($Entry.indexof("#")+1)
                }

                $ParsedEntry = $null
                    $ParsedEntry = [PSCustomObject] @{
                        IP = $IP
                        HostName = $HostName
                        Comment = $Comment 
                    }

                    $ParsedEntry
            }

            return $ResultsArray
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}