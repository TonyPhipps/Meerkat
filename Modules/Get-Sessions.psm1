function Get-Sessions {
    <#
    .SYNOPSIS 
        Gets login sessions.

    .DESCRIPTION 
        Gets login sessions utizling the builtin "qwinsta.exe" tool.

    .EXAMPLE 
        Get-Sessions

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Sessions} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Sessions.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-Sessions} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_Sessions.csv")
        }

    .NOTES 
        Updated: 2023-12-04

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
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-Sessions at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{
    
        $first = 1
        $ResultsArray = qwinsta 2>$null | ForEach-Object {
            if ($first -eq 1) {
                $userPos = $_.IndexOf("USERNAME")
                $sessionPos = $_.IndexOf("SESSIONNAME")  # max length 15
                $idPos = $_.IndexOf("ID") - 2  # id is right justified
                $statePos = $_.IndexOf("STATE") # max length 6
                $typePos = $_.IndexOf("TYPE")  # right justified too 
                $devicePos = $_.IndexOf("DEVICE")
                $first = 0
            }
            else {
                $user = $_.substring($userPos,$userPos-$sessionPos).Trim()
                $session = $_.substring($sessionPos,$userPos-$sessionPos).Trim()
                $id = [int]$_.substring($idPos,$statePos-$idPos).Trim()
                $state = $_.substring($statePos,$typePos-$statePos).Trim()
                $type = $_.substring($typePos,$devicePos-$typePos).Trim()
                $device = $_.substring($devicePos,$_.length-$devicePos).Trim()
        
                [pscustomobject]@{
                    SessionName = $session;
                    UserName = $user;
                    ID = $id;
                    State = $state;
                    Type = $type;
                    Device = $device}
            }
        }

        foreach ($Result in $ResultsArray) {

            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
        }

        return $ResultsArray | Select-Object Host, DateScanned, SessionName, UserName, ID, State, Type, Device
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}
