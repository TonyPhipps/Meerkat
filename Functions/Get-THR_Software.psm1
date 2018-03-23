function Get-THR_Software {
    <#
    .SYNOPSIS 
        Gets the installed software for the given computer(s).

    .DESCRIPTION 
        Gets the installed software for the given computer(s).

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Software 
        Get-THR_Software SomeHost
        Get-Content C:\hosts.csv | Get-THR_Software
        Get-THR_Software -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Software

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

        class Software
        {
            [string]$Computer
            [datetime]$DateScanned

            [string]$Publisher
            [string]$DisplayName
            [string]$DisplayVersion
            [string]$InstallDate
            [string]$InstallSource
            [string]$InstallLocation
            [string]$PSChildName
            [string]$HelpLink
        }
    }

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present
        
        $Software += Invoke-Command -Computer $Computer -ScriptBlock {
            $pathAllUser = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
            $pathAllUser32 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
                
            Get-ItemProperty -Path $pathAllUser, $pathAllUser32 |
                Where-Object DisplayName -ne $null
        }
       
        if ($Software) { 
            $OutputArray = @()

            foreach ($item in $Software) {
                
                $output = $null
                $output = [Software]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u
                
                $output.Publisher = $item.Publisher
                $output.DisplayName = $item.DisplayName
                $output.DisplayVersion = $item.DisplayVersion
                $output.InstallDate = $item.InstallDate
                $output.InstallSource = $item.InstallSource
                $output.InstallLocation = $item.InstallLocation
                $output.InstallLocation = $item.InstallLocation
                $output.PSChildName = $item.PSChildName
                $output.HelpLink = $item.HelpLink

                $OutputArray += $output
            }
        
        Return $OutputArray

        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $Result = $null
            $Result = [Software]::new()

            $Result.Computer = $Computer
            $Result.DateScanned = Get-Date -Format u
            
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