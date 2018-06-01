function Get-THR_ADS {
    <#
    .SYNOPSIS 
        Performs a search for alternate data streams (ADS) on a system.

    .DESCRIPTION 
        Performs a search for alternate data streams (ADS) on a system. Default starting directory is c:\users.
        To test, perform the following steps first:
        $file = "C:\temp\testfile.txt"
        Set-Content -Path $file -Value 'Nobody here but us chickens!'
        Add-Content -Path $file -Value 'Super secret squirrel stuff' -Stream 'secretStream'

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Path  
        Specify a path to search for alternate data streams in. Default is c:\users

    .EXAMPLE 
        Get-THR_ADS -Path "C:\"
        Get-THR_ADS SomeHostName.domain.com -Path "C:\"
        Get-Content C:\hosts.csv | Get-THR_ADS -Path "C:\"
        Get-THR_ADS $env:computername -Path "C:\"
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_ADS -Path "C:\"

    .NOTES 
        Updated: 2018-04-26

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

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME,

        [Parameter()]
        $Path = "C:\Users"
    )

    begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class ADS {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $FileName
            [String] $StreamName
            [String] $StreamLength
            [String] $StreamContent
            [String] $Attributes
            [DateTime] $CreationTimeUtc
            [DateTime] $LastAccessTimeUtc
            [DateTime] $LastWriteTimeUtc

        }
    }

    process{

        $Computer = $Computer.Replace('"', '')
        
        $Streams = $null
        $Streams = Invoke-Command -ArgumentList $Path -ComputerName $Computer -ScriptBlock {
            $Path = $args[0]

            $Streams = Get-ChildItem -Path $Path -Recurse -PipelineVariable FullName | 
            ForEach-Object { Get-Item $_.FullName -Stream * } | # Doesn't work without foreach
            Where-Object {($_.Stream -notlike "*DATA") -AND ($_.Stream -ne "Zone.Identifier")}

            ForEach ($Stream in $Streams) {
                $File = Get-Item $Stream.FileName
                $StreamContent = Get-Content -Path $Stream.FileName -Stream $Stream.Stream
                $Attributes = Get-ItemProperty -Path $Stream.FileName

                $Stream | Add-Member -MemberType NoteProperty -Name CreationTimeUtc -Value $File.CreationTimeUtc
                $Stream | Add-Member -MemberType NoteProperty -Name LastAccessTimeUtc -Value $File.LastAccessTimeUtc
                $Stream | Add-Member -MemberType NoteProperty -Name LastWriteTimeUtc -Value $File.LastWriteTimeUtc
                $Stream | Add-Member -MemberType NoteProperty -Name StreamContent -Value $StreamContent
                $Stream | Add-Member -MemberType NoteProperty -Name Attributes -Value $Attributes.Mode
            }

            return $Streams
        }
        
        if ($Streams) {
            Write-Verbose "Streams were found."

            $OutputArray = ForEach ($Stream in $Streams) {

                $output = $null
                $output = [ADS]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $output.FileName = $Stream.FileName
                $output.StreamName = $Stream.Stream
                $output.StreamLength = $Stream.Length
                $output.Attributes = $Stream.Attributes
                $output.StreamContent = $Stream.StreamContent
                $output.CreationTimeUtc = $Stream.CreationTimeUtc
                $output.LastAccessTimeUtc = $Stream.LastAccessTimeUtc
                $output.LastWriteTimeUtc = $Stream.LastWriteTimeUtc
                
                $output
            }

            $total++
            return $OutputArray
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $Result = $null
            $Result = [ADS]::new()

            $Result.Computer = $Computer
            $Result.DateScanned = Get-Date -Format u
            
            $total++
            return $Result
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Started at {0}" -f $DateScanned)
        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}