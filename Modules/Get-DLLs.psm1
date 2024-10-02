function Get-DLLs {
    <#
    .SYNOPSIS 
        Collects information on all DLLs that are currently loaded by any process on the system.

    .DESCRIPTION 
        Collects information on all DLLs that are currently loaded by any process on the system.

    .EXAMPLE 
        Get-DLLs

    .EXAMPLE
        Get-DLLs | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\DLLs.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-DLLs} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\DLLs.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-DLLs} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_DLLs.csv")
        }

    .NOTES 1
        Updated: 2024-10-02

        Contributing Authors:
            Anthony Phipps
            Jeremy Arnold
            
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
       https://github.com/TonyPhipps/Meerkat
       https://github.com/TonyPhipps/Meerkat/wiki/DLLs
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-DLLs at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $Processes = Get-Process | Select-Object Id, Path, Modules

        $ResultsArray = foreach ($Process in $Processes) {
            foreach ($Module in $Process.Modules){
                $Module | Add-Member -MemberType NoteProperty -Name "ProcessID" -Value $Process.Id -Force
                $Module | Add-Member -MemberType NoteProperty -Name "ProcessName" -Value $Process.Path -Force
                $Module | Select-Object FileName, ProcessName, ProcessID
            }
        }

        foreach ($Result in $ResultsArray){
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned 
            $Result | Add-Member -MemberType NoteProperty -Name "ModuleVersion" -Value $ModuleVersion
        }

        return $ResultsArray | Select-Object Host, DateScanned, FileName, ProcessName, ProcessID
    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ"))
    }
}
