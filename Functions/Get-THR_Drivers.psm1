function Get-THR_Drivers {
    <#
    .SYNOPSIS 
        Gets a list of drivers for the given computer(s).

    .DESCRIPTION 
        Gets a list of drivers for the given computer(s).

    .EXAMPLE 
        Get-THR_Drivers 
        Get-THR_Drivers SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Drivers
        Get-THR_Drivers -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Drivers

    .NOTES
        Updated: 2019-03-26

        Contributing Authors:
            Jeremy Arnold
            Anthony Phipps
            
        LEGAL: Copyright (C) 2019
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
    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $ResultsArray = Get-WindowsDriver -Online -ErrorAction SilentlyContinue

        foreach ($Result in $ResultsArray) {
            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
        }

        return $ResultsArray | Select-Object Host, DateScanned, ProviderName, Driver, Version, Date, ClassDescription, DriverSignature, OriginalFileName
            
    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}