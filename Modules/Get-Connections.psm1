﻿function Get-Connections {
    <#
    .SYNOPSIS
        Retrieves details on all TCP and UDP connections and listening ports.

    .EXAMPLE 
        Get-Connections

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Connections} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Connections.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-Connections} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_Connections.csv")
        }

    .NOTES
        Updated: 2023-10-23

        Contributing Authors:
            Jeremy Arnold
            Anthony Phipps
            
        LEGAL: Copyright (C) 2023
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
        https://github.com/TonyPhipps/Meerkat
        https://github.com/TonyPhipps/Meerkat/wiki/TCPConnections
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-Connections at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

   process{
        
        $NetTCPConnections = Get-NetTCPConnection | 
        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, AppliedSettings,
        @{Name="Protocol";Expression={"TCP"}},
        OwningProcess,
        @{Name="Path"; Expression={ (Get-Process -Id $_.OwningProcess).Path }}

        $NetUDPEndpoints = Get-NetUDPEndpoint |
            Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State,
            @{Name="AppliedSetting";Expression={$_.Description}},
            @{Name="Protocol";Expression={"UDP"}},
            OwningProcess,
            @{Name="Path"; Expression={ (Get-Process -Id $_.OwningProcess).Path }}
        
        $ResultsArray = $NetTCPConnections + $NetUDPEndpoints
        
        foreach ($Result in $ResultsArray){

            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned 
            $Result | Add-Member -MemberType NoteProperty -Name "ModuleVersion" -Value $ModuleVersion
        }

        return $ResultsArray | Select-Object Host, DateScanned, ModuleVersion, LocalAddress, LocalPort, 
        RemoteAddress, RemotePort, State, AppliedSetting, Protocol, OwningProcess, Path
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}
