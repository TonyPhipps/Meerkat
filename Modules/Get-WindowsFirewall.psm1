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
        Updated: 2024-06-03

        Contributing Authors:
            Anthony Phipps, Jack Smith
            
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
    #>


    [cmdletbinding()]
    param(
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-WindowsFirewall at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()          
    }

    process{

        $netsh = netsh advfirewall firewall show rule name=all verbose | Out-String
        $rulesArray = $netsh -split("\r\n\r\n") 

        $ResultsArray = foreach ($rule in $rulesArray) {
            if ($rule -match "Rule Name:") {
                $RuleName = ($rule | Select-String -Pattern "Rule Name: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $Enabled = ($rule | Select-String -Pattern "Enabled: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $Direction = ($rule | Select-String -Pattern "Direction: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $Profiles = ($rule | Select-String -Pattern "Profiles: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $Grouping = ($rule | Select-String -Pattern "Grouping: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $LocalIP = ($rule | Select-String -Pattern "LocalIP: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $RemoteIP = ($rule | Select-String -Pattern "RemoteIP: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $Protocol = ($rule | Select-String -Pattern "Protocol: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $EdgeTraversal = ($rule | Select-String -Pattern "Edge traversal: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $InterfaceTypes = ($rule | Select-String -Pattern "InterfaceTypes: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $Security = ($rule | Select-String -Pattern "Security: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $RuleSource = ($rule | Select-String -Pattern "Rule source: +([^\r\n]+)").Matches.Groups[1].Value.Trim()
                $Action = ($rule | Select-String -Pattern "Action: +([^\r\n]+)").Matches.Groups[1].Value.Trim()

                if ($rule -match "LocalPort: +([^\r\n]+)") { $LocalPort = ($rule | Select-String -Pattern "LocalPort: +([^\r\n]+)").Matches.Groups[1].Value.Trim() }
                if ($rule -match "Description: +([^\r\n]+)") { $Description = ($rule | Select-String -Pattern "Description: +([^\r\n]+)").Matches.Groups[1].Value.Trim() }
                if ($rule -match "RemotePort: +([^\r\n]+)") { $RemotePort = ($rule | Select-String -Pattern "RemotePort: +([^\r\n]+)").Matches.Groups[1].Value.Trim() }
                if ($rule -match "Program: +([^\r\n]+)") { $Program = ($rule | Select-String -Pattern "Program: +([^\r\n]+)").Matches.Groups[1].Value.Trim() }
                if ($rule -match "Service: +([^\r\n]+)") { $Service = ($rule | Select-String -Pattern "Service: +([^\r\n]+)").Matches.Groups[1].Value.Trim() }
                
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
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ"))
    }
}
