function Get-EventLogsMetadata {
    <#
    .SYNOPSIS
        Gets metadata about each event log.

    .DESCRIPTION
        Gets metadata about each event log.

    .EXAMPLE 
        Get-EventLogsMetadata

    .EXAMPLE
        Get-EventLogsMetadata | 
        Export-Csv -NoTypeInformation ("c:\temp\EventLogsMetadata.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-EventLogsMetadata} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\EventLogsMetadata.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-EventLogsMetadata} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_EventLogsMetadata.csv")
        }

    .NOTES
        Updated: 2022-11-30

        Contributing Authors:
            Anthony Phipps, Jack Smith
            
        LEGAL: Copyright (C) 2022
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
       https://github.com/TonyPhipps/Meerkat/wiki/EventLogsMetadata
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [datetime] $StartTime,

        [Parameter()]
        [datetime] $EndTime
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started Get-EventLogsMetadata at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

    }

    process{

        $ResultsArray = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue

        foreach ($Result in $ResultsArray) {
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
            $Result | Add-Member -MemberType NoteProperty -Name "OldestEvent" -Value (Get-WinEvent -LogName $Result.LogName -MaxEvents 1 -Oldest -ErrorAction SilentlyContinue | Select-Object TimeCreated -ExpandProperty TimeCreated)
        }
    
        return $ResultsArray | Select-Object Host, DateScanned, LogName, LogType, LogIsolation, FileSize, IsEnabled, LogFilePath, LogMode, IsLogFull, RecordCount, LastAccessTime, LastWriteTime, OldestRecordNumber, OldestEvent
     
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}                                                              