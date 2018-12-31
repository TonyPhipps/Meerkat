function Get-THR_Processes {
    <#
    .SYNOPSIS 
        Gets the processes applied to a given system.

    .DESCRIPTION 
        Gets the processes applied to a given system, including usernames.

    .EXAMPLE
        Get-THR_Processes
        
    .EXAMPLE
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-THR_Processes} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation "c:\temp\results\$Target_processes.csv"
        }

    .NOTES 
        Updated: 2018-12-30

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
       https://github.com/TonyPhipps/THRecon/wiki/Processes
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Verbose ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $Hostname = $ENV:COMPUTERNAME
        $DateScanned = Get-Date -Format u

        $ProcessArray = Get-Process -IncludeUserName
        $CIMProcesses = Get-CimInstance -class win32_Process
        $CIMServices = Get-CIMinstance -class Win32_Service        
        $PerfProcArray = Get-CIMinstance -class Win32_PerfFormattedData_PerfProc_Process

        foreach ($Process in $ProcessArray){
            
            $Services = $CIMServices | Where-Object ProcessID -eq $Process.ID 
            $Services = $Services.PathName -Join "; "
            
            $CommandLine = $CIMProcesses | Where-Object ProcessID -eq $Process.ID | Select-Object -ExpandProperty CommandLine
            $PercentProcessorTime = $PerfProcArray | Where-Object IDProcess -eq $Process.ID | Select-Object -ExpandProperty PercentProcessorTime
            $MemoryMB = $PerfProcArray | Where-Object IDProcess -eq $Process.ID | Select-Object -ExpandProperty workingSetPrivate
            $MemoryMB = try {[Math]::Round(($MemoryMB / 1mb),2)} Catch{}

            $Process | Add-Member -MemberType NoteProperty -Name "Host" -Value $Hostname
            $Process | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
            $Process | Add-Member -MemberType NoteProperty -Name "CommandLine" -Value $CommandLine
            $Process | Add-Member -MemberType NoteProperty -Name "Services" -Value $Services
            $Process | Add-Member -MemberType NoteProperty -Name "PercentProcessorTime" -Value $PercentProcessorTime
            $Process | Add-Member -MemberType NoteProperty -Name "MemoryMB" -Value $MemoryMB
            $Process | Add-Member -MemberType NoteProperty -Name "ModuleCount" -Value @($Process.Modules).Count
            $Process | Add-Member -MemberType NoteProperty -Name "ThreadCount" -Value @($Process.Threads).Count
        }

        return $ProcessArray | Select-Object Host, DateScanned, CommandLine, Services, PercentProcessorTime, MemoryMB, BasePriority, Id, MainWindowHandle, MainWindowTitle, PriorityBoostEnabled, PriorityClass, PrivateMemorySize, PrivilegedProcessorTime, ProcessName, Responding, SessionId, StartTime, TotalProcessorTime, UserProcessorTime, Company, CPU, Description, FileVersion, Path, Product, ProductVersion, ModuleCount, ThreadCount, HandleCount
    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Started at {0}" -f $DateScanned)
        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}

