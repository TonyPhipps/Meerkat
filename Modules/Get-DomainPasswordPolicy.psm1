Function Get-DomainPasswordPolicy {
    <#
    .SYNOPSIS
        Gets the default password policy for a domain.

    .DESCRIPTION
        Gets the default password policy for a domain.

    .EXAMPLE 
        Get-DomainPasswordPolicy

    .EXAMPLE
        Get-DomainPasswordPolicy | 
        Export-Csv -NoTypeInformation ("c:\temp\DomainPasswordPolicy.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Computer} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\DomainPasswordPolicy.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-DomainPasswordPolicy} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_DomainPasswordPolicy.csv")
        }

    .NOTES
        Updated: 2022-12-1

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
       https://github.com/TonyPhipps/Meerkat/wiki/DomainPasswordPolicy
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started Get-DomainPasswordPolicy at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

    $ResultsArray = New-Object -TypeName PSObject

    $ADDefaultDomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy
        foreach ($Property in $ADDefaultDomainPasswordPolicy.PSObject.Properties) {
            $ResultsArray | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.value -ErrorAction SilentlyContinue
        }  

    foreach ($Result in $ResultsArray){
        $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
        $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned            
    }

    return $ResultsArray | Select-Object Host, DateScanned, ComplexityEnabled, ReversibleEncryptionEnabled, DistinguishedName, objectClass, 
        objectGuid, LockoutDuration, LockoutObservationWindow, MaxPasswordAge, MinPasswordAge, LockoutThreshold, 
        MinPasswordLength, PasswordHistoryCount    
    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}