Function Add-WinEventXMLData {
    <#
    .SYNOPSIS
        Add XML fields to an event log record.
    
    .DESCRIPTION
        Add XML fields to an event log record.
        Takes in Event Log entries from Get-WinEvent, converts each to XML, extracts all properties and adds them to the event object.
    
    .PARAMETER Event
        One or more events.
        Accepts data from Get-WinEvent or any System.Diagnostics.Eventing.Reader.EventLogRecord object
    
    .INPUTS
        System.Diagnostics.Eventing.Reader.EventLogRecord
    
    .OUTPUTS
        System.Diagnostics.Eventing.Reader.EventLogRecord
    
    .EXAMPLE
        Get Windows Applocker events and XML fields.
        Get-WinEvent -FilterhashTable @{ LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8002","8003","8004" } -MaxEvents 10 | 
            Add-WinEventXMLData | 
            Select-Object *;

    .EXAMPLE
        Get Windows Sysmon events and XML fields.
        Get-WinEvent -filterhashtable @{ LogName="Microsoft-Windows-Sysmon/Operational" } | 
            Add-WinEventXMLData | 
            Select-Object *;
        
        Or from a WEF/WEC:
        Get-WinEvent -ComputerName WEFSERVER -FilterHashtable @{ LogName="ForwardedEvents"; Id=1; StartTime=(Get-Date).AddDays(-2) } -MaxEvents 10 | 
            Where-Object {  $_.LogName -eq "Microsoft-Windows-Sysmon/Operational" } | 
            Add-WinEventXMLData | 
            Select-Object *;

    .EXAMPLE
        Get Windows System logs and XML fields.
        Get-WinEvent -FilterHashtable @{ LogName="System" } -MaxEvents 10 | 
            Add-WinEventXMLData | 
            Select-Object *;

    .EXAMPLE    
        Get-WinEvent -FilterHashtable @{ LogName="ForwardedEvents" } -MaxEvents 10 | 
            Add-WinEventXMLData | 
            Select-Object *;

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
    
    .FUNCTIONALITY
        Computers
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 0 )]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]]
        $Event
    );

    Process {

        $output = $_;
                    
        $EventXML = [xml]$_.ToXml();
           
        if ($EventXML.Event.UserData.RuleAndFileData) {

            Write-Verbose "Event Type: AppLocker";
            $EventXMLFields = $EventXML.Event.UserData.RuleAndFileData | Get-Member | Where-Object {$_.Membertype -eq "Property"} |  Select-Object Name;

            $EventXMLFields | ForEach-Object {
                $output | Add-Member -MemberType NoteProperty -Name $_.Name -Value $EventXML.Event.UserData.RuleAndFileData.($_.Name);
            };
        }
        elseif ($EventXML.Event.UserData.CbsPackageInitiateChanges) {
                
            Write-Verbose "Event Type: Setup";
            $EventXMLFields = $EventXML.Event.UserData.CbsPackageInitiateChanges | Get-Member | Where-Object {$_.Membertype -eq "Property"} |  Select-Object Name; ;

            $EventXMLFields | ForEach-Object {
                $output | Add-Member -MemberType NoteProperty -Name $_.Name -Value $EventXML.Event.UserData.CbsPackageInitiateChanges.($_.Name);
            };
        }
        elseif ($EventXML.Event.UserData.CbsPackageChangeState) {
                
            Write-Verbose "Event Type: Setup";
            $EventXMLFields = $EventXML.Event.UserData.CbsPackageChangeState | Get-Member | Where-Object {$_.Membertype -eq "Property"} |  Select-Object Name;

            $EventXMLFields | ForEach-Object {
                $output | Add-Member -MemberType NoteProperty -Name $_.Name -Value $EventXML.Event.UserData.CbsPackageChangeState.($_.Name);
            };
        }
        elseif ($EventXML.Event.EventData.Data[0].Name) {
                
            Write-Verbose "Event Type: Generic";
            $EventXMLFields = $EventXML.Event.EventData.Data;

            For ( $i = 0; $i -lt $EventXMLFields.count; $i++ ) {
                $output | Add-Member -MemberType NoteProperty -Name $EventXMLFields[$i].Name -Value $EventXMLFields[$i].'#text' -Force;
            };
        };

        Return $output;
    };
};
