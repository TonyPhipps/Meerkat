function Get-THR_RecycleBin {
    <#
    .SYNOPSIS 
        ...

    .DESCRIPTION 
        ....

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_RecycleBin 
        Get-THR_RecycleBin SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_RecycleBin
        Get-THR_RecycleBin -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_RecycleBin

    .NOTES 
        Updated: 2018-08-05

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

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $total = 0

        class DeletedItem {
            [string] $Computer
            [string] $DateScanned  

            [String] $LinkType
            [String] $Name
            [String] $Length
            [String] $Directory
            [String] $IsReadOnly
            [String] $Exists
            [String] $FullName
            [String] $CreationTimeUtc
            [String] $LastAccessTimeUtc
            [String] $LastWriteTimeUtc
            [String] $IsContainer
            [String] $Mode
        }

        $Command = {
            Get-ChildItem ("{0}\`$Recycle.Bin" -f $env:SystemDrive) -Force -Recurse
         }
    }

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present
        
        Write-Verbose ("{0}: Querying remote system" -f $Computer)

        if ($Computer -eq $env:COMPUTERNAME){
            
            $ResultsArray = & $Command 
        } 
        else {

            $ResultsArray = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock $Command
        }
       
        if ($ResultsArray) { 
            
            $OutputArray = foreach ($RecycledItem in $ResultsArray) {
             
                $output = $null
                $output = [DeletedItem]::new()
                
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format o

                $output.LINKType = $RecycledItem.LINKType
                $output.Name = $RecycledItem.Name
                $output.Length = $RecycledItem.Length
                $output.Directory = $RecycledItem.Directory
                $output.IsReadOnly = $RecycledItem.IsReadOnly
                $output.Exists = $RecycledItem.Exists
                $output.FullName = $RecycledItem.FullName
                $output.CreationTimeUtc = $RecycledItem.CreationTimeUtc
                $output.LastAccessTimeUtc = $RecycledItem.LastAccessTimeUtc
                $output.LastWriteTimeUtc = $RecycledItem.LastWriteTimeUtc
                $output.IsContainer = $RecycledItem.PSIsContainer
                $output.Mode = $RecycledItem.Mode

                $output
            }

            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [DeletedItem]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format o
            
            $total++
            return $output
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}