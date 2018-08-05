function Get-THR_Processes {
    <#
    .SYNOPSIS 
        Gets the processes applied to a given system.

    .DESCRIPTION 
        Gets the processes applied to a given system, including usernames.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Processes 
        Get-THR_Processes SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Processes
        Get-THR_Processes $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Processes

    .NOTES 
        Updated: 2018-08-05

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

        class Process {
            [String] $Computer
            [String] $DateScanned

            [int] $ModuleCount
            [int] $ThreadCount

            [int] $BasePriority
            [string] $Container
            [bool] $EnableRaisingEvents
            #[int] $ExitCode
            [datetime] $ExitTime
            [string] $Handle
            [int] $HandleCount
            [bool] $HasExited
            [int] $Id
            #[string] $MachineName
            [string] $MainModule
            [string] $MainWindowHandle
            [string] $MainWindowTitle
            [string] $MaxWorkingSet
            [string] $MinWorkingSet
            [string] $Modules
            [int] $NonpagedSystemMemorySize
            [long] $NonpagedSystemMemorySize64
            [int] $PagedMemorySize
            [long] $PagedMemorySize64
            [int] $PagedSystemMemorySize
            [long] $PagedSystemMemorySize64
            [int] $PeakPagedMemorySize
            [long] $PeakPagedMemorySize64
            [int] $PeakVirtualMemorySize
            [long] $PeakVirtualMemorySize64
            [int] $PeakWorkingSet
            [long] $PeakWorkingSet64
            [bool] $PriorityBoostEnabled
            [string] $PriorityClass
            [int] $PrivateMemorySize
            [long] $PrivateMemorySize64
            [nullable[timespan]] $PrivilegedProcessorTime
            [string] $ProcessName
            [string] $ProcessorAffinity
            [bool] $Responding
            #[string] $SafeHandle
            [int] $SessionId
            [string] $Site
            [string] $StandardError
            [string] $StandardInput
            [string] $StandardOutput
            #[string] $StartInfo
            [nullable[datetime]] $StartTime
            [string] $SynchronizingObject
            #[string] $Threads
            [nullable[timespan]] $TotalProcessorTime
            [nullable[timespan]] $UserProcessorTime
            [int] $VirtualMemorySize
            [long] $VirtualMemorySize64
            [int] $WorkingSet
            [long] $WorkingSet64
            [string] $Company
            [string] $CPU
            [string] $Description
            [string] $FileVersion
            [string] $Path
            [string] $Product
            [string] $ProductVersion
        }

        $Command = { 
            
            $ProcessArray = Get-Process -IncludeUserName
            $CIMProcesses = Get-CimInstance -class win32_Process
            $CIMServices = Get-CIMinstance -class Win32_Service

            foreach ($Process in $ProcessArray){
                
                $Services = $CIMServices | Where-Object ProcessID -eq $Process.ID 
                $Services = $Services.PathName -Join "; "

                $CommandLine = $CIMProcesses | Where-Object ProcessID -eq $Process.ID | Select-Object -ExpandProperty CommandLine

                $Process | Add-Member -MemberType NoteProperty -Name "CommandLine" -Value $CommandLine
                $Process | Add-Member -MemberType NoteProperty -Name "Services" -Value $Services
                
            }

            return $ProcessArray
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $ResultsArray = $null

        if ($Computer -eq $env:COMPUTERNAME){
            
            $ResultsArray = & $Command 
        } 
        else {

            $ResultsArray = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock $Command
        }
            
        if ($ResultsArray) {
            
            $OutputArray = foreach ($Process in $ResultsArray) {

                $output = $null
                $output = [Process]::new()
                                    
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format o

                $output.BasePriority = $Process.BasePriority
                $output.Container = $Process.Container
                $output.EnableRaisingEvents = $Process.EnableRaisingEvents
                #$output.ExitCode = $Process.ExitCode
                #$output.ExitTime = $Process.ExitTime
                $output.Handle = $Process.Handle
                $output.HandleCount = $Process.HandleCount
                $output.HasExited = $Process.HasExited
                $output.Id = $Process.Id
                #$output.MachineName = $Process.MachineName
                $output.MainModule = $Process.MainModule
                $output.MainWindowHandle = $Process.MainWindowHandle
                $output.MainWindowTitle = $Process.MainWindowTitle
                $output.MaxWorkingSet = $Process.MaxWorkingSet
                $output.MinWorkingSet = $Process.MinWorkingSet
                $output.Modules = $Process.Modules
                $output.NonpagedSystemMemorySize = $Process.NonpagedSystemMemorySize
                $output.NonpagedSystemMemorySize64 = $Process.NonpagedSystemMemorySize64
                $output.PagedMemorySize = $Process.PagedMemorySize
                $output.PagedMemorySize64 = $Process.PagedMemorySize64
                $output.PagedSystemMemorySize = $Process.PagedSystemMemorySize
                $output.PagedSystemMemorySize64 = $Process.PagedSystemMemorySize64
                $output.PeakPagedMemorySize = $Process.PeakPagedMemorySize
                $output.PeakPagedMemorySize64 = $Process.PeakPagedMemorySize64
                $output.PeakVirtualMemorySize = $Process.PeakVirtualMemorySize
                $output.PeakVirtualMemorySize64 = $Process.PeakVirtualMemorySize64
                $output.PeakWorkingSet = $Process.PeakWorkingSet
                $output.PeakWorkingSet64 = $Process.PeakWorkingSet64
                $output.PriorityBoostEnabled = $Process.PriorityBoostEnabled
                $output.PriorityClass = $Process.PriorityClass
                $output.PrivateMemorySize = $Process.PrivateMemorySize
                $output.PrivateMemorySize64 = $Process.PrivateMemorySize64
                $output.PrivilegedProcessorTime = $Process.PrivilegedProcessorTime
                $output.ProcessName = $Process.ProcessName
                $output.ProcessorAffinity = $Process.ProcessorAffinity
                $output.Responding = $Process.Responding
                #$output.SafeHandle = $Process.SafeHandle
                $output.SessionId = $Process.SessionId
                $output.Site = $Process.Site
                $output.StandardError = $Process.StandardError
                $output.StandardInput = $Process.StandardInput
                $output.StandardOutput = $Process.StandardOutput
                #$output.StartInfo = $Process.StartInfo
                $output.StartTime = $Process.StartTime
                $output.SynchronizingObject = $Process.SynchronizingObject
                #$output.Threads = $Process.Threads
                $output.TotalProcessorTime = $Process.TotalProcessorTime
                $output.UserProcessorTime = $Process.UserProcessorTime
                $output.VirtualMemorySize = $Process.VirtualMemorySize
                $output.VirtualMemorySize64 = $Process.VirtualMemorySize64
                $output.WorkingSet = $Process.WorkingSet
                $output.WorkingSet64 = $Process.WorkingSet64
                $output.Company = $Process.Company
                $output.CPU = $Process.CPU
                $output.Description = $Process.Description
                $output.FileVersion = $Process.FileVersion
                $output.Path = $Process.Path
                $output.Product = $Process.Product
                $output.ProductVersion = $Process.ProductVersion

                $output.MainModule = $output.MainModule.Replace('System.Diagnostics.ProcessModule (', '').Replace(')', '')
                $output.ModuleCount = @($Process.Modules).Count
                $output.ThreadCount = @($Process.Threads).Count
                $output.Modules = $Process.Modules -join "; "
                $output.Modules = $output.Modules.Replace('System.Diagnostics.ProcessModule (', '').Replace(')', '')
                
                $output
            }

            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [Process]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format o
            
            $total++
            return $output
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}