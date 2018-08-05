function Get-THR_ARP {
    <#
    .SYNOPSIS 
        Gets the arp cache for the given computer(s).

    .DESCRIPTION 
        Gets the arp cache from all connected interfaces for the given computer(s).

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_ARP 
        Get-THR_ARP  SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_ARP
        Get-THR_ARP -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_ARP

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

        class ArpCache
        {
            [string] $Computer
            [string] $DateScanned

            [String] $IfIndex
            [string] $InterfaceAlias
            [String] $IPAdress
            [String] $LinkLayerAddress
            [String] $State
            [String] $PolicyStore
        }

        $Command = {
            Get-NetNeighbor | 
            Where-Object {($_.LINKLayerAddress -ne "") -and
                ($_.LINKLayerAddress -ne "FF-FF-FF-FF-FF-FF") -and # Broadcast. Filtered by LinkLayerAddress rather than "$_.State -ne "permanent" to maintain manual entries
                ($_.LINKLayerAddress -notlike "01-00-5E-*") -and   # IPv4 multicast
                ($_.LINKLayerAddress -notlike "33-33-*")           # IPv6 multicast
            }
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

            Write-Verbose ("{0}: Parsing results." -f $Computer)
            
            $OutputArray = foreach ($record in $ResultsArray) {
             
                $output = $null
                $output = [ArpCache]::new()
        
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format o
                
                $output.IfIndex = $record.ifIndex
                $output.InterfaceAlias = $record.InterfaceAlias
                $output.IPAdress = $record.IPAddress
                $output.LINKLayerAddress = $record.LINKLayerAddress
                $output.State = $record.State
                $output.PolicyStore = $record.Store                 

                $output
            }

            $total++
            return $OutputArray

        }
        else {
                
            $output = $null
            $output = [ArpCache]::new()

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