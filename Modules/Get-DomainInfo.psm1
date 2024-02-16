Function Get-DomainInfo {
    <#
    .SYNOPSIS
        Checks domain health, replication, and DNS status.
    .DESCRIPTION
        Checks domain health, replication, and DNS status. 
        Native AD commands including repadmin, dsquery, and dcdiag or a comparable 
        PowerShell cmdlet are used to query domain meta data. 
    .EXAMPLE 
        Get-DomainInfo
    .EXAMPLE
        Get-DomainInfo | 
        Export-Csv -NoTypeInformation ("c:\temp\DomainInfo.csv")
    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Computer} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\DomainInfo.csv")
    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-DomainInfo} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_DomainInfo.csv")
        }
    .NOTES
        Updated: 2024-02-16
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
       https://github.com/TonyPhipps/Meerkat/wiki/DomainInfo
    #>

    [CmdletBinding()]
    param(
    )

    begin{



        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-DomainInfo at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $ResultsArray = New-Object -TypeName PSObject

        $GetADForest = Get-ADForest
        foreach ($Property in $GetADForest.PSObject.Properties) {
            $ResultsArray | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.value -ErrorAction SilentlyContinue
        }

        $GetADomain = Get-ADDomain 
        foreach ($Property in $GetADomain.PSObject.Properties) {
            $ResultsArray | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.value -ErrorAction SilentlyContinue
        }  

        $GetADObject = Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion
        foreach ($Property in $GetADomain.PSObject.Properties) {
            $ResultsArray | Add-Member -MemberType NoteProperty -Name 'objectVersion' -Value $GetADObject.objectVersion -ErrorAction SilentlyContinue
        } 

        $GetADReplication = Get-ADReplicationPartnerMetadata -Target $ResultsArray.DNSRoot
        foreach ($Property in $GetADReplication.PSObject.Properties) {
            $ResultsArray | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.value -ErrorAction SilentlyContinue
        }

        $ADDefaultDomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy
        foreach ($Property in $ADDefaultDomainPasswordPolicy.PSObject.Properties) {
            $ResultsArray | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.value -ErrorAction SilentlyContinue
        }  

        $DCDiag = dcdiag /s:$env:COMPUTERNAME
        $DCDiag | select-string -pattern '\. (.*) \b(passed|failed)\b test (.*)' | foreach {
            $output = [pscustomobject] @{
                TestName = $_.Matches.Groups[3].Value
                TestResult = $_.Matches.Groups[2].Value
            }
            $ResultsArray | Add-Member -MemberType NoteProperty -Name $output.TestName -Value $output.TestResult -ErrorAction SilentlyContinue 
        }

        $DCDiagDNS = dcdiag /test:dns
        $DCDiagDNS | select-string -pattern '\. (.*) \b(passed|failed)\b test (.*)' | foreach {
            $dnsoutput = [pscustomobject] @{
                TestName = $_.Matches.Groups[3].Value
                TestResult = $_.Matches.Groups[2].Value
            }
            $ResultsArray | Add-Member -MemberType NoteProperty -Name ("DCDiagDNS",$dnsoutput.TestName -join "-") -Value $dnsoutput.TestResult -ErrorAction SilentlyContinue
        }

        foreach ($Result in $ResultsArray){
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
            $Result | Add-Member -MemberType NoteProperty -Name "DCDiagDNSConnectivity" -Value $Result.'DCDiagDNS-Connectivity'
            $Result | Add-Member -MemberType NoteProperty -Name "DCDiagDNSDNS" -Value $Result.'DCDiagDNS-DNS'
        }


        return $ResultsArray | Select-Object Host, DateScanned, DomainNamingMaster, SchemaMaster, InfrastructureMaster, RIDMaster, 
            PDCEmulator, DomainMode, ForestMode, objectVersion, LastReplicationSuccess, LastReplicationAttempt, ScheduledSync, 
            SyncOnStartup, Connectivity, Advertising, FrsEvent, DFSREvent, SysVolCheck, KccEvent, 
            KnowsOfRoleHolders, MachineAccount, NCSecDesc, NetLogons, ObjectsReplicated, Replications, RidManager, Services, 
            SystemLog, VerifyReferences, DCDiagDNS-Connectivity, DCDiagDNS-DNS, ComplexityEnabled, ReversibleEncryptionEnabled, DistinguishedName, objectClass, 
            objectGuid, LockoutDuration, LockoutObservationWindow, MaxPasswordAge, MinPasswordAge, LockoutThreshold, 
            MinPasswordLength, PasswordHistoryCount
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}
