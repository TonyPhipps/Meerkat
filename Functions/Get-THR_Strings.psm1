function Get-THR_Strings {
    <#
    .SYNOPSIS 
        Gets a list of strings from the process image on disk on a given system.

    .DESCRIPTION 
        Gets a list of strings from the process image on disk on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER PathContains
        If specified, limits the strings collection via -like.
        Example: 

    .PARAMETER MinimumLength
        7 by default. Specifies the minimum string length to return. 

    .EXAMPLE 
        Get-THR_Strings $env:computername
        Get-Content C:\hosts.csv | Get-THR_Strings -PathContains "*calc*"
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Strings -MinimumLength

    .NOTES 
        Updated: 2018-02-14

        Contributing Authors:
            Anthony Phipps    
            Jeremy Arnold
            
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
       https://www.zerrouki.com/powershell-cheatsheet-regular-expressions/
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,

        [Parameter()]
        $PathContains,

        [Parameter()]
        $MinimumLength = 7
    )

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Verbose "Started at $datetime"

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class StringMatch
        {
            [String] $Computer
            [dateTime] $DateScanned
            
            [string] $ProcessLocation
            [string] $String
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $processStrings = $null
        $processStrings = Invoke-Command -ArgumentList $MinimumLength, $PathContains -ComputerName $Computer -ScriptBlock {

            $MinimumLength = $args[0]
            $PathContains = $args[1]

            $Processes = Get-Process | Where-Object {$_.Path -ne $null} | Select-Object -Unique path

            if ($PathContains){
                $Processes = $Processes | Where-Object {$_.Path -like $PathContains} | Select-Object -Unique path    
            }

            $processStrings = @()
            
            foreach ($File in $Processes) {
                
                $path = $File.Path

                $UnicodeFileContents = Get-Content -Encoding "Unicode" -Path $path
                $UnicodeRegex = [Regex] "[\u0020-\u007E]{$MinimumLength,}"
                $Results += $UnicodeRegex.Matches($UnicodeFileContents).Value
                $processStrings += [pscustomobject] @{
                    Process = $path 
                    Stringsfound = $Results
                }
                    
                $AsciiFileContents = Get-Content -Encoding "UTF7" -Path $path
                $AsciiRegex = [Regex] "[\x20-\x7E]{$MinimumLength,}"
                $Results = $AsciiRegex.Matches($AsciiFileContents).Value
                $processStrings += [pscustomobject] @{
                    Process = $path 
                    Stringsfound = $Results
                }
            }

            return $processStrings
        }
                    
        if ($processStrings) {

            [regex]$regexEmail = '^([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})$'
            [regex]$regexIP = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])$'
            [regex]$regexURL = '^https?:\/\/'
            
            $outputArray = @()

            foreach ($process in $processStrings) {
                
                foreach ($string in $process.Stringsfound){

                    if (($string -match $regexEmail) -or ($string -match $regexIP) -or ($string -match $regexURL)){
                                        
                        $output = $null
                        $output = [StringMatch]::new()
    
                        $output.Computer = $Computer
                        $output.DateScanned = Get-Date -Format u
    
                        $output.ProcessLocation = $process.process
                        $output.String = $string
                                        
                        $outputArray += $output
                    }
                }
            }
            
            $total++
            return $outputArray
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $Result = $null
            $Result = [StringMatch]::new()

            $Result.Computer = $Computer
            $Result.DateScanned = $DateScanned
            
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