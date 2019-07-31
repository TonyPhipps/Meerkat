function Invoke-HAMER {
    <#
    .SYNOPSIS 
        Performs threat hunting reconnaissance on one or more target systems.

    .DESCRIPTION 
        Performs threat hunting reconnaissance on one or more target systems.

        Invoke-HAMER takes advantage of the `export-csv` cmdlet in this way by exporting ALL enabled modules to csv. The basic syntax is `Invoke-HAMER -Computer [Computername] -Modules [Module1, Module2, etc.]` (details via `get-help Invoke-HAMER -Full`).

        When running a single function against a single endpoint, the typical sytnax is `Get-h[ModuleName] -Computer [ComputerName]`, which returns objects relevant to the function called. All modules support the pipeline, which means results can be exported. For example, `Get-h[ModuleName] -Computer [ComputerName] | export-csv "c:\temp\results.csv" -notypeinformation` will utilize PowerShell's built-in csv export function (details via `get-help Get-h[function] -Full`).

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
        Invoke-HAMER -Computer WorkComputer

    .EXAMPLE
        Invoke-HAMER -All -Computer WorkComputer2

    .EXAMPLE
        Invoke-HAMER -Modules Computer, Autoruns

    .EXAMPLE
        Invoke-HAMER -Ingest -Output $pwd

    .EXAMPLE
        Invoke-HAMER -Quick -Output .\Results\

    .NOTES 
        Updated: 2019-05-17

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
       https://github.com/TonyPhipps/HAMER
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME,

        [Parameter()]
        [String] $Output = "C:\users\$env:USERNAME\HAMER",

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
            ADS = (${Function:Get-hADS}, "C:\Temp")
            ARP = (${Function:Get-hARP}, $null)
            Autoruns = ${Function:Get-hAutoruns}
            BitLocker = ${Function:Get-hBitLocker}
            Certificates = ${Function:Get-hCertificates}
            Computer = ${Function:Get-hComputer}
            DNS = ${Function:Get-hDNS}
            Drivers = ${Function:Get-hDrivers}
            EnvVars = ${Function:Get-hEnvVars}
            GroupMembers = ${Function:Get-hGroupMembers}
            Hardware = ${Function:Get-hHardware}
            Hosts = ${Function:Get-hHosts}
            Hotfixes = ${Function:Get-hHotfixes}
            MRU = ${Function:Get-hMRU}
            NetAdapters = ${Function:Get-hNetAdapters}
            NetRoute = ${Function:Get-hNetRoute}
            TCPConnections = ${Function:Get-hTCPConnections}
            Registry = ${Function:Get-hRegistry}
            ScheduledTasks = ${Function:Get-hScheduledTasks}
            Services = ${Function:Get-hServices}
            Sessions = ${Function:Get-hSessions}
            Shares = ${Function:Get-hShares}
            Software = ${Function:Get-hSoftware}
            Strings = ${Function:Get-hStrings}
            TPM = ${Function:Get-hTPM}
            MAC = ${Function:Get-hMAC}
            Processes = ${Function:Get-hProcesses}
            RecycleBin = ${Function:Get-hRecycleBin}
            DLLs = ${Function:Get-hDLLs}
            EventLogs = ${Function:Get-hEventLogs}
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
        $DateScannedFolder = ((Get-Date).ToUniversalTime()).ToString("yyyyMMdd-hhmmssZ")
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

            # & ("Get-h" + $Module) -Computer $Computer | Export-Csv ($FilePath + $Computer + "_$Module.csv") -NoTypeInformation -Append
            Invoke-Command -ComputerName $Computer -SessionOption (New-PSSessionOption -NoMachineProfile) -ScriptBlock $ModuleCommandArray.$Module[0] -ArgumentList $ModuleCommandArray.$Module[1] | 
                Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceID, PSShowComputerName | 
                Export-Csv -NoTypeInformation -Path ($Output + $Computer + "_" + $DateScannedFolder + "_" + $Module + ".csv")
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