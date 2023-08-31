function Invoke-Meerkat {
    <#
    .SYNOPSIS 
        Performs threat hunting reconnaissance on one or more target systems.

    .DESCRIPTION 
        Performs threat hunting reconnaissance on one or more target systems.

        Invoke-Meerkat takes advantage of the `export-csv` cmdlet in this way by exporting ALL enabled modules to csv. The basic syntax is `Invoke-Meerkat -Computer [Computername] -Modules [Module1, Module2, etc.]` (details via `get-help Invoke-Meerkat -Full`).

        When running a single function against a single endpoint, the typical sytnax is `Get-[ModuleName] -Computer [ComputerName]`, which returns objects relevant to the function called. All modules support the pipeline, which means results can be exported. For example, `Get-[ModuleName] -Computer [ComputerName] | export-csv "c:\temp\results.csv" -notypeinformation` will utilize PowerShell's built-in csv export function (details via `get-help Get-[function] -Full`).

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

    .PARAMETER Service
        Skips requesting credentials on systems that fail WinRM PSSession check.

    .EXAMPLE
        Invoke-Meerkat -Computer WorkComputer

    .EXAMPLE
        Invoke-Meerkat -All -Computer WorkComputer2

    .EXAMPLE
        Invoke-Meerkat -Modules Computer, Autoruns

    .EXAMPLE
        Get-Content c:\hosts.csv | Invoke-Meerkat -Output C:\TodaysDate\Meerkat\

    .EXAMPLE
        Invoke-Meerkat -Quick -Output .\Results\

    .NOTES 
        Updated: 2023-08-31

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2023
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
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME,

        [Parameter()]
        [String] $Output = "C:\users\$env:USERNAME\Meerkat",

        [Parameter()]
        [switch] $All,

        [Parameter()]
        [alias("Fast")]
        [switch] $Quick,
        
        [Parameter()]
        [alias("NonInteractive")]
        [switch] $Service = $false,

        [Parameter()]
        [alias("M", "Mod")]
        [ValidateSet( "ADS", "ARP", "Autoruns", "AuditPolicy", "BitLocker", "Certificates", "ComputerDetails", "Connections", "Defender", "Disks", "DomainInfo", "DLLs", "DNS", "Drivers", "EnvVars", 
            "EventLogs", "EventLogsMetadata", "LocalGroups", "LocalUsers", "Hardware", "Hosts", "Hotfixes", "EventsLoginFailures", "EventsLoginFailures", "EventsUserManagement", "RegistryMRU", "MAC", "NetAdapters", "NetRoutes", "Processes", "RecycleBin", 
            "Registry", "RegistryPersistence", "ScheduledTasks", "Services", "Sessions", "Shares", "Software", "Strings", "TPMDetails", "USBHistory", "WindowsFirewall")]
        [array]$Modules = ("ARP", "Autoruns", "AuditPolicy", "BitLocker", "RegistryPersistence", "ComputerDetails", "Disks", "DNS", "Drivers", "EnvVars", "EventsLoginFailures", 
        "LocalGroups", "LocalUsers", "Hosts", "Hotfixes", "RegistryMRU", "NetAdapters", "NetRoutes", "Connections",  "Registry", "ScheduledTasks", "Services", 
        "Sessions", "Shares", "Software", "TPMDetails", "Processes", "RecycleBin", "DLLs", "USBHistory", "WindowsFirewall")
    )

    begin{

        $ModuleCommandArray = @{
            ADS = (${Function:Get-ADS}, "C:\Temp")
            ARP = (${Function:Get-ARP}, $null)
            AuditPolicy = ${Function:Get-AuditPolicy}
            Autoruns = ${Function:Get-Autoruns}
            BitLocker = ${Function:Get-BitLocker}
            Certificates = ${Function:Get-Certificates}
            RegistryPersistence = ${Function:Get-RegistryPersistence}
            ComputerDetails = ${Function:Get-ComputerDetails}
            Defender = ${Function:Get-Defender}
            Disks = ${Function:Get-Disks}
            DLLs = ${Function:Get-DLLs}
            DNS = ${Function:Get-DNS}
            DomainInfo = ${Function:Get-DomainInfo}
            Drivers = ${Function:Get-Drivers}
            EventLogsMetadata = ${Function:Get-EventLogsMetadata}
            EnvVars = ${Function:Get-EnvVars}
            LocalUsers = ${Function:Get-LocalUsers}
            LocalGroups = ${Function:Get-LocalGroups}
            Hardware = ${Function:Get-Hardware}
            Hosts = ${Function:Get-Hosts}
            Hotfixes = ${Function:Get-Hotfixes}
            EventsLoginFailures = ${Function:Get-EventsLoginFailures}
            EventsUserManagement = ${Function:Get-EventsUserManagement}
            RegistryMRU = ${Function:Get-RegistryMRU}
            NetAdapters = ${Function:Get-NetAdapters}
            NetRoutes = ${Function:Get-NetRoutes}
            Connections = ${Function:Get-Connections}
            Registry = ${Function:Get-Registry}
            ScheduledTasks = ${Function:Get-ScheduledTasks}
            Services = ${Function:Get-Services}
            Sessions = ${Function:Get-Sessions}
            Shares = ${Function:Get-Shares}
            Software = ${Function:Get-Software}
            Strings = ${Function:Get-Strings}
            TPMDetails = ${Function:Get-TPMDetails}
            MAC = ${Function:Get-MAC}
            Processes = ${Function:Get-Processes}
            RecycleBin = ${Function:Get-RecycleBin}
            EventLogs = ${Function:Get-EventLogs}
            USBHistory = ${Function:Get-USBHistory}
            WindowsFirewall = ${Function:Get-WindowsFirewall}
        }

        if ($All) {

            [array]$Modules = ("ADS", "ARP", "Autoruns", "AuditPolicy", "BitLocker", "Certificates", "ComputerDetails", "Defender", 
            "Disks", "DLLs", "DomainInfo", "DNS", "Drivers", "EventLogsMetadata", "EnvVars", "LocalGroups", "LocalUsers", "Hardware", "Hosts", "Hotfixes",
            "EventsLoginFailures", "EventsUserManagement", "RegistryMRU", "NetAdapters", "NetRoutes", "Connections", "Registry", "RegistryPersistence", 
            "ScheduledTasks", "Services", "Sessions", "Shares", "Software", "Strings", "TPMDetails", "MAC", "Processes", "RecycleBin", "DLLs", "EventLogs", "USBHistory", 
            "WindowsFirewall")
        }

        if ($Quick) {

            $Modules = $Modules | 
            Where-Object { $_ -notin "ADS", "DLLs", "DomainInfo", "Drivers", "EventLogs", "MAC", "RegistryMRU", "RecycleBin", "Sessions", "Strings" }
        }  

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ")
        $DateScannedFolder = ((Get-Date).ToUniversalTime()).ToString("yyyyMMdd-hhmmssZ")
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0
    }

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        if (Test-Connection $Computer -Quiet -ErrorAction SilentlyContinue){
            Write-Information -InformationAction Continue -MessageData ("Test-Connection for {0} succeeded." -f $Computer)
        }
        else{
            Write-Information -InformationAction Continue -MessageData ("Test-Connection for {0} FAILED - skipping." -f $Computer)
            return
        }

        if (!(Test-Path $Output)){
            mkdir $Output
        }

        $Output = $Output + "\"
        
        try{
            if ($Computer -eq $env:COMPUTERNAME){
                foreach ($Module in $Modules){
                    try{
                        & ("Get-" + $Module) |
                            Export-Csv -NoTypeInformation -Path ($Output + $Computer + "_" + $DateScannedFolder + "_" + $Module + ".csv")
                    }
                    catch{}
                }
            }
            else {
                $session = New-PSSession $Computer -ErrorAction SilentlyContinue

                if ($session -is [System.Management.Automation.Runspaces.PSSession]){
                    Remove-PSSession $session
                    
                    foreach ($Module in $Modules){
                        try {
                            Invoke-Command -ComputerName $Computer -SessionOption (New-PSSessionOption -NoMachineProfile) -ScriptBlock $ModuleCommandArray.$Module[0] -ArgumentList $ModuleCommandArray.$Module[1] | 
                            Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceID, PSShowComputerName | 
                            Export-Csv -NoTypeInformation -Path ($Output + $Computer + "_" + $DateScannedFolder + "_" + $Module + ".csv")
                        }
                        catch{}
                    }
                }
                else{
                    Write-Information -InformationAction Continue -MessageData ("Remote test failed: $Computer.`n")
                    
                    if ($Service -eq $false) {

                        $cred = Get-Credential "$Computer\"
    
                        foreach ($Module in $Modules){
                            try{
                                Invoke-Command -ComputerName $Computer -Credential $cred -SessionOption (New-PSSessionOption -NoMachineProfile) -ScriptBlock $ModuleCommandArray.$Module[0] -ArgumentList $ModuleCommandArray.$Module[1] | 
                                Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceID, PSShowComputerName | 
                                Export-Csv -NoTypeInformation -Path ($Output + $Computer + "_" + $DateScannedFolder + "_" + $Module + ".csv")
                            }
                            catch{}
                        }
                    }
                    else{
                        Write-Information -InformationAction Continue -MessageData ("Running as service, skipping {}.`n" -f $Computer)
                    }
                }
            }
        } catch{}

        $total++
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Started at {0}" -f $DateScanned)
        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}
