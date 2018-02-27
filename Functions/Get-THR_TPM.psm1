function Get-THR_TPM {
    <#
    .SYNOPSIS 
        Gets the TPM info on a given system.

    .DESCRIPTION 
        Gets the TPM info on a given system. Converts ManufacturerId if the ID is in the list of built-in names.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address. 

    .EXAMPLE 
        Get-THR_TPM 
        Get-THR_TPM SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_TPM
        Get-THR_TPM $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_TPM

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
        https://trustedcomputinggroup.org/vendor-id-registry/
        https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/ADV170012
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        $Manufacturers = @{
            0x414D4400 = "AMD"
            0x41544D4C = "Atmel"
            0x4252434D = "Broadcom"
            0x474F4F47 = "Google"
            0x48504500 = "HPE"
            0x49424d00 = "IBM"
            0x49465800 = "Infineon"
            0x494E5443 = "Intel"
            0x4C454E00 = "Lenovo"
            0x4D534654 = "Microsoft"
            0x4E534D20 = "National Semiconductor"
            0x4E544300 = "Nuvoton Technology"
            0x4E545A00 = "Nationz"
            0x51434F4D = "Qualcomm"
            0x524F4343 = "Fuzhou Rockchip"
            0x534D5343  = "SMSC"
            0x534D534E = "Samsung"
            0x534E5300 = "Sinosun"
            0x53544D20 = "ST Microelectronics"
            0x54584E00 = "Texas Instruments"
            0x57454300 = "Winbond"
        }

        class TPM
        {
            [String] $Computer
            [dateTime] $DateScanned
            
            [bool] $TpmPresent
            [bool] $TpmReady
            [uint32] $ManufacturerId
            [String] $ManufacturerIdHex
            [String] $ManufacturerName
            [String] $ManufacturerVersion
            [String] $ManagedAuthLevel
            [String] $OwnerAuth
            [bool] $OwnerClearDisabled
            [String] $AutoProvisioning
            [bool] $LockedOut
            [String] $LockoutCount
            [String] $LockoutMax
            [String] $SelfTest
            [String] $FirmwareVersionAtLastProvision
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $TPMInfo = $null
        $TPMInfo = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            $TPM = Get-Tpm  -ErrorAction SilentlyContinue
            $FirmwareVersionAtLastProvision = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\TPM\WMI" -Name "FirmwareVersionAtLastProvision" -ErrorAction SilentlyContinue).FirmwareVersionAtLastProvision
            
            $TPM | Add-Member -MemberType NoteProperty -Name "FirmwareVersionAtLastProvision" -Value $FirmwareVersionAtLastProvision

            return $TPM
        }

        if ($TPMInfo) {
                        
            $output = $null
            $output = [TPM]::new()

            $output.Computer = $Computer
            $output.DateScanned = Get-Date -Format u

            $output.TpmPresent = $TPMInfo.TpmPresent
            $output.TpmReady = $TPMInfo.TpmReady
            $output.ManufacturerId = $TPMInfo.ManufacturerId
            $output.ManufacturerVersion = $TPMInfo.ManufacturerVersion
            $output.ManagedAuthLevel = $TPMInfo.ManagedAuthLevel
            $output.OwnerAuth = $TPMInfo.OwnerAuth
            $output.OwnerClearDisabled = $TPMInfo.OwnerClearDisabled
            $output.AutoProvisioning = $TPMInfo.AutoProvisioning
            $output.LockedOut = $TPMInfo.LockedOut
            $output.LockoutCount = $TPMInfo.LockoutCount
            $output.LockoutMax = $TPMInfo.LockoutMax
            $output.SelfTest = $TPMInfo.SelfTest
            $output.ManufacturerIdHex = "0x{0:x}" -f $TPMInfo.ManufacturerId
            $output.FirmwareVersionAtLastProvision = $TPMInfo.FirmwareVersionAtLastProvision

            # Convert ManufacturerId to ManufacturerName
            foreach ($Key in $Manufacturers.Keys) {

                if ($Key -eq $TPMInfo.ManufacturerId) {
                    
                    $output.ManufacturerName = $Manufacturers[$Key]
                }
            }

            return $output
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            
            $Result = $null
            $Result = [TPM]::new()

            $Result.Computer = $Computer
            $Result.DateScanned = $DateScanned
            
            $total++
            return $Result
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Started at {0}" -f $DateScanned)
        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
        Write-Verbose ("Ended at {0}" -f (Get-Date -Format u))
    }
}