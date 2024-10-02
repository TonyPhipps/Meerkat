function Get-AuditPolicy {
    <#
    .SYNOPSIS 
        Gets Audit Policy settings from auditpol.exe.

    .DESCRIPTION 
        Collects Audit Policy settings from auditpol.exe, including inclusions and exclusions. Also collects IdleLockoutTime from the Registry.

    .EXAMPLE 
        Get-AuditPolicy
    
    .EXAMPLE
        Get-AuditPolicy | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\AuditPolicy.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-AuditPolicy} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\AuditPolicy.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-AuditPolicy} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_AuditPolicy.csv")
        }

    .NOTES 
        Updated: 2024-06-03

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
       https://github.com/TonyPhipps/Meerkat
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-AuditPolicy at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $IdleLockoutTime = (Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "InactivityTimeoutSecs" -ErrorAction SilentlyContinue)/60
            
        $ResultsArray = auditpol.exe /get /category:* /r | ConvertFrom-Csv |
        Select-Object -Property "Subcategory", "Subcategory GUID", "Inclusion Setting", "Exclusion Setting"

        foreach ($Result in $ResultsArray) {

            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
        }

        return $ResultsArray | 
            Select-Object Host, DateScanned, "Subcategory", "Subcategory GUID", "Inclusion Setting", "Exclusion Setting" | 
                Group-Object Host, DateScanned | Foreach-Object {
                    $hash = [Ordered]@{
                        Host = ($_.Name -Split', ')[0]
                        DateScanned = ($_.Name -Split', ')[1]
                        IdleLockoutTime = $IdleLockoutTime
                    }
                    
                    $_.Group | Foreach-Object {
                        if ($_."Exclusion Setting") {
                            $hash.Add($_.Subcategory, ("{0}, Exclusions: {0}" -f $_."Inclusion Setting", $_."Exclusion Setting"))
                        }
                        else {
                            $hash.Add($_.Subcategory, "{0}" -f $_."Inclusion Setting")
                        }
                    }
                    
                    [pscustomobject]$hash
                }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ"))
    }
}
