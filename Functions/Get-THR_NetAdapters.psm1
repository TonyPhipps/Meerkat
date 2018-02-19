function Get-THR_NetAdapters {
    <#
    .SYNOPSIS 
        Gets the Interface(s) settings for the given computer(s).

    .DESCRIPTION 
        Gets the Interface(s) settings for the given computer(s) and returns a PS Object.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Fails  
        Provide a path to save failed systems to.

    .EXAMPLE 
        Get-THR_NetAdapters 
        Get-THR_NetAdapters SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_NetAdapters
        Get-THR_NetAdapters -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_NetAdapters

    .NOTES 
        Updated: 2018-02-07

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

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        
        [Parameter()]
        $Fails
    )

	begin{

        $datetime = Get-Date -Format u
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $total = 0

        class NetAdapter
        {
            [String] $Computer
            [DateTime] $DateScanned
            
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
        
	}

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present get-netadapter
        $Adapters = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-NetAdapter -ErrorAction SilentlyContinue} #get a list of network adapters
        
        if ($Adapters) {

            $AdapterConfigs = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-CimInstance Win32_NetworkAdapterConfiguration | Select-Object * -ErrorAction SilentlyContinue}  #get the configuration for the current adapter
            $OutputArray = $null
            $OutputArray = @()

            foreach ($Adapter in $Adapters) {#loop through the Interfaces and build the outputArray
                
                if ($Adapter.MediaConnectionState -eq "Connected") {

                    $AdapterConfig = $AdapterConfigs | Where-Object {$_.InterfaceIndex -eq $Adapter.InterfaceIndex}
                    $output = $null
			        $output = [NetAdapter]::new()
   
                    $output.Computer = $Computer
                    $output.DateScanned = Get-Date -Format u
                    $output.FQDN = $Adapter.SystemName
                    $output.DESCRIPTION = $Adapter.InterfaceDescription
                    $output.NetConnectionID = $Adapter.Name
                    $output.NetConnected= $Adapter.MediaConnectionState
                    $output.InterfaceIndex = $Adapter.ifIndex
                    $output.Speed = $Adapter.Speed
                    $output.MACAddress = $Adapter.MACAddress
                    $output.IPAddress = $AdapterConfig.ipaddress[0]
                    $output.Subnet = $AdapterConfig.IPsubnet[0]
                    $output.Gateway = $AdapterConfig.DefaultIPGateway
                    $output.DNS = $AdapterConfig.DNSServerSearchOrder
                    $output.MTU = $Adapter.MtuSize
                    $output.PromiscuousMode = $Adapter.PromiscuousMode

                    $OutputArray += $output

                }

            }

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
                $output = [NetAdapter]::new()

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