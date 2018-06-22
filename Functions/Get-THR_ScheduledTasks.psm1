function Get-THR_ScheduledTasks {
    <#
    .SYNOPSIS 
        Gets the scheduled tasks on a given system.

    .DESCRIPTION 
        Gets the scheduled tasks on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.  

    .EXAMPLE 
        Get-THR_ScheduledTasks 
        Get-THR_ScheduledTasks SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_ScheduledTasks
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_ScheduledTasks

    .NOTES 
        Updated: 2018-06-21

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
       https://github.com/TonyPhipps/THRecon/wiki/ScheduledTasks
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

        class Task {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $ActionsArguments
            [String] $ActionsExecute
            [String] $ActionsId
            [String] $ActionsWorkingDirectory
            [String] $Author
            [String] $Description
            [String] $SecurityDescriptor
            [String] $Source
            [String] $State
            [String] $TaskName
            [String] $TaskPath
            [String] $TriggersDelay
            [String] $TriggersEnabled
            [String] $TriggersEndBoundary
            [String] $TriggersExecutionTimeLimit
            [String] $TriggersPSComputerName
            [String] $TriggersRepetition
            [String] $TriggersStartBoundary
            [String] $URI
        }

        $Command = { Get-ScheduledTask }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        Write-Verbose ("{0}: Querying remote system" -f $Computer)

        if ($Computer = $env:COMPUTERNAME){
            
            $ResultsArray = & $Command 
        } 
        else {

            $ResultsArray = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock $Command
        }
            
        if ($ResultsArray) {

            $OutputArray = foreach($Entry in $ResultsArray) {

                $output = $null
                $output = [Task]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $output.ActionsArguments = ($Entry.Actions.Arguments -join " ")
                $output.ActionsExecute = ($Entry.Actions.Execute -join " ")
                $output.ActionsId = ($Entry.Actions.Id -join " ")
                $output.ActionsWorkingDirectory = ($Entry.Actions.WorkingDirectory -join " ")
                $output.Author = $Entry.Author
                $output.DESCRIPTION = $Entry.DESCRIPTION
                $output.SecurityDescriptor = $Entry.SecurityDescriptor
                $output.Source = $Entry.Source
                $output.State = $Entry.State
                $output.TaskName = $Entry.TaskName
                $output.TaskPath = $Entry.TaskPath
                $output.TriggersDelay = ($Entry.Triggers.Delay -join " ")
                $output.TriggersEnabled = ($Entry.Triggers.Enabled -join " ")
                $output.TriggersEndBoundary = ($Entry.Triggers.EndBoundary -join " ")
                $output.TriggersExecutionTimeLimit = ($Entry.Triggers.ExecutionTimeLimit -join " ")
                $output.TriggersPSComputerName = ($Entry.Triggers.PSComputerName -join " ")
                $output.TriggersRepetition = ($Entry.Triggers.Repetition -join " ")
                $output.TriggersStartBoundary = ($Entry.Triggers.StartBoundary -join " ")
                $output.URI = $Entry.URI

                $output
            }

            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [Task]::new()

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