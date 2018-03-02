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
        Updated: 2018-03-01

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

        $DateScanned = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class Process {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $BasePriority
            [String] $CPU
            [String] $CommandLine
            [String] $Company
            [String] $Description
            [String] $FileVersion
            [Int32] $HandleCount
            [Int32] $Id
            [String] $MainModule
            [String] $MainWindowHandle
            [String] $MainWindowTitle
            [Int32] $ModuleCount
            [String] $DisplayName
            [String] $Path
            [String] $PriorityClass
            [String] $PrivilegedProcessorTime
            [String] $ProcessName
            [String] $ProcessorAffinity
            [String] $Product
            [String] $ProductVersion
            [String] $Responding
            [Int32] $SessionId
            [String] $StartTime
            [Int32] $Threads
            [String] $TotalProcessorTime
            [String] $UserName
            [String] $Service
            [String] $DLLs
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $Processes = $null
        $Processes = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
            $Processes = Get-Process -IncludeUserName
            $CIMProcesses = Get-CimInstance -class win32_Process
            $CIMServices = Get-CIMinstance -class Win32_Service

            foreach ($Process in $Processes){
                
                $Services = $CIMServices | Where-Object ProcessID -eq $Process.ID 
                $Services = $Services.PathName -Join "; "

                $CommandLine = $CIMProcesses | Where-Object ProcessID -eq $Process.ID | Select-Object -ExpandProperty CommandLine

                $Process | Add-Member -MemberType NoteProperty -Name "CommandLine" -Value $CommandLine
                $Process | Add-Member -MemberType NoteProperty -Name "Service" -Value $Services
                
            }

            return $Processes
        }
            
        if ($Processes) {
            
            $outputArray = @()

            Foreach ($Process in $Processes) {

                $output = $null
                $output = [Process]::new()
                                    
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $output.BasePriority = $Process.BasePriority
                $output.CPU = $Process.CPU
                $output.CommandLine = $Process.CommandLine
                $output.Company = $Process.Company
                $output.Description = $Process.Description
                $output.FileVersion = $Process.FileVersion
                $output.HandleCount = $Process.HandleCount
                $output.Id = $Process.Id
                $output.MainModule = $Process.MainModule
                $output.MainModule = $output.MainModule.Replace('System.Diagnostics.ProcessModule (', '').Replace(')', '')
                $output.MainWindowHandle = $Process.MainWindowHandle
                $output.MainWindowTitle = $Process.MainWindowTitle
                $output.ModuleCount = @($Process.Modules).Count
                $output.DisplayName = $Process.Name
                $output.Path = $Process.Path
                $output.PriorityClass = $Process.PriorityClass
                $output.PrivilegedProcessorTime = $Process.PrivilegedProcessorTime
                $output.ProcessName = $Process.ProcessName
                $output.ProcessorAffinity = $Process.ProcessorAffinity
                $output.Product = $Process.Product
                $output.ProductVersion = $Process.ProductVersion
                $output.Responding = $Process.Responding
                $output.SessionId = $Process.SessionId
                $output.StartTime = $Process.StartTime
                $output.Threads = @($Process.Threads).Count
                $output.TotalProcessorTime = $Process.TotalProcessorTime
                $output.UserName = $Process.UserName
                $output.Service = $Process.Service
                $output.DLLs = $Process.Modules -join "; "
                $output.DLLs = $output.DLLs.Replace('System.Diagnostics.ProcessModule (', '').Replace(')', '')
                
                $outputArray += $output
            }

            return $outputArray

        }
        else {
                
            $output = $null
            $output = [Process]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format u
            
            $total++
            return $output
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}