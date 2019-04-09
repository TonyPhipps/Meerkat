function Get-THR_NetRoute {
    <#
    .SYNOPSIS 
        Gets a list of IPv4 Routes on a given system.

    .DESCRIPTION 
        Gets a list of IPv4 Routes on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_NetRoute 
        Get-THR_NetRoute SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_NetRoute
        Hunt-Get-THR_NetRoute $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-Get-THR_NetRoute

    .NOTES 
        Updated: 2018-08-05

        Contributing Authors:
            Jeremy Arnold
            
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

    [CmdletBinding()]
    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started Get-THR_NetRoute at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        Enum RouteType {
            AdminDefinedRoute = 2
            ComputedRoute = 3
            ActualRoute = 4        
        }

        class Route
        {
            [String] $Computer
            [string] $DateScanned

            [String] $InterfaceIndex
            [String] $InterfaceName
            [String] $DestinationPrefix
            [String] $NextHop
            [String] $Metric
            [String] $Protocol
            [String] $Store
            [String] $PublishedRoute
            [RouteType] $TypeOfRoute
        }

        $Command = {

            Enum RouteType {
                AdminDefinedRoute = 2
                ComputedRoute = 3
                ActualRoute = 4        
            }
            
            $InterfaceArray = $null
            $InterfaceArray = Get-NetAdapter | Where-Object {$_.MediaConnectionState -eq "Connected"}
            
            $RouteArray = foreach ($Interface in $InterfaceArray) {
                                
                Get-NetRoute -AddressFamily IPv4 -InterfaceIndex $Interface.ifIndex -IncludeAllCompartments
            }

            return $RouteArray        
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
            
            $OutputArray = foreach ($route in $ResultsArray) {
                
                $output = $null
                $output = [Route]::new()
    
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format o
    
                $output.InterfaceIndex = $route.ifIndex
                $output.InterfaceName= $route.interfaceAlias
                $output.DestinationPrefix = $route.DestinationPrefix
                $output.NextHop = $route.NextHop
                $output.Metric = $route.RouteMetric
                $output.Protocol = $route.Protocol
                $output.Store = $route.Store
                $output.PublishedRoute = $route.Publish
                $output.TypeOfRoute = $route.TypeOfRoute

                $output
            }

            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [Route]::new()

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