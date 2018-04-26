function Get-THR_Handles {
    <#
    .SYNOPSIS 
        Gets a list of Handles loaded by all process on a given system.

    .DESCRIPTION 
        Gets a list of Handles loaded by all process on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER HandlePath
        The location of Sysinternals Handle.exe/Handle64.exe. This parameter is manadatory
        and is how the function gets the list of handles.

    .EXAMPLE 
        Get-THR_Handles -HandlePath c:\tools\sysinternals
        Get-THR_Handles SomeHostName.domain.com -HandlePath "\\server\share\sysinternals"
        Get-Content C:\hosts.csv | Get-THR_Handles -HandlePath "\\server\share\sysinternals"
        Get-THR_Handles $env:computername -HandlePath "\\server\share\sysinternals"
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Handles -HandlePath "\\server\share\sysinternals"

    .NOTES 
        Updated: 2018-04-25

        Contributing Authors:
            Jeremy Arnold
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
       https://docs.microsoft.com/en-us/sysinternals/downloads/
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,

        [Parameter(HelpMessage="The folder path of Sysinternals Handle.exe, not including trailing backslash (\).")]
        [string]$HandlePath = "C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon\Utilities"
    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class Handle
        {
            [String] $Computer
            [dateTime] $DateScanned

            [string] $ProcessID
            [string] $Process
            [string] $Owner
            [string] $Location
            [string] $HandleType
            [string] $Attributes
            [string] $String
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $handles = $null
        $handles = Invoke-Command  -ArgumentList $HandlePath -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
            $HandlePath = $args[0]

            $Is64BitOperatingSystem = [environment]::Is64BitOperatingSystem
            if ($Is64BitOperatingSystem){
                $tool = 'handle64.exe'
            } 
            else {
                $tool = 'handle.exe'
            }

            $handles = Invoke-Expression "$HandlePath\$tool -a -nobanner -accepteula"

            return $handles
        
        }
            
        if ($handles) {
            [regex]$regexProcess = '(?<process>\S+)\spid:\s(?<pid>\d+)\s(?<string>.*)'
            [regex]$regexHandle = '(?<location>[A-F0-9]+):\s(?<type>\w+)\s{2}(?<attributes>\(.*\))?\s+(?<string>.*)'
            [regex]$nullHandle = '([A-F0-9]+):\s(\w+)\s+$'

            $outputArray = @()
            
            $handles = $handles | Where-Object {($_.length -gt 0) -and ($_ -notmatch $nullHandle)}
            
            Foreach ($handle in $handles) {
            
                if ($handle -match $regexProcess){
            
                    $process = $Matches.process
                    $processPID = $Matches.pid
                    $owner = $Matches.string
                }
            
                if ($handle -match $regexHandle){
            
                    $output = $null
                    $output = [Handle]::new()
    
                    $output.Computer = $Computer
                    $output.DateScanned = Get-Date -Format u
    
                    $output.ProcessID = $processPID
                    $output.Process = $process
                    $output.Owner =$owner
                    $output.Location = $Matches.location
                    $output.HandleType = $Matches.type
                    $output.Attributes = $Matches.attributes
                    $output.String = $Matches.string
                                        
                    $outputArray += $output
                }

            }
            
            $total++
            return $outputArray
        }
        else {
                
            $output = $null
            $output = [Handle]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format u
            
            $total++
            return $output
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}