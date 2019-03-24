function Get-THR_ADS {
    <#
    .SYNOPSIS 
        Performs a search for alternate data streams (ADS) in a given folder.

    .DESCRIPTION 
        Performs a search for alternate data streams (ADS) in a given folder. Default starting directory is c:\users.
        To test, perform the following steps first:
        $file = "C:\temp\testfile.txt"
        Set-Content -Path $file -Value 'Nobody here but us chickens!'
        Add-Content -Path $file -Value 'Super secret squirrel stuff' -Stream 'secretStream'

    .PARAMETER Path  
        Specify a path to search for alternate data streams in. Default is c:\users

    .EXAMPLE 
        Get-THR_ADS -Path "C:\Temp"
        
    .EXAMPLE
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-THR_ADS} -ArgumentList "C:\Temp" | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation "c:\temp\$Target_ADS.csv"
        }

    .NOTES 
        Updated: 2018-12-31

        Contributing Authors:
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

    [CmdletBinding()]
    param(
        $Path = "C:\Users"
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{

        $Streams = Get-ChildItem -Path $Path -Recurse -PipelineVariable FullName | 
        ForEach-Object { Get-Item $_.FullName -Stream * } | # Doesn't work without foreach
        Where-Object {($_.Stream -notlike "*DATA") -AND ($_.Stream -ne "Zone.Identifier")}

        ForEach ($Stream in $Streams) {

            $File = Get-Item $Stream.FileName
            $StreamContent = Get-Content -Path $Stream.FileName -Stream $Stream.Stream
            $Attributes = Get-ItemProperty -Path $Stream.FileName

            $Stream | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Stream | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
            $Stream | Add-Member -MemberType NoteProperty -Name "CreationTimeUtc" -Value $File.CreationTimeUtc
            $Stream | Add-Member -MemberType NoteProperty -Name "LastAccessTimeUtc" -Value $File.LastAccessTimeUtc
            $Stream | Add-Member -MemberType NoteProperty -Name "LastWriteTimeUtc" -Value $File.LastWriteTimeUtc
            $Stream | Add-Member -MemberType NoteProperty -Name "StreamContent" -Value $StreamContent
            $Stream | Add-Member -MemberType NoteProperty -Name "Attributes" -Value $Attributes.Mode
        }

        return $Streams | Select-Object Host, DateScanned, FileName, Stream, Length, Attributes, StreamContent, CreationTimeUtc, LastAccessTimeUtc, LastWriteTimeUtc
    }

    end{
        
        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}

