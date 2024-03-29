function Get-EventCounts {
    <#
    .SYNOPSIS
        Gets a count of events by Log Name, Source, Severity, and ID.

    .DESCRIPTION
        Gets a count of events by Log Name, Source, Severity, and ID.

    .PARAMETER StartTime
        Specify when to begin event log collection. Defaults to 24 hours ago based on current system time.
        
    .PARAMETER EndTime
        Specify when to end event log collection. Defaults to current system time.

    .EXAMPLE 
        Get-EventCounts

    .EXAMPLE
        Get-EventCounts | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\EventCounts.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-EventCounts} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\EventCounts.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-EventCounts} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_EventCounts.csv")
        }

    .NOTES
        Updated: 2024-03-27

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2024
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
       https://github.com/TonyPhipps/Meerkat/wiki/EventLogCounts
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [datetime] $StartTime,

        [Parameter()]
        [datetime] $EndTime
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-EventCounts at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        if(!($StartTime)){
            $StartTime = (Get-Date) - (New-TimeSpan -Hours 24)
        }

        if(!($EndTime)){
            $EndTime = (Get-Date)
        }
    }

    process{

        $Logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Where-Object { ($_.RecordCount -gt 0) } 

        $EventsArray = Foreach ($Log in $Logs){

            Get-WinEvent -FilterHashTable @{ LogName=$Log.LogName; StartTime=$StartTime; EndTime=$EndTime } -ErrorAction SilentlyContinue
        }

        $FilteredEvents = $EventsArray | Select-Object -Property ContainerLog, Id, ProviderName, LevelDisplayName

        $ResultsArray = $FilteredEvents | Group-Object ContainerLog, Id, ProviderName, LevelDisplayName | ForEach-Object {
            $Property = $_.name -split ', '
            [pscustomobject] @{
                ContainerLog = $Property[0]
                Id = $Property[1]
                ProviderName = $Property[2]
                LevelDisplayName = $Property[3]
                Count = ($_.Group | Measure-Object).Count
            }
        }

        foreach ($Result in $ResultsArray) {
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
        }

        return $ResultsArray | Select-Object Host, DateScanned, ContainerLog, Id, ProviderName, LevelDisplayName, Count
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}