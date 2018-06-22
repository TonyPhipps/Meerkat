function Get-THR_DLLs {
    <#
    .SYNOPSIS 
        Gets a list of DLLs loaded by all process on a given system.

    .DESCRIPTION 
        Gets a list of DLLs loaded by all process on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.        

    .EXAMPLE 
        Get-THR_DLLs 
        Get-THR_DLLs SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_DLLs
        Get-THR_DLLs $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_DLLs

    .NOTES 
        Updated: 2018-06-20

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
       https://github.com/TonyPhipps/THRecon/wiki/DLLs
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class DLL
        {
            [String] $Computer
            [dateTime] $DateScanned

            [string] $ProcessID
            [string] $Process
            [String] $DLLName
            [String] $DLLCompany
            [String] $DLLProduct
        }

        $Command = { 
            
            $Processes = Get-Process | Select-Object Id, ProcessName, Company, Product, Modules 
            return $Processes
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        Write-Verbose ("{0}: Querying remote system" -f $Computer)

        if ($Computer = $env:COMPUTERNAME){
            
            $ResultsArray = & $Command 
        } 
        else {

            $ResultsArray = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock $Command
        }
            
        if ($ResultsArray) {
            
            $outputArray = Foreach ($Process in $ResultsArray) {
                
                Foreach ($Module in $Process.modules){
                    
                    $output = $null
                    $output = [DLL]::new()
    
                    $output.Computer = $Computer
                    $output.DateScanned = Get-Date -Format u
    
                    $output.ProcessID = $Process.Id
                    $output.Process = $Process.ProcessName
                    $output.DLLCompany = $Module.Company
                    $output.DLLProduct = $Module.Product
                    $output.DLLName = $Module.ModuleName
                    
                    $output
                }
            }

            $total++
            return $outputArray
        }
        else {
                
            $output = $null
            $output = [DLL]::new()

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