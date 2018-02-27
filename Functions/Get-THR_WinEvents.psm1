function Get-THR_WinEvents {
    <#
    .SYNOPSIS 
        Gets Windows events from one or more systems.

    .DESCRIPTION 
        Gets Windows events from one or more systems.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_WinEvents -FilterHashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL" ID="8002","8003","8004"}
        Get-THR_WinEvents -FilterHashTable @{LogName="Windows PowerShell" StartTime=(Get-Date).AddDays(-8) EndTime=(Get-Date)} 
        Get-THR_WinEvents SomeHostName.domain.com
        Get-Content C:\hosts.txt | Get-THR_WinEvents
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_WinEvents

    .EXAMPLE
        Pull AppLocker Events from a Windows Event Collector:
        Get-THR_WinEvents -FilterHashTable @{LogName="ForwardedEvents" ID="8002","8003","8004"}

    .NOTES
        To extract XML data, use another script like Get-WinEventXMLData
           https://github.com/TonyPhipps/THRecon/blob/master/Add-WinEventXMLData.ps1
     
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

    [CmdletBinding()]
    param(
    	    [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
            $Computer = $env:COMPUTERNAME,

            [Parameter()]
            [array]
            $FilterHashTable = @{
                LogName="Windows PowerShell" 
                StartTime=(Get-Date).AddDays(-8)
            }
        )

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0
    }

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $Events = Get-WinEvent -ComputerName $Computer -FilterHashTable $FilterHashTable

        if ($Events) {

            $Events |
            Foreach-Object {

                $output = $_
                $output | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer
                $output | Add-Member -MemberType NoteProperty -Name DateScanned -Value (Get-Date -Format u)

                Return $output
            }

            $total++
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $output = $null
            $output = [PSCustomObject]@{
                Computer = $Computer
                DateScanned = $DateScanned
            }
            
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