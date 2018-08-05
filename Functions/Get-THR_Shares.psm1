function Get-THR_Shares {
    <#
    .SYNOPSIS 
        Gets the shares configured on a given system.

    .DESCRIPTION 
        Gets the shares configured on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_Shares 
        Get-THR_Shares SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_Shares
        Get-THR_Shares $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_Shares

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

        class SharePermission {

            [String] $Computer
            [string] $DateScanned
            
            [String] $Name
            [String] $Path
            [String] $Description
            [String] $TrusteeName
            [String] $TrusteeDomain
            [String] $TrusteeSID
            [String] $AccessType
            [String] $AccessMask
            [String] $SharePermissions
        }

        $Command = {

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

            $Shares = Get-WmiObject -class Win32_share -Filter "type=0"

            if ($Shares) {
                
                $OutputArray = foreach ($Share in $Shares) {

                    $ShareName = $Share.Name

                    $ShareSettings = Get-WmiObject -class Win32_LogicalShareSecuritySetting  -Filter "Name='$ShareName'"

                    $DACLArray = $ShareSettings.GetSecurityDescriptor().Descriptor.DACL

                    foreach ($DACL in $DACLArray) {

                        $TrusteeName = $DACL.Trustee.Name
                        $TrusteeDomain = $DACL.Trustee.Domain
                        $TrusteeSID = $DACL.Trustee.SIDString

                        # 1 Deny 0 Allow
                        if ($DACL.AceType) 
                            { $Type = "Deny" }
                        else 
                            { $Type = "Allow" }
            
                        $SharePermission = foreach ($Key in $PermissionFlags.Keys) { # Convert AccessMask to human-readable format

                            if ($Key -band $DACL.AccessMask) {
                                            
                                $PermissionFlags[$Key] + ";"
                            }
                        }

                        $output = New-Object -TypeName PSObject
                        
                        $output | Add-Member -MemberType NoteProperty -Name Computer -Value $Share.PSComputerName
                        $output | Add-Member -MemberType NoteProperty -Name Name -Value $Share.Name
                        $output | Add-Member -MemberType NoteProperty -Name Path -Value $Share.Path
                        $output | Add-Member -MemberType NoteProperty -Name DESCRIPTION -Value $Share.DESCRIPTION
                        $output | Add-Member -MemberType NoteProperty -Name TrusteeName -Value $TrusteeName
                        $output | Add-Member -MemberType NoteProperty -Name TrusteeDomain -Value $TrusteeDomain
                        $output | Add-Member -MemberType NoteProperty -Name TrusteeSID -Value $TrusteeSID
                        $output | Add-Member -MemberType NoteProperty -Name AccessType -Value $Type
                        $output | Add-Member -MemberType NoteProperty -Name AccessMask -Value $DACL.AccessMask
                        $output | Add-Member -MemberType NoteProperty -Name SharePermissions -Value $SharePermission

                        $output
                    }
                }

                return $OutputArray
            }
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

        if ($ResultsArray){

            $OutputArray = foreach($Entry in $ResultsArray) {

                $output = $null
                $output = [SharePermission]::new()
        
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format o
                
                $output.Name = $Entry.Name
                $output.Path = $Entry.Path
                $output.DESCRIPTION = $Entry.DESCRIPTION
                $output.TrusteeName = $Entry.TrusteeName
                $output.TrusteeDomain = $Entry.TrusteeDomain
                $output.TrusteeSID = $Entry.TrusteeSID
                $output.AccessType = $Entry.Type
                $output.AccessMask = $Entry.AccessMask
                $output.SharePermissions = $Entry.SharePermissions

                $output
            }

            $total++
            return $OutputArray
        
        }
        else {
                
            $output = $null
            $output = [SharePermission]::new()

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