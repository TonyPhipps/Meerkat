function Get-Software {
    <#
    .SYNOPSIS 
        Gets installed software.

    .DESCRIPTION 
        Gets installed software.

    .EXAMPLE 
        Get-Software

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Software} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Software.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-Software} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_Software.csv")
        }

    .NOTES 
        Updated: 2023-12-21

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
        Write-Information -InformationAction Continue -MessageData ("Started Get-Software at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start() 
    }

    process{
            
        $pathAllUser = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $pathAllUser32 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
            
        $SystemResultsArray = Get-ItemProperty -Path $pathAllUser, $pathAllUser32 | Where-Object DisplayName -ne $null

        $UsersResultsArray = @()
        $32BitPath = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $64BitPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

        $AllProfiles = Get-CimInstance Win32_UserProfile | Select-Object LocalPath, SID, Loaded, Special | Where-Object {$_.SID -like "S-1-5-21-*"}
        $MountedProfiles = $AllProfiles | Where-Object {$_.Loaded -eq $true}
        $UnmountedProfiles = $AllProfiles | Where-Object {$_.Loaded -eq $false}

        # Processing mounted hives
        $MountedProfiles | ForEach-Object {
            $UsersResultsArray += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$32BitPath"
            $UsersResultsArray += Get-ItemProperty -Path "Registry::\HKEY_USERS\$($_.SID)\$64BitPath"
        }

        # Processing unmounted hives
        $UnmountedProfiles | ForEach-Object {

            $Hive = "$($_.LocalPath)\NTUSER.DAT"

            if (Test-Path $Hive) {
                    
                REG LOAD HKU\temp $Hive > $null

                $UsersResultsArray += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$32BitPath"
                $UsersResultsArray += Get-ItemProperty -Path "Registry::\HKEY_USERS\temp\$64BitPath"

                # Run manual GC to allow hive to be unmounted
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
                    
                REG UNLOAD HKU\temp *> $null

            } else {
                Write-Warning "Unable to access registry hive at $Hive"
            }
        }

        $ResultsArray = $SystemResultsArray + $UsersResultsArray

        foreach ($Result in $ResultsArray) {

            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned 
            $Result | Add-Member -MemberType NoteProperty -Name "ModuleVersion" -Value $ModuleVersion
            $Result.PSParentPath = ($Result.PSParentPath -Split "::\\")[1]
        }

        return $ResultsArray | Select-Object Host, DateScanned, Publisher, DisplayName, DisplayVersion, InstallDate, 
        InstallSource, InstallLocation, PSChildName, PSParentPath, HelpLink
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}
