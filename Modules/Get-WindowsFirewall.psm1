Function Get-WindowsFirewall {
    <#
    .SYNOPSIS 
        Retreives all Windows Firewall rules.
    
    .DESCRIPTION
        Retreives all Windows Firewall rules.
    
    .EXAMPLE 
        Get-WindowsFirewall

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-WindowsFirewall} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\WindowsFirewall.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-WindowsFirewall} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_WindowsFirewall.csv")
        }
    
     .NOTES 
        Updated: 2022-11-22

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
    #>


    [cmdletbinding()]
    param(
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started Get-WindowsFirewall at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()          
    }

    process{

        $netsh = netsh advfirewall firewall show rule name=all verbose | Out-String
        $rulesArray = $netsh -split("\r\n\r\n") 

        $ResultsArray = foreach ($rule in $rulesArray) {
            if ($rule -match "Rule Name:") {
                $RuleName = ($rule | Select-String -Pattern "Rule Name: +(.+)").Matches.Groups[1].Value
                $Description = try{($rule | Select-String -Pattern "Description: +(.+)").Matches.Groups[1].Value} catch{""}
                $Enabled = ($rule | Select-String -Pattern "Enabled: +(.+)").Matches.Groups[1].Value
                $Direction = ($rule | Select-String -Pattern "Direction: +(.+)").Matches.Groups[1].Value
                $Profiles = ($rule | Select-String -Pattern "Profiles: +(.+)").Matches.Groups[1].Value
                $Grouping = ($rule | Select-String -Pattern "Grouping: +(.+)").Matches.Groups[1].Value
                $LocalIP = ($rule | Select-String -Pattern "LocalIP: +(.+)").Matches.Groups[1].Value
                $RemoteIP = ($rule | Select-String -Pattern "RemoteIP: +(.+)").Matches.Groups[1].Value
                $Protocol = ($rule | Select-String -Pattern "Protocol: +(.+)").Matches.Groups[1].Value
                $LocalPort = try{($rule | Select-String -Pattern "LocalPort: +(.+)").Matches.Groups[1].Value} catch{""}
                $RemotePort = try{($rule | Select-String -Pattern "RemotePort: +(.+)").Matches.Groups[1].Value} catch{""}
                $EdgeTraversal = ($rule | Select-String -Pattern "Edge traversal: +(.+)").Matches.Groups[1].Value
                $Program = try{($rule | Select-String -Pattern "Program: +(.+)").Matches.Groups[1].Value} catch{""}
                $Service = try{($rule | Select-String -Pattern "Service: +(.+)").Matches.Groups[1].Value} catch{""}
                $InterfaceTypes = ($rule | Select-String -Pattern "InterfaceTypes: +(.+)").Matches.Groups[1].Value
                $Security = ($rule | Select-String -Pattern "Security: +(.+)").Matches.Groups[1].Value
                $RuleSource = ($rule | Select-String -Pattern "Rule source: +(.+)").Matches.Groups[1].Value
                $Action = ($rule | Select-String -Pattern "Action: +(.+)").Matches.Groups[1].Value

                $RuleObject = [PSCustomObject]@{
                    RuleName = $RuleName
                    Description = $Description
                    Enabled = $Enabled
                    Direction = $Direction
                    Profiles = $Profiles
                    Grouping = $Grouping
                    LocalIP = $LocalIP
                    RemoteIP = $RemoteIP
                    Protocol = $Protocol
                    LocalPort = $LocalPort
                    RemotePort = $RemotePort
                    EdgeTraversal = $EdgeTraversal
                    Program = $Program
                    Service = $Service
                    InterfaceTypes = $InterfaceTypes
                    Security = $Security
                    RuleSource = $RuleSource
                    Action = $Action
                }

                $RuleObject
            }
        }

        foreach ($Result in $ResultsArray) {
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
        }

        return $ResultsArray | Select-Object Host, DateScanned, Direction, RuleName, Grouping, Profiles, Enabled, Action, Program, LocalIP, RemoteIP, Protocol, LocalPort, RemotePort, EdgeTraversal, InterfaceTypes, Security, RuleSource, Description
    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}