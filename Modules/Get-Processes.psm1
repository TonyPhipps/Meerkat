function Get-Processes {
    <#
    .SYNOPSIS 
        Gets process information relevant to an investigation or hunt.

    .DESCRIPTION 
        Gets process information relevant to an investigation or hunt.

        Alternative: tasklist.exe -v
        Alternative: wmic.exe process list full

    .EXAMPLE
        Get-Processes

    .EXAMPLE
        Get-Processes | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Processes.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Processes} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Processes.csv")
        
    .EXAMPLE
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-Processes} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_processes.csv")
        }

    .NOTES 
        Updated: 2024-09-30

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
       https://github.com/TonyPhipps/Meerkat/wiki/Processes
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-Processes at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        try{ $ProcessArray = Get-Process -IncludeUserName }catch{ $ProcessArray = Get-Process }
        $CIMProcesses = Get-CimInstance -class win32_Process
        $CIMServices = Get-CIMinstance -class Win32_Service        
        $PerfProcArray = Get-CIMinstance -class Win32_PerfFormattedData_PerfProc_Process

        foreach ($Process in $ProcessArray){
            
            $Services = $CIMServices | Where-Object ProcessID -eq $Process.ID 
            $Services = $Services.PathName -Join "; "
            
            $CommandLine = $CIMProcesses | Where-Object ProcessId -eq $Process.Id | Select-Object -ExpandProperty CommandLine
            $ParentId = $CIMProcesses | Where-Object ProcessId -eq $Process.Id | Select-Object -ExpandProperty ParentProcessId
            $ParentPath = Get-CimInstance -class win32_Process -Filter "ProcessId = '$ParentId'" | Select-Object -ExpandProperty Path
            $ParentCommandLine = Get-CimInstance -class win32_Process -Filter "ProcessId = '$ParentId'" | Select-Object -ExpandProperty CommandLine
            $PercentProcessorTime = $PerfProcArray | Where-Object IDProcess -eq $Process.ID | Select-Object -ExpandProperty PercentProcessorTime
            $MemoryMB = $PerfProcArray | Where-Object IDProcess -eq $Process.ID | Select-Object -ExpandProperty workingSetPrivate
                if ($MemoryMB.GetType().Name -eq "UInt64"){
                    $MemoryMB = [Math]::Round(($MemoryMB / 1mb),2)
                }
                else { $MemoryMB = "" }
            $Process | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Process | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
            $Process | Add-Member -MemberType NoteProperty -Name "CommandLine" -Value $CommandLine
            $Process | Add-Member -MemberType NoteProperty -Name "ParentId" -Value $ParentId
            $Process | Add-Member -MemberType NoteProperty -Name "ParentPath" -Value $ParentPath
            $Process | Add-Member -MemberType NoteProperty -Name "ParentCommandLine" -Value $ParentCommandLine
            $Process | Add-Member -MemberType NoteProperty -Name "Services" -Value $Services
            $Process | Add-Member -MemberType NoteProperty -Name "PercentProcessorTime" -Value $PercentProcessorTime
            $Process | Add-Member -MemberType NoteProperty -Name "MemoryMB" -Value $MemoryMB
            $Process | Add-Member -MemberType NoteProperty -Name "ModuleCount" -Value @($Process.Modules).Count
            $Process | Add-Member -MemberType NoteProperty -Name "ThreadCount" -Value @($Process.Threads).Count
        }

        return $ProcessArray | Select-Object Host, DateScanned, CommandLine, Services, PercentProcessorTime, MemoryMB, BasePriority, Id, MainWindowHandle, MainWindowTitle, PriorityBoostEnabled, PriorityClass, PrivateMemorySize, PrivilegedProcessorTime, ProcessName, Responding, SessionId, StartTime, TotalProcessorTime, UserName, UserProcessorTime, Company, CPU, Description, FileVersion, Path, Product, ProductVersion, ModuleCount, ThreadCount, HandleCount, ParentId, ParentPath, ParentCommandLine
    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ"))
    }
}

