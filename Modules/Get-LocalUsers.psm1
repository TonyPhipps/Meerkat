function Get-LocalUsers {
    <#
    .SYNOPSIS 
        Gets a list of local users and additional details.

    .DESCRIPTION 
        Gets a list of local users and additional details.

        Alternative: net.exe user
        Alternative: net.exe localgroup
        Alternative: net.exe localgroup administrators

    .EXAMPLE 
        Get-LocalUsers

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-LocalUsers} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\LocalUsers.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-LocalUsers} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_Users.csv")
        }

    .NOTES 
        Updated: 2023-06-16

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
       https://github.com/TonyPhipps/Meerkat/wiki/LocalUsers
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started Get-LocalUsers at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $ResultsArray = Get-LocalUser
        $GroupArray = Get-LocalGroup
        foreach ($Group in $GroupArray){
            $Group | Add-Member -MemberType NoteProperty -Name "Users" -Value ((Get-LocalGroupMember -Group $Group).Name -join ", ")
        }
            
        Foreach ($Result in $ResultsArray) {
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
            $Result | Add-Member -MemberType NoteProperty -Name "Groups" -Value (($GroupArray | Where-Object Users -Match $Result.Name).Name -join ", ")
        }

        return $ResultsArray | Select-Object Host, DateScanned, Name, Description, SID, PrincipalSource, ObjectClass, Groups, Enabled, FullName, PasswordChangeableDate, PasswordExpires, UserMayChangePassword, PasswordRequired, PasswordLastSet, LastLogon
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}
