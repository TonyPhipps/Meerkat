function Get-Entropy {
    <#
    .SYNOPSIS 
        Returns the entropy of a given string. A higher entropy score suggests a higher chance of being random.

    .DESCRIPTION 
        Uses Shannon Entropy algorithm to calculate and return the entropy of a given string.
        Entropy can be used to determine the likelihood that a string was generated with a randomization formula.
        For example, locating DGA-generated domains OR a randomly generated file/process name.

    .PARAMETER String
        The string for which entropy is to be calculated.

    .EXAMPLE 
        Get-Entropy "lsass.exe"
        Get-Entropy "33fsd.exe"
        Get-Entropy "This is an encoded string"
        Get-Entropy "https://www.google.com"
        Get-Entropy "https://3lkl3h4kljnl.fruityflies.com"
        Get-Entropy "VGhpcyBpcyBhbiBlbmNvZGVkIHN0cmluZw=="

    .NOTES      
        Updated: 2018-08-03

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
       https://en.wiktionary.org/wiki/Shannon_entropy
       http://rosettacode.org/wiki/Entropy
       https://en.wikipedia.org/wiki/Domain_generation_algorithm

    #>

    param(
        [Parameter(Position = 0)]
        [string] $String
    )

    begin{}

    process{

        $Entropy = $String.ToCharArray() | 
            Group-Object | 
                ForEach-Object {
                    $p = $_.Count / $String.Length
                    $i = [Math]::Log($p, 2)
                    -$p * $i
                } | 
                    Measure-Object -Sum | 
                        ForEach-Object Sum
    
        return $Entropy
    }
    
    end{}
}