function Get-THR_Hotfixes {
    <#
    .SYNOPSIS 
        Gets the hotfixes applied to a given system.

    .DESCRIPTION 
        Gets the hotfixes applied to a given system. Get-Hotfix returns only OS-level hotfixes, this one grabs em all.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Hotfixes 
        Get-THR_Hotfixes SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Hotfixes
        Get-THR_Hotfixes $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Hotfixes

    .NOTES 
        Updated: 2018-02-07

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2018
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
        https://github.com/TonyPhipps/THRecon
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $total = 0

        class Hotfix
        {
            [string] $Computer
            [Datetime] $DateScanned

            [String] $PSComputerName
            [String] $Operation
            [string] $ResultCode
            [String] $HResult
            [String] $Date
            [String] $Title
            [String] $Description
            [String] $UnmappedResultCode
            [String] $ClientApplicationID
            [String] $ServerSelection
            [String] $ServiceID
            [String] $UninstallationNotes
            [String] $SupportUrl
        }
	}

    process{

        $Hotfixes = invoke-command -Computer $Computer -scriptblock {

            $Session = New-Object -ComObject "Microsoft.Update.Session"
            $Searcher = $Session.CreateUpdateSearcher()
            $historyCount = $Searcher.GetTotalHistoryCount()
            $Searcher.QueryHistory(0, $historyCount) | Where-Object Title -ne $null
        }

        if ($Hotfixes){
            
            $OutputArray = @()

            foreach ($item in $Hotfixes) {

                $output = $null
                $output = [Hotfix]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $output.PSComputerName = $item.PSComputerName
                $output.Operation = $item.Operation
                $output.ResultCode = $item.ResultCode
                $output.HResult = $item.HResult
                $output.Date = $item.Date
                $output.Title = $item.Title
                $output.DESCRIPTION = $item.DESCRIPTION
                $output.UnmappedResultCode = $item.UnmappedResultCode
                $output.ClientApplicationID = $item.ClientApplicationID
                $output.ServerSelection = $item.ServerSelection
                $output.ServiceID = $item.ServiceID
                $output.UninstallationNotes = $item.UninstallationNotes
                $output.SupportUrl = $item.SupportUrl

                $OutputArray += $output
            }

            $total++
            return $OutputArray
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            if ($Fails) {
                
                $total++
                Add-Content -Path $Fails -Value ("$Computer")
            }
            else {
                
                $output = $null
                $output = [ArpCache]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u
                
                $total++
                return $output
            }
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}