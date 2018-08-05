function Get-THR_NetAdapters {
    <#
    .SYNOPSIS 
        Gets the Interface(s) settings for the given computer(s).

    .DESCRIPTION 
        Gets the Interface(s) settings for the given computer(s) and returns a PS Object.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_NetAdapters 
        Get-THR_NetAdapters SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_NetAdapters
        Get-THR_NetAdapters -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_NetAdapters

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

        class NetAdapter
        {
            [String] $Computer
            [string] $DateScanned
            
            [String] $FQDN
            [String] $Description
            [String] $NetConnectionID
            [String] $NetConnected
            [String] $InterfaceIndex
            [String] $Speed
            [String] $MACAddress
            [String] $IPAddress
            [String] $Subnet
            [String] $Gateway
            [String] $DNS
            [String] $MTU
            [bool] $PromiscuousMode
        }
        
        $Command = {

            $AdaptersArray = Get-NetAdapter -ErrorAction SilentlyContinue
            $AdapterConfigArray = Get-CimInstance Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue  #get the configuration for the current adapter

            $AdaptersArray = $AdaptersArray | Where-Object {$_.MediaConnectionState -eq "Connected"}
            
            foreach ($Adapter in $AdaptersArray) {
                
                $AdapterConfig = $AdapterConfigArray | Where-Object {$_.InterfaceIndex -eq $Adapter.IfIndex}

                $Adapter | Add-Member -MemberType NoteProperty -Name ipaddress -Value $AdapterConfig.ipaddress[0]
                $Adapter | Add-Member -MemberType NoteProperty -Name IPsubnet -Value $AdapterConfig.IPsubnet[0]
                $Adapter | Add-Member -MemberType NoteProperty -Name DefaultIPGateway -Value $AdapterConfig.DefaultIPGateway
                $Adapter | Add-Member -MemberType NoteProperty -Name DNSServerSearchOrder -Value $AdapterConfig.DNSServerSearchOrder                
            }

            return $AdaptersArray
        } 
	}

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present get-netadapter

        Write-Verbose ("{0}: Querying remote system" -f $Computer)

        if ($Computer -eq $env:COMPUTERNAME){
            
            $ResultsArray = & $Command 
        } 
        else {

            $ResultsArray = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock $Command
        }
        
        if ($ResultsArray) {

            
            $OutputArray = foreach ($Adapter in $ResultsArray) {#loop through the Interfaces and build the outputArray
                
                $output = $null
                $output = [NetAdapter]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format o
                $output.FQDN = $Adapter.SystemName
                $output.DESCRIPTION = $Adapter.InterfaceDescription
                $output.NetConnectionID = $Adapter.Name
                $output.NetConnected= $Adapter.MediaConnectionState
                $output.InterfaceIndex = $Adapter.ifIndex
                $output.Speed = $Adapter.Speed
                $output.MACAddress = $Adapter.MACAddress
                $output.IPAddress = $Adapter.ipaddress
                $output.Subnet = $Adapter.IPsubnet
                $output.Gateway = $Adapter.DefaultIPGateway
                $output.DNS = $Adapter.DNSServerSearchOrder
                $output.MTU = $Adapter.MtuSize
                $output.PromiscuousMode = $Adapter.PromiscuousMode

                $output
            }

            $total++
            Return $OutputArray
        }
        else {
                
            $output = $null
            $output = [NetAdapter]::new()

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