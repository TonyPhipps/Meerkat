function Invoke-THR_PSExec {
    <#
    .SYNOPSIS 
        Deploys Invoke-THR using psexec.

    .DESCRIPTION 
        Deploys Invoke-THR using psexec. Some environments block ports 5985, 5986, or otherwise prohibit WinRM. 
        This uses psexec to bypass those restrictions.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER ModulePath
        Local folder of module to deploy. Default is "$ENV:USERPROFILE\Documents\WindowsPowerShell\Modules\THRecon\"
    
    .PARAMETER Output
        Local folder save results to. Default is "C:\Temp\Results\"

    .PARAMETER ModuleName
        Name of module to deploy. Default is "THRecon.psm1"

    .PARAMETER PSExec
        Local folder containing the psexec.exe file. Default is "C:\Program Files\Sysinternals"
        
    .PARAMETER RemoteModulePath
        Remote path to store deployed module. Default is "C:\Windows\Toolkit\"

    .PARAMETER RemoteOutputPath
        Remote path to store scan results. Default is "C:\Windows\Toolkit\Results\"

    .PARAMETER Command
        Command to execute on remote system. Default is "Invoke-THR". 
        Special parameters to Invoke-THR like "Invoke-THR -Module MAC" can also be used.        

    .EXAMPLE
        Invoke-THR-PSExec -Computer WorkComputer
        Invoke-thr_psexec -Computer WorkComputer -Command 'Get-THR_MAC -Hash | export-csv c:\windows\toolkit\results\computer.csv -notypeinformation'

    .NOTES 
        Updated: 2018-06-01

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
       https://docs.microsoft.com/en-us/sysinternals/downloads/
    #>

    [CmdletBinding()]
    param(
    #Remote Parameters
    [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$Computer = "127.0.0.1",
    [string]$RemoteModulePath = "c:\Windows\Toolkit\",
    [string]$RemoteOutputPath = "c:\Windows\Toolkit\Results\",
    [string]$Command = "Invoke-THR",
    
    #Local Parameters
    [string]$ModulePath = "$ENV:USERPROFILE\Documents\WindowsPowerShell\Modules\THRecon\",
    [string]$Output = "C:\Temp\Results\",
    [string]$ModuleName = "THRecon.psm1",
    [string]$PSExec = "C:\Program Files\Sysinternals"
    )

    begin{
        function Copy-WithProgress { # https://blogs.technet.microsoft.com/heyscriptingguy/2015/12/20/build-a-better-copy-item-cmdlet-2/

            param(
                $Source,
                $Destination
            )

            $Source = $Source.tolower()
            $Filelist = Get-Childitem $Source -Recurse
            $Total = $Filelist.count
            $Position = 0

            New-Item -ItemType Directory -Path $Destination -Force

            foreach ($File in $Filelist) {
                
                $Filename = $File.Fullname.tolower().replace($Source,"")
                $DestinationFile = ($Destination + $Filename)
                
                Copy-Item $File.FullName -Destination $DestinationFile -Recurse -Force
                
                $Position++
                Write-Progress -Activity "Copying data from $Source to $Destination" -Status "Copying File $Filename" -PercentComplete (($Position/$total)*100)
            }

            Write-Progress -Activity "Copying data from $Source to $Destination" -Completed
        }
    }

    process{

        # Prepare NTFS/Share path versions
         $ModuleShare = $RemoteModulePath.Replace(':', '$')
         $ModuleNTFS = $RemoteModulePath.Replace('$', ':')
         $OutputShare = $RemoteOutputPath.Replace(':', '$')

        if($Command -like "Invoke-THR*"){
            
            if($Command -like "*output*"){
                Write-Error -Message "Specify remote output via -RemoteOutputPath parameter."
                exit
            }

            $Command = $Command + " -Output $RemoteOutputPath"
            
        } else {
            
            mkdir \\$Computer\$OutputShare -ErrorAction SilentlyContinue
        }

        # Stage files
        #Copy-Item $ModulePath -Recurse -Force -Destination \\$Computer\$ModuleShare -- has issues, hence the Copy-WithProgress function
        Copy-WithProgress -Source "$ModulePath" -Destination "\\$Computer\$ModuleShare"

        # Import modules and execute command as system. -s was added due to access denied errors on only some modules.
        & $PSExec\PsExec.exe -s \\$Computer -accepteula powershell -ExecutionPolicy ByPass -nologo -command "& {import-module $ModuleNTFS\$ModuleName; & $Command}"
    }

    end{
        # Retrieve Results
        Copy-WithProgress -Source \\$Computer\$OutputShare -Destination $Output

        # Cleanup
        Remove-Item \\$Computer\$OutputShare -Recurse -Force
        Remove-Item \\$Computer\$ModuleShare -Recurse -Force
    }
}