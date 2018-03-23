function Get-THR_Hosts {
    <#
    .SYNOPSIS 
        Gets the arp cache for the given computer(s).

    .DESCRIPTION 
        Gets the arp cache from all connected interfaces for the given computer(s).

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Hosts 
        Get-THR_Hosts  SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Hosts
        Get-THR_Hosts -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Hosts

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
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $total = 0

        class Entry
        {
            [string] $Computer
            [Datetime] $DateScanned

            [String] $HostsIP
            [string] $HostsName
            [String] $HostsComment
        }
	}

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $HostsData = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock {
            $Hosts = Join-Path -Path $($env:windir) -ChildPath "system32\drivers\etc\hosts"

            [regex]$nonwhitespace = "\S"

            Get-Content $Hosts | Where-Object {
                (($nonwhitespace.Match($_)).value -ne "#") -and ($_ -notmatch "^\s+$") -and ($_.Length -gt 0) # exlcude full-line comments and blank lines
            }
        }

        if ($HostsData){

            $OutputArray = @()

            Write-Verbose ("{0}: Parsing results." -f $Computer)
            $HostsData | ForEach-Object {

                $ip = $null
                $hostname = $null
                $comment = $null

                $_ -match "(?<IP>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(?<HOSTNAME>\S+)" | Out-Null

                $ip = $matches.ip
                $hostname = $matches.hostname

                if ($_.contains("#")) {
                    
                    $comment = $_.substring($_.indexof("#")+1)
                }

                $output = $null
                $output = [Entry]::new()
        
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u
                
                $output.HostsIP = $ip
                $output.HostsName = $hostname
                $output.HostsComment = $comment

                $OutputArray += $output
            }

            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [Entry]::new()

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