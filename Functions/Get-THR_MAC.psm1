function Get-THR_MAC {
    <#
    .SYNOPSIS 
        Records Modified, Accessed, and Created (MAC) times on files.

    .DESCRIPTION 
        Records Modified, Accessed, and Created (MAC) times on files. Use the -Path command to 
        provide a directory to recursively record MAC times.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Path  
        Specify a path to begin recursive recording of MAC times (Defaults to c:\users)

    .EXAMPLE 
        Get-THR_MAC
        Get-THR_MAC SomeHostName.domain.com -Path "C:\"
        Get-Content C:\hosts.csv | Get-THR_MAC
        Get-THR_MAC $env:computername -Path "C:\Windows"
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_MAC

    .NOTES 
        Updated: 2018-05-23

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

        class FileMAC {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $FileName
            [String] $Mode
            [String] $Bytes
            [String] $LastWriteTimeUTC
            [DateTime] $LastAccessTimeUTC
            [DateTime] $CreationTimeUTC
        }
    }

    process{

        $Computer = $Computer.Replace('"', '')
        
        $MACArray = $null
        $MACArray = Invoke-Command -ComputerName $Computer -ScriptBlock {
           
            $MACArray = Get-ChildItem -Path $Using:Path -File -Recurse | Select-Object FullName, Mode, Length, LastWriteTimeUtc, LastAccessTimeUtc, CreationTimeUtc

            return $MACArray
        }
        
        if ($MACArray) {
            Write-Verbose "MAC times were received."

            $OutputArray = ForEach ($FileMAC in $MACArray) {

                $output = $null
                $output = [FileMAC]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $output.FileName = $FileMAC.FullName
                $output.Mode = $FileMAC.Mode
                $output.Bytes = $FileMAC.Length
                $output.LastWriteTimeUTC = $FileMAC.LastWriteTimeUtc
                $output.LastAccessTimeUTC = $FileMAC.LastAccessTimeUtc
                $output.CreationTimeUTC = $FileMAC.creationTimeUtc
                
                $output
            }

            $total++
            return $OutputArray
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $Result = $null
            $Result = [FileMAC]::new()

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