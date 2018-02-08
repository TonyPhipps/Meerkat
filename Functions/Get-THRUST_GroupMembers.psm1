function Get-THRUST_GroupMembers {
    <#
    .SYNOPSIS 
        Gets a list of the members of each local group on a given system.

    .DESCRIPTION 
        Gets a list of the members of each local group on a given system.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Fails  
        Provide a path to save failed systems to.

    .EXAMPLE 
        Get-THRUST_GroupMembers 
        Get-THRUST_GroupMembers SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THRUST_GroupMembers
        Get-THRUST_GroupMembers $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THRUST_GroupMembers

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
       https://github.com/TonyPhipps/THRUST
    #>

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

        class Member
        {
            [String] $Computer
            [dateTime] $DateScanned

            [String] $Name
            [String] $SID
            [String] $PrincipalSource
            [String] $ObjectClass
            [String] $GroupName
            [String] $GroupDescription
            [String] $GroupSID
            [String] $GroupPrincipalSource
            [String] $GroupObjectClass
        };
	};

    process{

        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

        Write-Verbose ("{0}: Querying remote system" -f $Computer); 
        
        $groupMembers = $null;
        $groupMembers = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
            $groups = $null;
            $groups = Get-LocalGroup;
            
            $groupMembers = @();
            
            Foreach ($group in $groups) { # get members of each group
                
                $members = $null;
                $members = Get-LocalGroupMember -Group $group.Name;
                
                Foreach ($member in $members) { # add group properties to each member
            
                    $member | Add-Member -MemberType NoteProperty -Name "GroupDescription" -Value $group.DESCRIPTION;
                    $member | Add-Member -MemberType NoteProperty -Name "GroupName" -Value $group.Name;
                    $member | Add-Member -MemberType NoteProperty -Name "GroupSID" -Value $group.SID;
                    $member | Add-Member -MemberType NoteProperty -Name "GroupPrincipalSource" -Value $group.PrincipalSource;
                    $member | Add-Member -MemberType NoteProperty -Name "GroupObjectClass" -Value $group.ObjectClass;
                    $groupMembers += $member;
                };
            };
            
            return $groupMembers;
        };

        if ($groupMembers) {
            
            $outputArray = @();

            Foreach ($groupMember in $groupMembers) {
                
                $output = $null;
                $output = [Member]::new();
    
                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
    
                $output.Name = $groupMember.Name;
                $output.SID = $groupMember.SID;
                $output.PrincipalSource = $groupMember.PrincipalSource;
                $output.ObjectClass = $groupMember.ObjectClass;
                $output.GroupName = $groupMember.GroupName;
                $output.GroupDescription = $groupMember.GroupDescription;
                $output.GroupSID = $groupMember.GroupSID;
                $output.GroupPrincipalSource = $groupMember.GroupPrincipalSource;
                $output.GroupObjectClass = $groupMember.GroupObjectClass;

                $outputArray += $output;
            };

            $total++;
            return $outputArray;
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [Member]::new();

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