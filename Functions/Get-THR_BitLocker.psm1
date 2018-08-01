function Get-THR_BitLocker {
    <#
    .SYNOPSIS 
        Gets BitLocker details on a given system.

    .DESCRIPTION 
        Gets BitLocker details on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.  

    .EXAMPLE 
        Get-THR_BitLocker
        Get-THR_BitLocker SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_BitLocker
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_BitLocker

    .NOTES 
        Updated: 2018-08-01

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
    #>

    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $DateScanned = Get-Date -Format u
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class BitLocker {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $ComputerName
            [String] $MountPoint
            [String] $EncryptionMethod
            [String] $AutoUnlockEnabled
            [DateTime] $MetadataVersion
            [String] $VolumeStatus
            [String] $ProtectionStatus
            [String] $LockStatus
            [String] $EncryptionPercentage
            [String] $WipePercentage
            [String] $VolumeType
            [String] $CapacityGB
            [String] $KeyProtector
        }

        $Command = { Get-BitLockerVolume }
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

            $OutputArray = ForEach ($Volume in $ResultsArray) {
                
                $output = $null
                $output = [BitLocker]::new()
        
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u
                
                $output.ComputerName = $Volume.ComputerName
                $output.MountPoint = $Volume.MountPoint
                $output.EncryptionMethod = $Volume.EncryptionMethod
                $output.AutoUnlockEnabled = $Volume.AutoUnlockEnabled
                $output.MetadataVersion = $Volume.MetadataVersion
                $output.VolumeStatus = $Volume.VolumeStatus
                $output.ProtectionStatus = $Volume.ProtectionStatus
                $output.LockStatus = $Volume.LockStatus
                $output.EncryptionPercentage = $Volume.EncryptionPercentage
                $output.WipePercentage = $Volume.WipePercentage
                $output.VolumeType = $Volume.VolumeType
                $output.CapacityGB = $Volume.CapacityGB
                $output.KeyProtector = $Volume.KeyProtector

                $output
            }
        
            $total++
            return $OutputArray
        }
        else {
                
            $output = $null
            $output = [BitLocker]::new()

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