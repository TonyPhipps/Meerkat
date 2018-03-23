Function Test-SharePermissions {
	<#
	.SYNOPSIS 
		Tests the current user's ability to read, write, and delete a file in a given share.
	
	.DESCRIPTION 
		Tests the current user's ability to read, write, and delete a file in a given share. Supports piping in share paths.
	
	.PARAMETER SharePath  
		A complete share path (e.g. \\Hostname\ShareName\).
	
	.EXAMPLE 
		Test-SharePermissions "\\servername\share\"
		Import-Csv c:\temp\shares.csv | ForEach-Object {"\\{0}\{1}\" -f $_.ComputerName, $_.Name} | Test-SharePermissions
	
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

	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
		$SharePath
	)

	begin{
		$DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class Share {
			[String] $SharePath
			[DateTime] $DateScanned
			
			[String] $UserTested
			[String] $FileTested
            [String] $Read
			[String] $Write
			[String] $Delete

		}
		
		$RandomString = -join ((65..90) + (97..122) | Get-Random -Count 10 | Foreach-Object {[char]$_})
	}

	process{

		$output = $null
		$output = [Share]::new()

		$output.SharePath = $SharePath
		$output.UserTested = whoami
		$output.FileTested = "$RandomString.txt"
		$output.DateScanned = Get-Date -Format u
		$output.Read = $False
		$output.Write = $False
		$output.Delete = $False
		
		Write-Verbose "Testing Read Permission"

		if (Get-ChildItem $SharePath -Name -ErrorAction SilentlyContinue) {

			$output.Read = $True
		}
		
		Write-Verbose "Testing Write Permission"
		if (($output.Read) -eq $True) {
			
			New-Item -Path $SharePath -Name "$RandomString.txt" -ItemType "file" -Force -ErrorAction SilentlyContinue | Out-Null
			
			if (Test-Path $SharePath\$RandomString.txt -PathType Leaf -ErrorAction SilentlyContinue) {
                
                $output.Write = $True
			}
		}

		Write-Verbose "Testing Delete Permission"
		if (($output.Write) -eq $True) {

			Remove-Item -path $SharePath\$RandomString.txt -ErrorAction SilentlyContinue | Out-Null

			if (-NOT (Test-Path $SharePath\$RandomString.txt -ErrorAction SilentlyContinue)) {
                
                $output.Delete = $True
			}
		}

		$elapsed = $stopwatch.Elapsed
        $total = $total + 1
        
        Write-Verbose "System $total `t $ThisComputer `t Total Time Elapsed: $elapsed"

		return $output
	}
	
	end{
        
        $elapsed = $stopwatch.Elapsed

		Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed"
	}
}
