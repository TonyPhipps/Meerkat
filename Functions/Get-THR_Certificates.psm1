function Get-THR_Certificates {
    <#
    .SYNOPSIS 
        Gets a list of programs that auto start for the given computer(s).

    .DESCRIPTION 
        Gets a list of programs that auto start for the given computer(s).

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Certificates 
        Get-THR_Certificates SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Certificates
        Get-THR_Certificates -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Certificates

    .NOTES
        Updated: 2018-06-14

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

        class Certificate
        {
            [string] $Computer
            [Datetime] $DateScanned
            
            [String] $Path
            [String] $Thumbprint
            [String] $SendAsTrustedIssuer
            [String] $DnsNameList
            [String] $FriendlyName
            [String] $Issuer
            [String] $Subject
            [String] $NotAfter
            [String] $NotBefore
            [String] $Algorithm
        }

        $Command = {
            Get-ChildItem Cert:\LocalMachine\ -Recurse | 
                Select-Object @{Name="Path"; Expression = {$_.PSParentPath.Split("::")[2]}}, Thumbprint, SendAsTrustedIssuer, DnsNameList, FriendlyName, Issuer, Subject, NotAfter, NotBefore, PSIsContainer, @{Name="Algorithm"; Expression = {$_.SignatureAlgorithm.FriendlyName}} | 
                Where-Object {$_.PSIsContainer -ne $True}
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
            
            $outputArray = foreach ($Certificate in $ResultsArray) {
             
                $output = $null
                $output = [Certificate]::new()
                
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u
                
                $output.Path = $Certificate.Path
                $output.DnsNameList = $Certificate.DnsNameList
                $output.SendAsTrustedIssuer = $Certificate.SendAsTrustedIssuer
                $output.FriendlyName = $Certificate.FriendlyName
                $output.Issuer = $Certificate.Issuer
                $output.Subject = $Certificate.Subject
                $output.NotAfter = $Certificate.NotAfter
                $output.NotBefore = $Certificate.NotBefore
                $output.Thumbprint = $Certificate.Thumbprint
                $output.Algorithm = $Certificate.Algorithm

                $output
            }

            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [Certificate]::new()

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