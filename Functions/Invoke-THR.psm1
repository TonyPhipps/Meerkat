function Invoke-THR {
    <#
    .SYNOPSIS 
        Performs threat hunting reconnaissance on one or more target systems.

    .DESCRIPTION 
        Performs threat hunting reconnaissance on one or more target systems.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER All
        Collect all possible results. Exlcusions like -Quick and -Micro are applied AFTER -All.

    .PARAMETER Quick
        Excludes collections that are anticipated to take more than a few minutes to retrieve results.
    
    .PARAMETER Micro
        Excludes collections that are anticipated to consume more than about half a megabyte.

    .PARAMETER Output
        Specify a path to save results to. Default is the current working directory.

    .PARAMETER Ingest
        When used, an additional subfolder will me made under -Output for each collection type enabled. 
        Intended for use with products that ingest files, like Elasticstack, Graylog, Splunk, etc.
        To speed up bulk collections, consider using a jobs manager like PoshRSJob 
        (https://github.com/proxb/PoshRSJob)
        A PoshRSJob wrapper is provided in the \Utilities\ folder of this project.

    .EXAMPLE
        Invoke-THR -Computer WorkComputer

    .EXAMPLE
        Invoke-THR -All -Computer WorkComputer2

    .EXAMPLE
        Invoke-THR -Modules Computer, Autoruns

    .EXAMPLE
        Invoke-THR -Ingest -Output $pwd

    .EXAMPLE
        Invoke-THR -Quick -Output .\Results\

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
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME,

        [Parameter()]
        [String] $Output = "C:\temp",

        [Parameter()]
        [switch] $All,

        [Parameter()]
        [alias("Fast")]
        [switch] $Quick,

        [Parameter()]
        [alias("Small")]
        [switch] $Micro,

        [Parameter()]
        [alias("M", "Mod")]
        [ValidateSet( "ADS", "ARP", "Autoruns", "BitLocker", "Certificates", "Computer", "DLLs", "DNS", "Drivers", "EnvVars", 
            "EventLogs", "GroupMembers", "Hardware", "Hosts", "Hotfixes", "MRU", "NetAdapters", "NetRoute", "TCPConnections", 
            "Processes", "RecycleBin", "Registry", "ScheduledTasks", "Services", "Sessions", "Shares", "Software", "Strings", "TPM",
            "MAC" )]
        [array]$Modules = ("ARP", "Autoruns", "BitLocker", "Computer", "DNS", "Drivers", "EnvVars", "GroupMembers", "Hosts", "Hotfixes",
            "MRU", "NetAdapters", "NetRoute", "TCPConnections",  "Registry", "ScheduledTasks", "Services", "Sessions", "Shares", "Software",
            "TPM", "Processes", "RecycleBin", "DLLs")
    )

    begin{

        $ModuleCommandArray = @{
            ADS = (${Function:Get-THR_ADS}, "C:\Temp")
            ARP = (${Function:Get-THR_ARP}, $null)
            Autoruns = ${Function:Get-THR_Autoruns}
            BitLocker = ${Function:Get-THR_BitLocker}
            Certificates = ${Function:Get-THR_Certificates}
            Computer = ${Function:Get-THR_Computer}
            DNS = ${Function:Get-THR_DNS}
            Drivers = ${Function:Get-THR_Drivers}
            EnvVars = ${Function:Get-THR_EnvVars}
            GroupMembers = ${Function:Get-THR_GroupMembers}
            Hardware = ${Function:Get-THR_Hardware}
            Hosts = ${Function:Get-THR_Hosts}
            Hotfixes = ${Function:Get-THR_Hotfixes}
            MRU = ${Function:Get-THR_MRU}
            NetAdapters = ${Function:Get-THR_NetAdapters}
            NetRoute = ${Function:Get-THR_NetRoute}
            TCPConnections = ${Function:Get-THR_TCPConnections}
            Registry = ${Function:Get-THR_Registry}
            ScheduledTasks = ${Function:Get-THR_ScheduledTasks}
            Services = ${Function:Get-THR_Services}
            Sessions = ${Function:Get-THR_Sessions}
            Shares = ${Function:Get-THR_Shares}
            Software = ${Function:Get-THR_Software}
            Strings = ${Function:Get-THR_Strings}
            TPM = ${Function:Get-THR_TPM}
            MAC = ${Function:Get-THR_MAC}
            Processes = ${Function:Get-THR_Processes}
            RecycleBin = ${Function:Get-THR_RecycleBin}
            DLLs = ${Function:Get-THR_DLLs}
            EventLogs = ${Function:Get-THR_EventLogs}
        }

        if ($All) {

            [array]$Modules = ("ADS", "ARP", "Autoruns", "BitLocker", "Certificates", "Computer", "DNS", "Drivers", "EnvVars", "GroupMembers",
            "Hardware", "Hosts", "Hotfixes", "MRU", "NetAdapters", "NetRoute", "TCPConnections", "Registry", "ScheduledTasks",
            "Services", "Sessions", "Shares", "Software", "Strings", "TPM", "MAC", "Processes", "RecycleBin", "DLLs",
            "EventLogs")
        }

        if ($Quick) {

            $Modules = $Modules | 
            Where-Object { $_ -notin "ADS", "DLLs", "Drivers", "EventLogs", "MAC", "MRU", "RecycleBin", "Sessions", "Strings" }
        }

        if ($Micro){

            $Modules = $Modules | 
            Where-Object { $_ -notin "DLLs", "EventLogs", "MAC" }
        }   

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0
    }

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        if (!(Test-Path $Output)){
            mkdir $Output
        }

        $Output = $Output + "\"
        
        foreach ($Module in $Modules){

            # & ("Get-THR_" + $Module) -Computer $Computer | Export-Csv ($FilePath + $Computer + "_$Module.csv") -NoTypeInformation -Append
            Invoke-Command -ComputerName $Computer -SessionOption (New-PSSessionOption -NoMachineProfile) -ScriptBlock $ModuleCommandArray.$Module[0] -ArgumentList $ModuleCommandArray.$Module[1] | 
                Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceID, PSShowComputerName | 
                Export-Csv -NoTypeInformation -Path ($Output + $Computer + "_" + $Module + ".csv")
        }
    
        $total++
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Started at {0}" -f $DateScanned)
        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}