function Get-EditDistance {
    <#
    .SYNOPSIS 
        Gets Edit Distance Score (or raw Edit Distance) between two strings. 

    .DESCRIPTION 
        Uses the Wagner-Fischer algorithm to determine the Levenshtein Distance (or Edit Distance) between two strings.
        "The sum of the costs of insertions, replacements, deletions, and null actions needed to change one string into the other."

        A SCORE (default) closer to 1 represents a closer match, with 1 indicating a perfect match.
        A DISTANCE (returned with -Raw) closer to 0 represents a closer match, with 0 indicating a perfect match.

    .PARAMETER String1 
        First String; to be compared to String2.

    .PARAMETER String2
        Second String; to be compared to String1.

    .PARAMETER IngoreCase
        Disabled case sensitivity (default is OFF, case sensitive)

    .PARAMETER Score
        Returns the raw Distance, rather than the score.

    .EXAMPLE 
        Get-EditDistance https://www.mycompany.com http://www.myc0npany.com
        Get-EditDistance google bing
        Get-EditDistance george@mycompany.com goerge@mycompany.com
        Get-EditDistance lsass.exe 1sass.exe

    .NOTES
        TODO: Add support (or a sister module) for comparing a string to a list of strings and returning the number of matches that fall within a given score/distance.
        
        Updated: 2018-08-02

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
       https://en.wikipedia.org/wiki/Edit_distance
       https://en.wikipedia.org/wiki/Wagner-Fischer_algorithm
       https://en.wikipedia.org/wiki/Levenshtein_distance
    #>


    param(
        [Parameter(Position = 0)]
        [string] $String1,
        [Parameter(Position = 1)]
        [string] $String2,
        [switch] $IgnoreCase,
        [switch] $Raw
    )

    begin{

    }

    process{

        if ($String1.length -eq 0 -or $String2.length -eq 0) {
            
            return 0
        }
        
        if($IgnoreCase) {
            
            $String1 = $String1.ToLowerInvariant()
            $String2 = $String2.ToLowerInvariant()
        }

        # Build a 2d array with columns equal to String1's length
        # ... and rows equal to String2's length
        $Matrix = new-object -type 'int[,]' -arg ($String1.length + 1), ($String2.length + 1)

        # Fill out top row
        for ($x = 0; $x -le $Matrix.GetUpperBound(0); $x++) {

            $Matrix[$x, 0] = $x
        }

        # Fill out first column
        for ($y = 0; $y -le $Matrix.GetUpperBound(1); $y++) {
            
            $Matrix[0, $y] = $y
        }

        # For every cell in the first row
        for ($x = 1; $x -le $Matrix.GetUpperBound(0); $x++) {
            
            # for every cell in the first column
            for ($y = 1; $y -le $Matrix.GetUpperBound(1); $y++) {
                
                # If the characters match, set distance to zero
                if ([Convert]::ToInt32((($String1[$x - 1] -ceq $String2[$y - 1])))) {
                    $Cost = 0
                }
                else{
                    $Cost = 1
                }

                # Identify differences between two characters
                $Deletion = $Matrix[($x - 1), $y] + 1
                $Insertion = $Matrix[$x, ($y - 1)] + 1
                $Substitution = $Matrix[($x - 1), ($y - 1)] + $Cost
                
                # Set this cell to the distance cost between the two characters
                $Matrix[$x, $y] = [Math]::Min([Math]::Min($Deletion, $Insertion), $Substitution)
            }
        }

        # Raw distance is found in the last column of the last row
        $Distance = ($Matrix[$Matrix.GetUpperBound(0), $Matrix.GetUpperBound(1)])

        if ($Raw){
            
            return $Distance
        }
        else{
            
            return (1 - ($Distance) / ([Math]::Max($String1.Length, $String2.Length)))
        }
    }
}