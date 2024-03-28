function Get-NetAdapters {
    <#
    .SYNOPSIS 
        Gets network interface settings.

    .DESCRIPTION 
        Gets network interface settings.

    .EXAMPLE 
        Get-NetAdapters

    .EXAMPLE 
        Invoke-Command -ComputerName remoteHost -ScriptBlock ${Function:Get-NetAdapters} | 
        Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
        Export-Csv -NoTypeInformation ("c:\temp\NetAdapters.csv")

    .EXAMPLE 
        $Targets = Get-ADComputer -filter * | Select -ExpandProperty Name
        ForEach ($Target in $Targets) {
            Invoke-Command -ComputerName $Target -ScriptBlock ${Function:Get-NetAdapters} | 
            Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID | 
            Export-Csv -NoTypeInformation ("c:\temp\" + $Target + "_NetAdapters.csv")
        }

    .NOTES 
        Updated: 2024-03-27

        Contributing Authors:
            Jeremy Arnold
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

        $DateScanned = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ")
        Write-Information -InformationAction Continue -MessageData ("Started Get-NetAdapters at {0}" -f $DateScanned)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
    }

    process{
            
        $AdaptersArray = Get-NetAdapter -ErrorAction SilentlyContinue
        $AdapterConfigArray = Get-CimInstance Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue
        $NetConnectionProfileArray = Get-NetConnectionProfile
        $NetFirewallProfileArray = Get-NetFirewallProfile -PolicyStore ActiveStore

        $ResultsArray = $AdaptersArray | Where-Object {$_.MediaConnectionState -eq "Connected"}
        
        foreach ($Result in $ResultsArray) {
            
            $AdapterConfig = $AdapterConfigArray | Where-Object {$_.InterfaceIndex -eq $Result.IfIndex}
            $NetConnectionProfile = $NetConnectionProfileArray | Where-Object {$_.InterfaceIndex -eq $Result.IfIndex}
            $NetFirewallProfile = $NetFirewallProfileArray | Where-Object {$_.Name -eq $NetConnectionProfile.NetworkCategory}

            $Result | Add-Member -MemberType NoteProperty -Name "Host" -Value $env:COMPUTERNAME
            $Result | Add-Member -MemberType NoteProperty -Name "DateScanned" -Value $DateScanned
            $Result | Add-Member -MemberType NoteProperty -Name IPAddress -Value ($AdapterConfig.IPAddress -join ", ")
            $Result | Add-Member -MemberType NoteProperty -Name IPsubnet -Value ($AdapterConfig.IPsubnet -join ", ")
            $Result | Add-Member -MemberType NoteProperty -Name DefaultIPGateway -Value ($AdapterConfig.DefaultIPGateway -join ", ")
            $Result | Add-Member -MemberType NoteProperty -Name DNSServerSearchOrder -Value ($AdapterConfig.DNSServerSearchOrder -join ", ")
            $Result | Add-Member -MemberType NoteProperty -Name DHCPEnabled -Value $AdapterConfig.DHCPEnabled
            $Result | Add-Member -MemberType NoteProperty -Name NetworkCategory -Value $NetConnectionProfile.NetworkCategory
            $Result | Add-Member -MemberType NoteProperty -Name FirewallEnabled -Value $NetFirewallProfile.Enabled
        }

        return $AdaptersArray | Select-Object Host, DateScanned, SystemName, InterfaceDescription, Name, MediaConnectionState, 
        ifIndex, Speed, MacAddress, IPAddress, IPSubnet, DefaultIPGateway, DNSServerSearchOrder, MtuSize, PromiscuousMode, DHCPEnabled, NetworkCategory, FirewallEnabled
    }

    end{

        $elapsed = $stopwatch.Elapsed

        Write-Verbose ("Total time elapsed: {0}" -f $elapsed)
        Write-Verbose ("Ended at {0}" -f ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd hh:mm:ssZ"))
    }
}
