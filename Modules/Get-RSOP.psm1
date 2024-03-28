function Get-RSOP {
    <#
    .SYNOPSIS 
        Gets Resultant Set of Policy settings specific to security.

    .DESCRIPTION 
        Gets Resultant Set of Policy settings specific to security.
  

    .EXAMPLE 
        Get-RSOP

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-RSOP} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\RSOP.csv")

    .EXAMPLE
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-RSOP} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_RSOP.csv")
        }

    .NOTES 
        Updated: 2024-03-27

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2024
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
       https://git.bor.doi.net:8081/ics-security-operations/REC
       https://github.com/TonyPhipps/Meerkat
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-RSOP at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $ResultsArray = Get-CIMinstance -Namespace "root\rsop\computer"  -Query "select *  from rsop_securitysettings" |  
            Select-Object GPOID, id, precedence, ErrorCode, Status, OriginalPath, 
                @{name="AccountList";expression={$_.AccountList -join ", "}}, 
                UserRight, Data, Path, Type, KeyName, Setting, SDDLString, Service, StartupMode, GroupName, 
                @{name="Members";expression={$_.Members -join ", "}}, 
                @{name="MemberOf";expression={$_.MemberOf -join ", "}}, 
                Category, Failure, Success

        foreach ($Result in $ResultsArray) {
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
        }

        return $ResultsArray | 
            Select-Object Host, DateScanned, GPOID, id, precedence, ErrorCode, Status, 
            OriginalPath, AccountList, UserRight, Data, Path, Type, KeyName, Setting, SDDLString, Service, StartupMode, GroupName, 
            Members, MemberOf, Category, Failure, Success | 
                Sort-Object OriginalPath, AccountList, UserRight, Data, Path, Type, KeyName, Setting, SDDLString, Service, 
                StartupMode, GroupName, Members, MemberOf, Category, Failure, Success

    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Started at {0}" -f $DateScanned)
        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}
