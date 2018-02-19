 function Get-THR_Hardware {
    <#
    .SYNOPSIS 
        Gets a list of installed devices for the given computer(s).

    .DESCRIPTION 
        Gets a list of installed devices for the given computer(s).

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Fails  
        Provide a path to save failed systems to.

    .EXAMPLE 
        Get-THR_Hardware 
        Get-THR_Hardware SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Hardware
        Get-THR_Hardware -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Hardware

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

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $total = 0

        class Device
        {
            [string] $Computer
            [Datetime] $DateScanned
            
            [String] $Class
            [string] $Caption
            [string] $Description
            [String] $DeviceID

        }

    }

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present
        $OutputArray = @()
        $devices = $null
        Write-Verbose "Getting a list of installed devices..."
        $devices = Invoke-Command -Computer $Computer -ScriptBlock {Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue}
       
        if ($devices) { 
            $OutputArray = $devices | Group-Object pnpclass | Select-Object Name, Count | Sort-Object name
            foreach ($device in $devices) {
             
                $output = $null
                $output = [Device]::new()
                
                $output.DateScanned = Get-Date -Format u
                $output.Computer = $Computer
                $output.Class = $device.pnpclass
                $output.caption = $device.caption
                $output.description = $device.description
                $output.deviceID = $device.deviceID

                $OutputArray += $output
            
            }

            $total++
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
                $output = [Device]::new()

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