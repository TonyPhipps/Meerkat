function Get-THRUST_WinEvents {
    <#
    .SYNOPSIS 
        Gets Windows events from one or more systems.

    .DESCRIPTION 
        Gets Windows events from one or more systems.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Fails  
        Provide a path to save failed systems to.

    .EXAMPLE 
        Get-THRUST_WinEvents -FilterHashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8002","8003","8004"}
        Get-THRUST_WinEvents -FilterHashTable @{LogName="Windows PowerShell"; StartTime=(Get-Date).AddDays(-8); EndTime=(Get-Date)} 
        Get-THRUST_WinEvents SomeHostName.domain.com
        Get-Content C:\hosts.txt | Get-THRUST_WinEvents
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THRUST_WinEvents

    .EXAMPLE
        Pull AppLocker Events from a Windows Event Collector:
        Get-THRUST_WinEvents -FilterHashTable @{LogName="ForwardedEvents"; ID="8002","8003","8004"}

    .NOTES
        To extract XML data, use another script like Get-WinEventXMLData
           https://github.com/TonyPhipps/THRUST/blob/master/Add-WinEventXMLData.ps1
     
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
       https://github.com/TonyPhipps/THRUST
    #>

    [CmdletBinding()]
    param(
    	    [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
            $Computer = $env:COMPUTERNAME,

            [Parameter()]
            [array]
            $FilterHashTable = @{LogName="Windows PowerShell"; StartTime=(Get-Date).AddDays(-8);},
            
            [Parameter()]
            $Fails
        );

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;
    };

    process{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

        $Events = Get-WinEvent -ComputerName $Computer -FilterHashTable $FilterHashTable;

        if ($Events) {

            $Events |
                Foreach-Object {

                    $output = $_;
                    $output | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer;
                    $output | Add-Member -MemberType NoteProperty -Name DateScanned -Value (Get-Date -Format u);

                    Return $output;
                };
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [PSCustomObject]@{
                    Computer = $Computer
                    DateScanned = Get-Date -Format u
                };
                
                $total++;
                return $output;
            };
        };
    };

    end{

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed);
    };
};