Function Get-THR_EnvVars {
    <#
    .SYNOPSIS 
        Retreives the values of all environment variables from one or more systems.
    
    .DESCRIPTION
        Retreives the values of all environment variables from one or more systems.
    
    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.
    
    .EXAMPLE 
        get-content .\hosts.txt | Get-THR_EnvVars $env:computername | export-csv envVars.csv -NoTypeInformation
    
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
       https://github.com/TonyPhipps/Threat-Hunting-Recon-Kit
    #>


    [cmdletbinding()]


    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        
        [Parameter()]
        $Fails
    );

    begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;

        class EnvVariable {
            [String] $Computer
            [DateTime] $DateScanned
            
            [String] $Name         
            [String] $UserName
            [String] $VariableValue
        };
    };


    process{
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        
        $AllVariables = $null;
        $AllVariables = Get-CimInstance -Class Win32_Environment -ComputerName $Computer -ErrorAction SilentlyContinue;
        
        if ($AllVariables) {

            $OutputArray = $null;
            $OutputArray = @();

            ForEach ($Variable in $AllVariables) {
                $VariableValues = $Variable.VariableValue.Split(";") | Where-Object {$_ -ne ""}
            
                Foreach ($VariableValue in $VariableValues) {
                    $VariableValueSplit = $Variable;
                    $VariableValueSplit.VariableValue = $VariableValue;
                
                    $output = $null;
                    $output = [EnvVariable]::new();
   
                    $output.Computer = $Computer;
                    $output.DateScanned = Get-Date -Format u;

                    $output.Name = $VariableValueSplit.Name;
                    $output.UserName = $VariableValueSplit.UserName;
                    $output.VariableValue = $VariableValueSplit.VariableValue;         

                    $OutputArray += $output;

                };
            };

            $elapsed = $stopwatch.Elapsed;
            $total = $total+1;

            return $OutputArray;
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [EnvVariable]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $total++;
                return $output;
            };
        };
    };

    end{

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed);
    };
};