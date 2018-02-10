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
        Updated: 2018-02-08

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
        $OutputPath = "C:\Temp",

        [Parameter()]
        [switch]$Bulk
    );

    begin{
        $FullOutputPath = $OutputPath + $("\{0}_{1}" -f $Computer, $(Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"));
        
        if (!(Test-Path $FullOutputPath -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $FullOutputPath;
        };
    };

    process{
        
        Get-THR_Computer -Computer $Computer | Export-Csv $FullOutputPath\Computer.csv -NoTypeInformation;
        
        Get-THR_ADS -Computer $Computer | Export-Csv $FullOutputPath\ADS.csv -NoTypeInformation;
        Get-THR_ARP -Computer $Computer | Export-Csv $FullOutputPath\ARP.csv -NoTypeInformation;
        Get-THR_Autoruns -Computer $Computer | Export-Csv $FullOutputPath\Autoruns.csv -NoTypeInformation;
        Get-THR_BitLocker -Computer $Computer | Export-Csv $FullOutputPath\BitLocker.csv -NoTypeInformation;
        Get-THR_DLLs -Computer $Computer | Export-Csv $FullOutputPath\DLLs.csv -NoTypeInformation;
        Get-THR_DNS -Computer $Computer | Export-Csv $FullOutputPath\DNS.csv -NoTypeInformation;
        Get-THR_Drivers -Computer $Computer | Export-Csv $FullOutputPath\Drivers.csv -NoTypeInformation;
        Get-THR_EnvVars -Computer $Computer | Export-Csv $FullOutputPath\EnvVars.csv -NoTypeInformation;
        Get-THR_GroupMembers -Computer $Computer | Export-Csv $FullOutputPath\GroupMembers.csv -NoTypeInformation;
        Get-THR_Handles -Computer $Computer | Export-Csv $FullOutputPath\Handles.csv -NoTypeInformation;
        Get-THR_Hardware -Computer $Computer | Export-Csv $FullOutputPath\Hardware.csv -NoTypeInformation;
        Get-THR_Hosts -Computer $Computer | Export-Csv $FullOutputPath\Hosts.csv -NoTypeInformation;
        Get-THR_Hotfixes -Computer $Computer | Export-Csv $FullOutputPath\Hotfixes.csv -NoTypeInformation;
        Get-THR_NetAdapters -Computer $Computer | Export-Csv $FullOutputPath\NetAdapters.csv -NoTypeInformation;
        Get-THR_NetRoute -Computer $Computer | Export-Csv $FullOutputPath\NetRoute.csv -NoTypeInformation;
        Get-THR_Ports -Computer $Computer | Export-Csv $FullOutputPath\Ports.csv -NoTypeInformation;
        Get-THR_Processes -Computer $Computer | Export-Csv $FullOutputPath\Processes.csv -NoTypeInformation;
        Get-THR_RecycleBin -Computer $Computer | Export-Csv $FullOutputPath\RecycleBin.csv -NoTypeInformation;
        Get-THR_ScheduledTasks -Computer $Computer | Export-Csv $FullOutputPath\ScheduledTasks.csv -NoTypeInformation;
        Get-THR_Services -Computer $Computer | Export-Csv $FullOutputPath\Services.csv -NoTypeInformation;
        Get-THR_Sessions -Computer $Computer | Export-Csv $FullOutputPath\Sessions.csv -NoTypeInformation;
        Get-THR_Shares -Computer $Computer | Export-Csv $FullOutputPath\Shares.csv -NoTypeInformation;
        Get-THR_Software -Computer $Computer | Export-Csv $FullOutputPath\Software.csv -NoTypeInformation;
        Get-THR_Strings -Computer $Computer | Export-Csv $FullOutputPath\Strings.csv -NoTypeInformation;
        Get-THR_TPM -Computer $Computer | Export-Csv $FullOutputPath\TPM.csv -NoTypeInformation;
    };

    end{

    };
};