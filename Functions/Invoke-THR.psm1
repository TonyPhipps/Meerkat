function Invoke-THR {
    <#
    .SYNOPSIS 
        Performs threat hunting reconnaissance on one or more target systems.

    .DESCRIPTION 
        Performs threat hunting reconnaissance on one or more target systems.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Path  
        Specify a path to save results to. Default is the current working directory.

    .EXAMPLE 
        

    .NOTES 
        Updated: 2018-02-18

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
        $OutputPath = $pwd,

        [Parameter()]
        $Port,

        [Parameter()]
        [switch] $All,

        [Parameter()]
        [alias("Fast")]
        [switch] $Quick,

        [Parameter()]
        [alias("Small")]
        [switch] $Micro,

        [Parameter()]
        [switch] $Info,

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
        [switch] $TPM
    )

    begin{
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        if (!$Port) {
            $Port = "5985"
        }

        $Test=$null
        $Test = [bool](Test-WSMan -ComputerName $Computer -Port $Port -UseSSL -ErrorAction SilentlyContinue)

        If(!$Test){
            $Test = [bool](Test-WSMan -ComputerName $Computer -Port $Port -ErrorAction SilentlyContinue)
        }
        else{
            Write-Information -InformationAction Continue -MessageData ("Successfully reached WinRM on {0} at port {1}" -f $Computer, $Port)
            $SLL = $True
        }

        If (!$Test){
            Write-Information -InformationAction Continue -MessageData ("Could not reach WinRM on {0} at port {1}" -f $Computer, $Port)
            break
        }
        else{
            Write-Information -InformationAction Continue -MessageData ("Successfully reached WinRM on {0} at port {1}" -f $Computer, $Port)
        }
    }

    process{
        
        if ($All -or $Computers){
            Get-THR_Computer -Computer $Computer | Export-Csv "Computer.csv" -NoTypeInformation -Append
        }

        if ($All -or $ADS){
            if (!$Quick) {
                Get-THR_ADS -Computer $Computer | Export-Csv "ADS.csv" -NoTypeInformation -Append
            }
        }
        
        if ($All -or $ARP){
            Get-THR_ARP -Computer $Computer | Export-Csv "ARP.csv" -NoTypeInformation -Append
        }

        if ($All -or $Autoruns){
        Get-THR_Autoruns -Computer $Computer | Export-Csv "Autoruns.csv" -NoTypeInformation -Append
        }

        if ($All -or $BitLocker){
        Get-THR_BitLocker -Computer $Computer | Export-Csv "BitLocker.csv" -NoTypeInformation -Append
        }

        if ($All -or $DLLs){
            if (!$Micro) {
                Get-THR_DLLs -Computer $Computer | Export-Csv "DLLs.csv" -NoTypeInformation -Append
            }
        }
        
        if ($All -or $DNS){
        Get-THR_DNS -Computer $Computer | Export-Csv "DNS.csv" -NoTypeInformation -Append
        }

        if ($All -or $Drivers){
            Get-THR_Drivers -Computer $Computer | Export-Csv "Drivers.csv" -NoTypeInformation -Append
        }

        if ($All -or $EnvVars){
            Get-THR_EnvVars -Computer $Computer | Export-Csv "EnvVars.csv" -NoTypeInformation -Append
        }

        if ($All -or $GroupMembers){
            Get-THR_GroupMembers -Computer $Computer | Export-Csv "GroupMembers.csv" -NoTypeInformation -Append
        }

        if ($All -or $Handles){
            Get-THR_Handles -Computer $Computer | Export-Csv "Handles.csv" -NoTypeInformation -Append
        }

        if ($All -or $Hardware){
            Get-THR_Hardware -Computer $Computer | Export-Csv "Hardware.csv" -NoTypeInformation -Append
        }

        if ($All -or $Hosts){
            Get-THR_Hosts -Computer $Computer | Export-Csv "Hosts.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $Hotfixes){
            Get-THR_Hotfixes -Computer $Computer | Export-Csv "Hotfixes.csv" -NoTypeInformation -Append
        }

        if ($All -or $NetAdapters){
            Get-THR_NetAdapters -Computer $Computer | Export-Csv "NetAdapters.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $NetRoute){
            Get-THR_NetRoute -Computer $Computer | Export-Csv "NetRoute.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $Ports){
            Get-THR_Ports -Computer $Computer | Export-Csv "Ports.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $Processes){
            Get-THR_Processes -Computer $Computer | Export-Csv "Processes.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $RecycleBin){
            Get-THR_RecycleBin -Computer $Computer | Export-Csv "RecycleBin.csv" -NoTypeInformation -Append
        }

        if ($All -or $Registry){
            Get-THR_RegistryKeys -Computer $Computer | Export-Csv "RegistryKeys.csv" -NoTypeInformation -Append
        }

        if ($All -or $ScheduledTasks){
            Get-THR_ScheduledTasks -Computer $Computer | Export-Csv "ScheduledTasks.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $Services){
            Get-THR_Services -Computer $Computer | Export-Csv "Services.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $Sessions){
            Get-THR_Sessions -Computer $Computer | Export-Csv "Sessions.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $Shares){
            Get-THR_Shares -Computer $Computer | Export-Csv "Shares.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $Software){
            Get-THR_Software -Computer $Computer | Export-Csv "Software.csv" -NoTypeInformation -Append
        }
        
        if ($All -or $Strings){
            if (!$Quick) {
                Get-THR_Strings -Computer $Computer | Export-Csv "Strings.csv" -NoTypeInformation -Append
            }
        }
        
        if ($All -or $TPM){
            Get-THR_TPM -Computer $Computer | Export-Csv "TPM.csv" -NoTypeInformation -Append
        }

        if ($All -or $Logs){
            if (!$Quick -and !$Micro) {
                Get-THR_EventLogs -Computer $Computer | Export-Csv "EventLogs.csv" -NoTypeInformation -Append
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