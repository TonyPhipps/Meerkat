function Get-THR_GroupMembers {
    <#
    .SYNOPSIS 
        Gets a list of the members of each local group on a given system.

    .DESCRIPTION 
        Gets a list of the members of each local group on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_GroupMembers 
        Get-THR_GroupMembers SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_GroupMembers
        Get-THR_GroupMembers $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_GroupMembers

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
       https://github.com/TonyPhipps/THRecon/wiki/GroupMembers
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $DateScanned = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Information -InformationAction Continue -MessageData ("Started {0} at {1}" -f $MyInvocation.MyCommand.Name, $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()

        $total = 0

        class Member
        {
            [String] $Computer
            [dateTime] $DateScanned

            [String] $UserDomain
            [String] $UserName
            [String] $UserSID
            [String] $UserPrincipalSource
            [String] $UserObjectClass
            [String] $GroupName
            [String] $GroupDescription
            [String] $GroupSID
            [String] $GroupPrincipalSource
            [String] $GroupObjectClass
        }
	}

    process{

        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present

        Write-Verbose ("{0}: Querying remote system" -f $Computer) 
        
        $GroupMembers = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
            $GroupArray = Get-LocalGroup
            
            $GroupMembers = @()
            
            Foreach ($Group in $GroupArray) { # get members of each group
                
                $MemberArray = Get-LocalGroupMember -Group $Group.Name
                
                Foreach ($Member in $MemberArray) { # add group properties to each member
            
                    $Member | Add-Member -MemberType NoteProperty -Name "UserDomain" -Value $Member.Name.Split("\")[0]
                    $Member | Add-Member -MemberType NoteProperty -Name "UserName" -Value $Member.Name.Split("\")[1]
                    $Member | Add-Member -MemberType NoteProperty -Name "GroupDescription" -Value $Group.DESCRIPTION
                    $Member | Add-Member -MemberType NoteProperty -Name "GroupName" -Value $Group.Name
                    $Member | Add-Member -MemberType NoteProperty -Name "GroupSID" -Value $Group.SID
                    $Member | Add-Member -MemberType NoteProperty -Name "GroupPrincipalSource" -Value $Group.PrincipalSource
                    $Member | Add-Member -MemberType NoteProperty -Name "GroupObjectClass" -Value $Group.ObjectClass
                    $GroupMembers += $Member
                }
            }

            return $GroupMembers
        }

        if ($GroupMembers) {
            
            $outputArray = @()

            Foreach ($GroupMember in $GroupMembers) {
                
                $output = $null
                $output = [Member]::new()
    
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u
    
                $output.UserDomain = $GroupMember.UserDomain
                $output.UserName = $GroupMember.UserName
                $output.UserSID = $GroupMember.SID
                $output.UserPrincipalSource = $GroupMember.PrincipalSource
                $output.UserObjectClass = $GroupMember.ObjectClass
                $output.GroupName = $GroupMember.GroupName
                $output.GroupDescription = $GroupMember.GroupDescription
                $output.GroupSID = $GroupMember.GroupSID
                $output.GroupPrincipalSource = $GroupMember.GroupPrincipalSource
                $output.GroupObjectClass = $GroupMember.GroupObjectClass

                $outputArray += $output
            }

            $total++
            return $outputArray
        }
        else {
                
            $output = $null
            $output = [Member]::new()

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