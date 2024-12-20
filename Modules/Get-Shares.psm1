function Get-Shares {
    <#
    .SYNOPSIS 
        Collects information on all existing shares on the system.

    .DESCRIPTION 
        Collects information on all existing shares on the system.

    .EXAMPLE 
        Get-Shares

    .EXAMPLE
        Get-Shares | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Shares.csv")

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-Shares} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\Shares.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-Shares} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_Shares.csv")
        }

    .NOTES 
        Updated: 2024-10-22

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2024
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
       https://github.com/TonyPhipps/Meerkat
    #>

    [CmdletBinding()]
    param(
    )

    begin{

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-Shares at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $accessMask = [Ordered]@{
            [uint32]'0x80000000' = 'Read'
            [uint32]'0x40000000' = 'Write'
            [uint32]'0x20000000' = 'Execute'
            [uint32]'0x10000000' = 'All'
            [uint32]'0x02000000' = 'MaximumAllowed'
            [uint32]'0x01000000' = 'AccessSystemSecurity'
            [uint32]'0x00100000' = 'Synchronize'
            [uint32]'0x00080000' = 'WriteOwner'
            [uint32]'0x00040000' = 'WriteDAC'
            [uint32]'0x00020000' = 'ReadControl'
            [uint32]'0x00010000' = 'Delete'
            [uint32]'0x00000100' = 'WriteAttributes'
            [uint32]'0x00000080' = 'ReadAttributes'
            [uint32]'0x00000040' = 'DeleteChild'
            [uint32]'0x00000020' = 'Execute/Traverse'
            [uint32]'0x00000010' = 'WriteExtendedAttributes'
            [uint32]'0x00000008' = 'ReadExtendedAttributes'
            [uint32]'0x00000004' = 'AppendData/AddSubdirectory'
            [uint32]'0x00000002' = 'WriteData/AddFile'
            [uint32]'0x00000001' = 'ReadData/ListDirectory'
          }
    }

    process{

        $Shares = Get-SmbShare
        $ResultsArray = ForEach ($Share in $Shares) {

            $ShareAccessArray = Get-SmbShareAccess -InputObject $Share

            $SharePermissions = "Control, Account, Rights`n"
            ForEach ($ShareAccess in $ShareAccessArray) {

                $SharePermissions += "{0}, {1}, {2}`n" -f $ShareAccess.AccessControlType, $ShareAccess.AccountName, $ShareAccess.AccessRight
            }

            if (-not ([String]::IsNullOrEmpty($Share.Path)) ){ # The IPC share has no path and no NTFS permissions
                try{ $NTFSAccessArray = Get-Acl -Path $Share.Path } catch{}
                $NTFSPermissions = "Control, Account, Rights, Inheritance, Propagation`n"
            } else {
                $NTFSPermissions = ''
                $NTFSAccessArray = @()
            }

            ForEach ($NTFSAccess in $NTFSAccessArray.Access) {
                # NTFS Permissions include an enum with most standard permissions, but some will just come out as a number. These need to be broken apart into a set of permissions based on bit masks.
                $NTFSAccessValue = $NTFSAccess.FileSystemRights.value__ | Select-Object -First 1
                $IsNonStandardFileSystemRightsValue = $null -eq ($NTFSAccessValue -as [System.Security.AccessControl.FileSystemRights])
                if ($IsNonStandardFileSystemRightsValue){
                    $NTFSAccessFileSystemRights = $accessMask.Keys |
                        Where-Object { $NTFSAccess.FileSystemRights.value__ -band $_ } |
                        ForEach-Object { $accessMask[$_] }
                    $NTFSAccessFileSystemRights = $NTFSAccessFileSystemRights -join " - "
                }
                else {
                    $NTFSAccessFileSystemRights = $NTFSAccess.FileSystemRights -replace ", ", " - "
                }

                $PropagationFlags = $NTFSAccess.PropagationFlags -replace ", ", " - "
                $InheritanceFlags = $NTFSAccess.InheritanceFlags -replace ", ", " - "
                $NTFSPermissions += "{0}, {1}, {2}, {3}, {4}`n" -f $NTFSAccess.AccessControlType, $NTFSAccess.IdentityReference.Value, $NTFSAccessFileSystemRights, $InheritanceFlags, $PropagationFlags
            }

            $output = New-Object -TypeName PSObject

            $output | Add-Member -MemberType NoteProperty -Name Name -Value $Share.Name
            $output | Add-Member -MemberType NoteProperty -Name Path -Value $Share.Path
            $output | Add-Member -MemberType NoteProperty -Name Description -Value $Share.Description
            $output | Add-Member -MemberType NoteProperty -Name SharePermissions -Value $SharePermissions
            $output | Add-Member -MemberType NoteProperty -Name NTFSPermissions -Value $NTFSPermissions

            $output
        }
        
        ForEach ($Result in $ResultsArray) {

            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned 
        }

        return $ResultsArray | Select-Object Host, DateScanned, Name, Path, Description, SharePermissions, NTFSPermissions
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ"))
    }
}
