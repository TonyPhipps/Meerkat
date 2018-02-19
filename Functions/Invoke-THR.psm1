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
        $OutputPath = ".\",

        [Parameter()]
        $Options = "all"
    )

    begin{
        $DateScanned = Get-Date -Format u
        Write-Verbose "Started at $DateScanned"

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        $FullOutputPath = $OutputPath + $("\{1}" -f $(Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"))
        
        if (!(Test-Path $FullOutputPath -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $FullOutputPath
        }
    }

    process{
        
        if (($Options -like "all") -or ($Options -like "*pc*")){
            Get-THR_Computer -Computer $Computer | Export-Csv $FullOutputPath\Computer.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*ads*")){
            Get-THR_ADS -Computer $Computer | Export-Csv $FullOutputPath\ADS.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*arp*")){
            Get-THR_ARP -Computer $Computer | Export-Csv $FullOutputPath\ARP.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*atr*")){
        Get-THR_Autoruns -Computer $Computer | Export-Csv $FullOutputPath\Autoruns.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*btl*")){
        Get-THR_BitLocker -Computer $Computer | Export-Csv $FullOutputPath\BitLocker.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*dll*")){
            Get-THR_DLLs -Computer $Computer | Export-Csv $FullOutputPath\DLLs.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*dns*")){
        Get-THR_DNS -Computer $Computer | Export-Csv $FullOutputPath\DNS.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*drv*")){
            Get-THR_Drivers -Computer $Computer | Export-Csv $FullOutputPath\Drivers.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*var*")){
            Get-THR_EnvVars -Computer $Computer | Export-Csv $FullOutputPath\EnvVars.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*grp*")){
            Get-THR_GroupMembers -Computer $Computer | Export-Csv $FullOutputPath\GroupMembers.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*hdl*")){
            Get-THR_Handles -Computer $Computer | Export-Csv $FullOutputPath\Handles.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*hdw*")){
            Get-THR_Hardware -Computer $Computer | Export-Csv $FullOutputPath\Hardware.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*hst*")){
            Get-THR_Hosts -Computer $Computer | Export-Csv $FullOutputPath\Hosts.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*hfx*")){
            Get-THR_Hotfixes -Computer $Computer | Export-Csv $FullOutputPath\Hotfixes.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*nta*")){
            Get-THR_NetAdapters -Computer $Computer | Export-Csv $FullOutputPath\NetAdapters.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*ntr*")){
            Get-THR_NetRoute -Computer $Computer | Export-Csv $FullOutputPath\NetRoute.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*prt*")){
            Get-THR_Ports -Computer $Computer | Export-Csv $FullOutputPath\Ports.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*prc*")){
            Get-THR_Processes -Computer $Computer | Export-Csv $FullOutputPath\Processes.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*rcb*")){
            Get-THR_RecycleBin -Computer $Computer | Export-Csv $FullOutputPath\RecycleBin.csv -NoTypeInformation -Append
        }

        if (($Options -like "all") -or ($Options -like "*sch*")){
            Get-THR_ScheduledTasks -Computer $Computer | Export-Csv $FullOutputPath\ScheduledTasks.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*srv*")){
            Get-THR_Services -Computer $Computer | Export-Csv $FullOutputPath\Services.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*ssn*")){
            Get-THR_Sessions -Computer $Computer | Export-Csv $FullOutputPath\Sessions.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*shr*")){
            Get-THR_Shares -Computer $Computer | Export-Csv $FullOutputPath\Shares.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*sfw*")){
            Get-THR_Software -Computer $Computer | Export-Csv $FullOutputPath\Software.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*str*")){
            Get-THR_Strings -Computer $Computer | Export-Csv $FullOutputPath\Strings.csv -NoTypeInformation -Append
        }
        
        if (($Options -like "all") -or ($Options -like "*tpm*")){
            Get-THR_TPM -Computer $Computer | Export-Csv $FullOutputPath\TPM.csv -NoTypeInformation -Append
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