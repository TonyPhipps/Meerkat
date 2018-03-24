function Get-THR_EventLogs {
    <#
    .SYNOPSIS 
        Gets all event logs on a given system since the specified time frame. Defaults to 8 hours.

    .DESCRIPTION 
        Gets all event logs on a given system since the specified time frame. Defaults to 8 hours.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Days  
        Specify how many days prior to begin event log collection.
        
    .PARAMETER Hours  
        Specify how many hours prior to begin event log collection.

    .PARAMETER Minutes  
        Specify how many minutes prior to begin event log collection.

    .EXAMPLE 
        Get-THR_EventLogs 
        Get-THR_EventLogs SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_EventLogs
        Get-THR_EventLogs $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_EventLogs

    .NOTES 
        Updated: 2018-03-23

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
        $Computer = $env:COMPUTERNAME,

        [Parameter()]
        [int] $Days = "0",

        [Parameter()]
        [int] $Hours = "0",

        [Parameter()]
        [int] $Minutes = "0"

    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class Event {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $TimeCreated
            [String] $MachineName
            [String] $UserId
            [String] $ProcessId
            [String] $LogName
            [String] $Source
            [String] $LevelDisplayName
            [String] $EventId
            [String] $OpcodeDisplayName
            [String] $TaskDisplayName
            [String] $Message
            [String] $RecordId
            [String] $RelatedActivityId
            [String] $ThreadId
            [String] $Version
        }

        if ($Days -eq 0 -and $Hours -eq 0 -and $Minutes -eq 0){
            $Hours = 8
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $EventLogs = $null
        $EventLogs = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
           
            $Logs = Get-WinEvent -ListLog * | Select-Object LogName | 
            Where-Object LogName -ne "Microsoft-Windows-PowerShell/Operational" # Powershell operational log has no useful details

            $Events = @()
            Foreach ($Log in $Logs){

                $Events += Get-WinEvent -FilterHashTable @{LogName=$Log.LogName; StartTime=(Get-Date) - (New-TimeSpan -Days $Using:Days -Hours $Using:Hours -Minutes $Using:Minutes)} -ErrorAction SilentlyContinue | 
                Select-Object TimeCreated, MachineName, UserId, ProcessId, LogName, ProviderName, LevelDisplayName, Id, OpcodeDisplayName, TaskDisplayName, Message, RecordId, RelatedActivityId, ThreadId, Version
            }

            return $Events
        }
            
        if ($EventLogs) {
            
            $outputArray = @()

            Foreach ($Event in $EventLogs) {

                $output = $null
                $output = [Event]::new()
                                    
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $output.TimeCreated = $Event.TimeCreated
                $output.MachineName = $Event.MachineName
                $output.UserId = $Event.UserId
                $output.ProcessId = $Event.ProcessId
                $output.LogName = $Event.LogName
                $output.Source = $Event.ProviderName
                $output.LevelDisplayName = $Event.LevelDisplayName
                $output.EventId = $Event.Id
                $output.OpcodeDisplayName = $Event.OpcodeDisplayName
                $output.TaskDisplayName = $Event.TaskDisplayName
                $output.Message = $Event.Message
                $output.RecordId = $Event.RecordId
                $output.RelatedActivityId = $Event.RelatedActivityId
                $output.ThreadId = $Event.ThreadId
                $output.Version = $Event.Version
                
                $outputArray += $output
            }

            return $outputArray
        }
        else {
                
            $output = $null
            $output = [Event]::new()

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