function Get-EventsUserManagement {
    <#
    .SYNOPSIS
        Gets account management events within specified time frame. Defaults to now and the last 60 days.

    .DESCRIPTION
        Gets account management events within specified time frame. Defaults to now and the last 60 days.
        4720: A user account was created
        4726: A user account was deleted
        4732: A member was added to a security-enabled local group
        4733: A member was removed from a security-enabled local group
        4781: The name of an account was changed

    .PARAMETER StartTime
        Specify when to begin event log collection. Defaults to 7 days ago based on system time.
        
    .PARAMETER EndTime
        Specify when to end account management event collection. Defaults to current time on system time.

    .EXAMPLE 
        Get-EventsUserManagement

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-EventsUserManagement} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\EventsUserManagement.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-EventsUserManagement} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_EventsUserManagement.csv")
        }

    .NOTES
        Updated: 2022-11-21

        Contributing Authors:
            Anthony Phipps, Jack Smith
            
        LEGAL: Copyright (C) 2022
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
       https://github.com/TonyPhipps/Meerkat/wiki/EventsUserManagement
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [datetime] $StartTime,

        [Parameter()]
        [datetime] $EndTime
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started Get-EventsUserManagement at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        if(!($StartTime)){
            $StartTime = (Get-Date) - (New-TimeSpan -Days 7)
        }

        if(!($EndTime)){
            $EndTime = (Get-Date)
        }

        function Get-UserName_Property($Result) {
            switch ($Result.ID) {
                4720 { $Result.Properties[4].Value }
                4726 { $Result.Properties[4].Value }
                4732 { $Result.Properties[6].Value }
                4733 { $Result.Properties[6].Value }
                4781 { $Result.Properties[5].Value }
            }     
        }

        function Get-SourceName_Property($Result) {
            switch ($Result.ID) {
                4781 { $Result.Properties[0].Value }
                default { "" }
            }     
        }

        function Get-TargetName_Property($Result) {
            switch ($Result.ID) {
                4720 { $Result.Properties[0].Value }
                4726 { $Result.Properties[0].Value }
                4732 { 
                    try{
                        $SID = New-Object System.Security.Principal.SecurityIdentifier($Result.Properties[1].Value.Value)
                        $objUser = $SID.Translate([System.Security.Principal.NTAccount])
                        $objUser.Value
                    }
                    catch {"SID UNRESOLVABLE"}
                }
                4733 {
                    try{
                        $SID = New-Object System.Security.Principal.SecurityIdentifier($Result.Properties[1].Value.Value)
                        $objUser = $SID.Translate([System.Security.Principal.NTAccount])
                        $objUser.Value
                    }
                    catch {"SID UNRESOLVABLE"}
                }
                4781 { $Result.Properties[1].Value }
            }     
        }

        function Get-TargetSID_Property($Result) {
            switch ($Result.ID) {
                4720 { $Result.Properties[2].Value }
                4726 { $Result.Properties[2].Value }
                4732 { $Result.Properties[1].Value }
                4733 { $Result.Properties[1].Value }
                4781 { $Result.Properties[3].Value }
            }     
        }
        
        function Get-Domain_Property($Result) {
            switch ($Result.ID) {
                4720 { $Result.Properties[1].Value }
                4726 { $Result.Properties[1].Value }
                4732 { $Result.Properties[3].Value }
                4733 { $Result.Properties[3].Value }
                4781 { $Result.Properties[2].Value }
            }     
        }

        function Get-Group_Property($Result) {
            switch ($Result.ID) {
                4732 { $Result.Properties[2].Value }
                4733 { $Result.Properties[2].Value }
                default { "" }
            }     
        }
        
    }

    process{

        $EventID = 4720, 4726, 4732, 4733, 4781
        
        $ResultsArray = Get-WinEvent -FilterHashtable @{ LogName="Security"; ID = $EventID } 
        
            foreach ($Result in $ResultsArray) {
     
                $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
                $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned

                $Result | Add-Member -MemberType NoteProperty -Name "UserName" -Value (Get-UserName_Property($Result))
                $Result | Add-Member -MemberType NoteProperty -Name "SourceName" -Value (Get-SourceName_Property($Result))
                $Result | Add-Member -MemberType NoteProperty -Name "TargetName" -Value (Get-TargetName_Property($Result))
                $Result | Add-Member -MemberType NoteProperty -Name "TargetSID" -Value (Get-TargetSID_Property($Result))
                $Result | Add-Member -MemberType NoteProperty -Name "Domain" -Value (Get-Domain_Property($Result))
                $Result | Add-Member -MemberType NoteProperty -Name "Group" -Value (Get-Group_Property($Result))
                
                $Result.Message = $Result.Message.Split([System.Environment]::NewLine)[0]
            }
        
            return $ResultsArray | Select-Object Host, DateScanned, TimeCreated, ID, Message, UserName, SourceName, TargetName, TargetSID, Domain, Group, RecordId

        }
    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}