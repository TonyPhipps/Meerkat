function Get-THR_DNS {
    <#
    .SYNOPSIS 
        Gets the DNS cache for the given computer(s).

    .DESCRIPTION 
        Gets the DNS cache from all connected interfaces for the given computer(s).

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .EXAMPLE 
        Get-THR_DNS 
        Get-THR_DNS SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-THR_DNS
        Get-THR_DNS -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-THR_DNS

    .NOTES 
        Updated: 2018-02-07

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
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME
    )

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff"
        Write-Verbose ("Started at {0}" -f $datetime)

        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $total = 0

        enum recordType {
            A = 1
            NS = 2
            CNAME = 5
            SOA = 6
            WKS = 11
            PTR = 12
            HINFO = 13
            MINFO = 14
            MX = 15
            TXT = 16
            AAAA = 28
            SRV = 33
            ALL = 255
        }

        enum recordStatus {
            Success = 0
            NotExist = 9003
            NoRecords = 9501
        }

        enum recordResponse {
            Question = 0
            Answer = 1
            Authority = 2
            Additional = 3
        }

        class DNSCache {
            [string] $Computer
            [Datetime] $DateScanned

            [recordStatus] $Status
            [String] $DataLength
            [recordresponse] $RecordResponse
            [String] $TTL
            [RecordType] $RecordType
            [String] $Record
            [string] $Entry
            [string] $RecordName
        }
    }

    process{
            
        $Computer = $Computer.Replace('"', '')  # get rid of quotes, if present
        
        Write-Verbose ("{0}: Querying remote system" -f $Computer) 
        $dnsCache = $null
        $dnsCache = Invoke-Command -ComputerName $Computer -ScriptBlock { Get-DnsClientCache } -ErrorAction SilentlyContinue
       
        if ($dnsCache) { 
            
            $OutputArray = @()

            Write-Verbose ("{0}: Looping through retrived results" -f $Computer)
            foreach ($dnsRecord in $dnsCache) {
             
                $output = $null
                $output = [DNSCache]::new()
                
                $output.Computer = $Computer
                $output.DateScanned = Get-Date -Format u

                $output.Status = $dnsRecord.status
                $output.DataLength = $dnsRecord.dataLength
                $output.RecordResponse = $dnsRecord.section
                $output.TTL = $dnsRecord.TimeToLive
                $output.RecordType = $dnsRecord.Type
                $output.Record = $dnsRecord.data
                $output.Entry = $dnsRecord.entry
                $output.RecordName = $dnsRecord.Name                 

                $OutputArray += $output
            }

            $elapsed = $stopwatch.Elapsed
            $total = $total + 1
            
            Write-Verbose ("System {0} complete: `t {1} `t Total Time Elapsed: {2}" -f $total, $Computer, $elapsed)

            $total = $total+1
            Return $OutputArray
        }
        else {
                
            $output = $null
            $output = [DNSCache]::new()

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