function Get-THR_Shares {
    <#
    .SYNOPSIS 
        Gets the shares configured on a given system.

    .DESCRIPTION 
        Gets the shares configured on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Fails  
        Provide a path to save failed systems to.

    .EXAMPLE 
        Get-THR_Shares 
        Get-THR_Shares SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Shares
        Get-THR_Shares $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Shares

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

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,

        [Parameter()]
        $Fails
    )

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        $PermissionFlags = @{
            0x1     =     "Read-List"
            0x2     =     "Write-Create"
            0x4     =     "Append-Create Subdirectory"                  	
            0x20    =     "Execute file-Traverse directory"
            0x40    =     "Delete child"
            0x10000 =     "Delete"                     
            0x40000 =     "Write access to DACL"
            0x80000 =     "Write Owner"
        }

        class SharePermission
        {
            [String] $Computer
            [Datetime] $DateScanned
            
            [String] $Name
            [String] $Path
            [String] $Description
            [String] $TrusteeName
            [String] $TrusteeDomain
            [String] $TrusteeSID
            [String] $AccessType
            [String] $AccessMask
            [String] $Permissions
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        $Shares = $null
        $Shares = Get-WmiObject -class Win32_share -Filter "type=0" -ComputerName $Computer -ErrorAction SilentlyContinue

        if ($Shares) {
            $OutputArray = $null
            $OutputArray = @()

            foreach ($Share in $Shares) {

                $ShareName = $Share.Name

                $ShareSettings = Get-WmiObject -class Win32_LogicalShareSecuritySetting  -Filter "Name='$ShareName'" -ComputerName $Computer -ErrorAction SilentlyContinue

                $DACLs = $ShareSettings.GetSecurityDescriptor().Descriptor.DACL

                foreach ($DACL in $DACLs) {

                    $TrusteeName = $DACL.Trustee.Name
                    $TrusteeDomain = $DACL.Trustee.Domain
                    $TrusteeSID = $DACL.Trustee.SIDString

                    # 1 Deny 0 Allow
                    if ($DACL.AceType) 
                        { $Type = "Deny" }
                    else 
                        { $Type = "Allow" }
        
                    $SharePermission = $null

                    # Convert AccessMask to human-readable format
                    foreach ($Key in $PermissionFlags.Keys) {

                        if ($Key -band $DACL.AccessMask) {
                                          
                            $SharePermission += $PermissionFlags[$Key]       
                            $SharePermission += " "
                        }
                    }

                    $output = $null
                    $output = [SharePermission]::new()

                    $output.Computer = $Computer
                    $output.DateScanned = Get-Date -Format u
                    $output.Computer = $Share.PSComputerName
                    $output.Name = $Share.Name
                    $output.Path = $Share.Path
                    $output.DESCRIPTION = $Share.DESCRIPTION
                    $output.TrusteeName = $TrusteeName
                    $output.TrusteeDomain = $TrusteeDomain
                    $output.TrusteeSID = $TrusteeSID
                    $output.AccessType = $Type
                    $output.AccessMask = $DACL.AccessMask
                    $output.Permissions = $SharePermission

                    $OutputArray += $output
                }
            }

            return $OutputArray
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer)
            if ($Fails) {
                
                $total++
                Add-Content -Path $Fails -Value ("$Computer")
            }
            else {
                
                $output = $null
                $output = [SharePermission]::new()

                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u
                
                $total++
                return $output
            }
        }
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed)
    }
}