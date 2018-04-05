function Invoke-THR {
    <#
    .SYNOPSIS 
        Performs threat hunting reconnaissance on one or more target systems.

    .DESCRIPTION 
        Performs threat hunting reconnaissance on one or more target systems.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER All
        Collect all possible results. Exlcusions like -Quick and -Micro are applied AFTER -All

    .PARAMETER Quick
        Excludes collections that are anticipated to take more than a few minutes to retrieve results.
    
    .PARAMETER Micro
        Excludes collections that are anticipated to consume more than about half a megabyte.

    .PARAMETER OutputPath  
        Specify a path to save results to. Default is the current working directory.

    .PARAMETER Ingest
        When used, an additional subfolder will me made under -Path for each collection type enabled. 
        Intended for use with products that ingest files, like ELK, Graylog, Splunk, etc.
        To speed up bulk collections, consider using a jobs manager like PoshRSJob 
        (https://github.com/proxb/PoshRSJob)
        A PoshRSJob wrapper is provided in the \Utilities folder of this project.

    .EXAMPLE
        Invoke-THR -All -Micro

    .EXAMPLE
        Invoke-THR -All -Ingest -Path C:\temp

    .EXAMPLE
        Invoke-THR -All -Quick -Path .\Results\

    .NOTES 
        Updated: 2018-04-04

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
        [String] $Path = $pwd,

        [Parameter()]
        [alias("Database","Index","Indexable","Ingestible")]
        [switch] $Ingest = $False,

        [Parameter()]
        $Port = "5985",

        [Parameter()]
        [switch] $All,

        [Parameter()]
        [alias("Fast")]
        [switch] $Quick,

        [Parameter()]
        [alias("Small")]
        [switch] $Micro,

        [Parameter()]
        [alias("Info")]
        [switch] $Computers,

        [Parameter()]
        [switch] $ADS,

        [Parameter()]
        [alias("ARPTable")]
        [switch] $ARP,

        [Parameter()]
        [alias("ATR","Autorun")]
        [switch] $Autoruns,

        [Parameter()]
        [alias("BTL")]
        [switch] $BitLocker,

        [Parameter()]
        [alias("DLL")]
        [switch] $DLLs,

        [Parameter()]
        [switch] $DNS,

        [Parameter()]
        [alias("DRV","Driver")]
        [switch] $Drivers,

        [Parameter()]
        [alias("VAR","Vars","EnvVar")]
        [switch] $EnvVars,

        [Parameter()]
        [alias("GRP","Groups","Members")]
        [switch] $GroupMembers,

        [Parameter()]
        [alias("HND","Handle")]
        [switch] $Handles,

        [Parameter()]
        [alias("HDW")]
        [switch] $Hardware,

        [Parameter()]
        [alias("HST","Hostfile")]
        [switch] $Hosts,

        [Parameter()]
        [alias("FIX","Fixes","Hotfix")]
        [switch] $Hotfixes,

        [Parameter()]
        [alias("NET","NetAdapter")]
        [switch] $NetAdapters,

        [Parameter()]
        [alias("RTE","Route")]
        [switch] $NetRoute,

        [Parameter()]
        [alias("PRT")]
        [switch] $Ports,

        [Parameter()]
        [alias("PRC","Process")]
        [switch] $Processes,

        [Parameter()]
        [alias("BIN","Recycler")]
        [switch] $RecycleBin,
        
        [Parameter()]
        [alias("REG","RegistryKeys")]
        [switch] $Registry,

        [Parameter()]
        [alias("Recent","RegistryMRU")]
        [switch] $MRU,

        [Parameter()]
        [alias("TSK","ScheduledTask","Tasks")]
        [switch] $ScheduledTasks,

        [Parameter()]
        [alias("SVC","Service")]
        [switch] $Services,

        [Parameter()]
        [alias("SSN","Session")]
        [switch] $Sessions,

        [Parameter()]
        [alias("SHR""Share")]
        [switch] $Shares,

        [Parameter()]
        [alias("SFW")]
        [switch] $Software,

        [Parameter()]
        [alias("STR","String")]
        [switch] $Strings,

        [Parameter()]
        [alias("LOG","EventLogs")]
        [switch] $Logs,

        [Parameter()]
        [switch] $TPM,

        [Parameter()]
        [alias("CER","Certs")]
        [switch] $Certificates
    )

    begin{
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        $Test=$null
        $Test = [bool](Test-WSMan -ComputerName $Computer -Port $Port -ErrorAction SilentlyContinue)

        If (!$Test){
            Write-Information -InformationAction Continue -MessageData ("Could not reach WinRM on {0} at port {1}" -f $Computer, $Port)
            break
        }
        else{
            Write-Information -InformationAction Continue -MessageData ("Successfully reached WinRM on {0} at port {1}" -f $Computer, $Port)
        }
    }

    process{
   
        if (!(Test-Path $Path)){
            mkdir $Path
        }

        $FilePath = $Path + "\"
        
        if ($All -or $Computers){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Computers\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Computer -Computer $Computer | Export-Csv ($FilePath + "Computer.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $ARP){
            
            if ($Ingest){
                
                $FilePath = $Path + "\ARP\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_ARP -Computer $Computer | Export-Csv ($FilePath + "ARP.csv") -NoTypeInformation -Append
        }

        if ($All -or $Autoruns){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Autoruns\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Autoruns -Computer $Computer | Export-Csv ($FilePath + "Autoruns.csv") -NoTypeInformation -Append
        }

        if ($All -or $BitLocker){
            
            if ($Ingest){
                
                $FilePath = $Path + "\BitLocker\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_BitLocker -Computer $Computer | Export-Csv ($FilePath + "BitLocker.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $DNS){
            
            if ($Ingest){
                
                $FilePath = $Path + "\DNS\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_DNS -Computer $Computer | Export-Csv ($FilePath + "DNS.csv") -NoTypeInformation -Append
        }

        if ($All -or $GroupMembers){
            
            if ($Ingest){
                
                $FilePath = $Path + "\GroupMembers\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_GroupMembers -Computer $Computer | Export-Csv ($FilePath + "GroupMembers.csv") -NoTypeInformation -Append
        }

        if ($All -or $Handles){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Handles\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Handles -Computer $Computer | Export-Csv ($FilePath + "Handles.csv") -NoTypeInformation -Append
        }

        if ($All -or $NetAdapters){
            
            if ($Ingest){
                
                $FilePath = $Path + "\NetAdapters\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_NetAdapters -Computer $Computer | Export-Csv ($FilePath + "NetAdapters.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $NetRoute){
            
            if ($Ingest){
                
                $FilePath = $Path + "\NetRoute\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_NetRoute -Computer $Computer | Export-Csv ($FilePath + "NetRoute.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $Ports){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Ports\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Ports -Computer $Computer | Export-Csv ($FilePath + "Ports.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $Processes){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Processes\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Processes -Computer $Computer | Export-Csv ($FilePath + "Processes.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $RecycleBin){
            
            if ($Ingest){
                
                $FilePath = $Path + "\RecycleBin\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_RecycleBin -Computer $Computer | Export-Csv ($FilePath + "RecycleBin.csv") -NoTypeInformation -Append
        }

        if ($All -or $Registry){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Registry\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Registry -Computer $Computer | Export-Csv ($FilePath + "Registry.csv") -NoTypeInformation -Append
        }

        if ($All -or $ScheduledTasks){
            
            if ($Ingest){
                
                $FilePath = $Path + "\ScheduledTasks\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_ScheduledTasks -Computer $Computer | Export-Csv ($FilePath + "ScheduledTasks.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $Services){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Services\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Services -Computer $Computer | Export-Csv ($FilePath + "Services.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $Sessions){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Sessions\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Sessions -Computer $Computer | Export-Csv ($FilePath + "Sessions.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $Shares){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Shares\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Shares -Computer $Computer | Export-Csv ($FilePath + "Shares.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $TPM){
            
            if ($Ingest){
                
                $FilePath = $Path + "\TPM\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_TPM -Computer $Computer | Export-Csv ($FilePath + "TPM.csv") -NoTypeInformation -Append
        }

        if ($All -or $Hosts){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Hosts\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Hosts -Computer $Computer | Export-Csv ($FilePath + "Hosts.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $Software){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Software\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Software -Computer $Computer | Export-Csv ($FilePath + "Software.csv") -NoTypeInformation -Append
        }
        
        if ($All -or $EnvVars){
            
            if ($Ingest){
                
                $FilePath = $Path + "\EnvVars\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_EnvVars -Computer $Computer | Export-Csv ($FilePath + "EnvVars.csv") -NoTypeInformation -Append
        }

        if ($All -or $MRU){
            
            if ($Ingest){
                
                $FilePath = $Path + "\MRU\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_MRU -Computer $Computer | Export-Csv ($FilePath + "MRU.csv") -NoTypeInformation -Append
        }

        if ($All -or $Drivers){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Drivers\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Drivers -Computer $Computer | Export-Csv ($FilePath + "Drivers.csv") -NoTypeInformation -Append
        }

        if ($All -or $Hotfixes){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Hotfixes\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Hotfixes -Computer $Computer | Export-Csv ($FilePath + "Hotfixes.csv") -NoTypeInformation -Append
        }

        if ($All -or $Hardware){
            
            if ($Ingest){

                $FilePath = $Path + "\Hardware\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Hardware -Computer $Computer | Export-Csv ($FilePath + "Hardware.csv") -NoTypeInformation -Append
        }

        if ($All -or $Certificates){
            
            if ($Ingest){
                
                $FilePath = $Path + "\Certificates\"                
                if (!(Test-Path $FilePath)){ mkdir $FilePath }
                $FilePath = $FilePath + $Computer + "_"
            }

            Get-THR_Certificates -Computer $Computer | Export-Csv ($FilePath + "Certificates.csv") -NoTypeInformation -Append            
        }

        if ($All -or $DLLs){
            
            if (!$Micro) {
                
                if ($Ingest){
                    
                    $FilePath = $Path + "\DLLs\"                
                    if (!(Test-Path $FilePath)){ mkdir $FilePath }
                    $FilePath = $FilePath + $Computer + "_"
                }
    
                Get-THR_DLLs -Computer $Computer | Export-Csv ($FilePath + "DLLs.csv") -NoTypeInformation -Append
            }
        }

        if ($All -or $ADS){
            
            if (!$Quick) {
               
                if ($Ingest){
                    
                    $FilePath = $Path + "\ADS\"                
                    if (!(Test-Path $FilePath)){ mkdir $FilePath }
                    $FilePath = $FilePath + $Computer + "_"
                }
    
                Get-THR_ADS -Computer $Computer | Export-Csv ($FilePath + "ADS.csv") -NoTypeInformation -Append
            }
        }

        if ($All -or $Strings){
            
            if (!$Quick) {
                
                if ($Ingest){
                    
                    $FilePath = $Path + "\Strings\"                
                    if (!(Test-Path $FilePath)){ mkdir $FilePath }
                    $FilePath = $FilePath + $Computer + "_"
                }

                Get-THR_Strings -Computer $Computer | Export-Csv ($FilePath + "Strings.csv") -NoTypeInformation -Append
            }
        }

        if ($All -or $Logs){
            
            if (!$Quick -and !$Micro) {
                
                if ($Ingest){
                    
                    $FilePath = $Path + "\EventLogs\"                
                    if (!(Test-Path $FilePath)){ mkdir $FilePath }
                    $FilePath = $FilePath + $Computer + "_"
                }

                Get-THR_EventLogs -Computer $Computer | Export-Csv ($FilePath + "EventLogs.csv") -NoTypeInformation -Append
            }
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