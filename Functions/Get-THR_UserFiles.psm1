function Get-THR_UserFiles {
    <#
    .SYNOPSIS 
        Gets a list of interesting files in folders users can edit.

    .DESCRIPTION 
        Gets a list of interesting files in folders users can edit.
        Includes *.exe, *.ps1, *.com, *.cmd, *.vbs, *.vbe, *.js, *.jse, *.wsf, *.wsh, *.dll, *.bat,*.psm1,
                *.bin, *.cpl, *.gadget, *.inf, *.ins, *.inx, *.isu, *.job, *.msc, *.msi, *.msp,
                *.mst, *.paf, *.pif, *.reg, *.rgs, *.scr, *.sct, *.shb, *.shs, *.u3p, *.ws

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_UserFiles 
        Get-THR_UserFiles SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_UserFiles
        Get-THR_UserFiles $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_UserFiles

    .NOTES 
        Updated: 2018-04-11

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
       https://github.com/TonyPhipps/THRecon/wiki/UserFiles
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

        class UserFile {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $FullName
            [String] $IsReadOnly
            [String] $Attributes
            [String] $Mode
            [String] $Length
            [String] $CreationTimeUtc
            [String] $LastAccessTimeUtc
            [String] $LastWriteTimeUtc
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $FileArray = $null
        $FileArray = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
            $UserDirectoryArray = Get-ChildItem "c:\" -Directory -Force -Depth 0
            $UserDirectoryArray = $UserDirectoryArray | Where-Object { !($_.Name -in "Documents and Settings", "Config.Msi", "`$Windows.~WS", "PerfLogs", "Program Files", "Program Files (x86)", "ProgramData", "Recovery", "System Volume Information", "Windows")}
            $UserDirectoryArray = $UserDirectoryArray.FullName

            $FileArray = $null
            foreach ($UserDirectory in $UserDirectoryArray){
                $FileArray += Get-Childitem $UserDirectory -Recurse -Include *.exe, *.ps1, *.com,  
                 *.cmd, *.vbs, *.vbe, *.js, *.jse, *.wsf, *.wsh, *.dll, *.bat,*.psm1, #Executables
                *.bin, *.cpl, *.gadget, *.ins, *.inp, *.hta, *.msc, *.msi, *.msp, *.mst, #Executables
                *.paf, *.pif, *.reg, *.rgs, *.scr, *.sct, *.shb, *.shs, *.u3p, *.ws #Executables
            }

            $FileArray = $FileArray | Select-Object FullName, IsReadOnly, Attributes, Mode, LinkType, Length, CreationTimeUtc, LastAccessTimeUtc, LastWriteTimeUtc

            return $FileArray
        }
            
        if ($FileArray) {
            
            $outputArray = @()

            Foreach ($File in $FileArray) {

                $output = $null
                $output = [UserFile]::new()
                                    
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $output.FullName = $File.FullName
                $output.IsReadOnly = $File.IsReadOnly
                $output.Attributes = $File.Attributes
                $output.Mode = $File.Mode
                $output.Length = $File.Length
                $output.CreationTimeUtc = $File.CreationTimeUtc
                $output.LastAccessTimeUtc = $File.LastAccessTimeUtc
                $output.LastWriteTimeUtc = $File.LastWriteTimeUtc

                
                $outputArray += $output
            }

            return $outputArray

        }
        else {
                
            $output = $null
            $output = [UserFile]::new()

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