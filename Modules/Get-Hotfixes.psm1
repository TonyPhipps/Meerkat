function Get-Hotfixes {
    <#
    .SYNOPSIS 
        Returns all applied hotfixes.

    .DESCRIPTION 
        Returns all applied hotfixes. Get-Hotfix returns only OS-level hotfixes, this one grabs em all.

    .EXAMPLE 
        Get-Hotfixes

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Hotfixes} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Hotfixes.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-Hotfixes} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_Hotfixes.csv")
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
        Write-Information -InformationAction Continue -MessageData ("Started Get-Hotfixes at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $Session = New-Object -ComObject "Microsoft.Update.Session"
        $Searcher = $Session.CreateUpdateSearcher()
        $historyCount = $Searcher.GetTotalHistoryCount()
        $UpdatesArray = $Searcher.QueryHistory(0, $historyCount) | Where-Object Title -ne $null
        
        $HotfixesArray = Get-Hotfix
        
        foreach ($Hotfix in $HotfixesArray) {
            $Hotfix | Add-Member -MemberType NoteProperty -Name "Date" -Value $Hotfix.InstalledOn
            $Hotfix | Add-Member -MemberType NoteProperty -Name "Title" -Value $Hotfix.HotFixID
            $Hotfix | Add-Member -MemberType NoteProperty -Name "SupportUrl" -Value $Hotfix.Caption
        }

        foreach ($Update in $UpdatesArray){
            $pattern = "(KB\d+)"

            if ($Update.Title -match $pattern) {
                $HotFixID = $matches[1]
                $Update | Add-Member -MemberType NoteProperty -Name "HotFixID" -Value $HotFixID
            }
        }

        $MatchingHotFixIDs = (Compare-Object $UpdatesArray $HotfixesArray -Property "HotFixID" -IncludeEqual -ExcludeDifferent -PassThru).HotFixID
        
        $FilteredHotFixesArray = $HotfixesArray | Where-Object { $_.HotFixID -notin $MatchingHotFixIDs }

        $ResultsArray = @() + $UpdatesArray + $FilteredHotFixesArray

        foreach ($Result in $ResultsArray) {
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
        }
        
        return $ResultsArray | Select-Object Host, DateScanned, Operation, ResultCode, HResult, Date, HotFixID, Title, Description, UnmappedResultCode, ClientApplicationID, ServerSelection, ServiceID, UninstallationNotes, SupportUrl, InstalledBy

    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ"))
    }
}
