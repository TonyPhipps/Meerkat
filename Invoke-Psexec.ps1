function Invoke-PSExec {
    <#
    .SYNOPSIS 
        Uses psexec to invoke a command on one or more systems in the pipeline.

    .DESCRIPTION 
        

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.
  
    .PARAMETER PSExec
        Local folder containing the psexec.exe file. Default is "C:\Program Files\Sysinternals"
        
    .PARAMETER Command
        Command to execute on remote system. Default is "Get-ComputerInfo".     

    .EXAMPLE

    .NOTES 
        Updated: 2019-10-10

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
       https://github.com/TonyPhipps/
       https://docs.microsoft.com/en-us/sysinternals/downloads/
    #>

    [CmdletBinding()]
    param(
        #Remote Parameters
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]$Computer = "127.0.0.1",
        $Command = {
            # Shared folder with temporary write access. Need to create this first
            $dirname = "c:\report"
            $fname = "$dirName\lockhunt-$(get-date -f yyyy-MM-dd).csv"
            Get-ChildItem -Path C:\ -Include *.locked -File -Recurse -ErrorAction SilentlyContinue | Select-Object FullName | Export-Csv $fname -NoTypeInformation
        },
        
        #Local Parameters
        [string]$PSExec = "C:\Program Files\Sysinternals"
    )

    begin{
    }

    process{

        & $PSExec\PsExec.exe \\$Computer -accepteula powershell -ExecutionPolicy ByPass -windowstyle hidden -nologo -noprofile -command "& $Command"
    }

    end{
    }
}