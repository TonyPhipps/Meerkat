$FileList = @('THRUST.psd1', 'THRUST.psm1');
$FunctionsToExport = @();

Get-ChildItem "e:\scripts\THRUST\functions" -Filter *.ps1 | Select-Object -ExpandProperty FullName | ForEach-Object {
    $File = Split-Path $_ -Leaf
    $Function = $File.Split(".")[0];
    $FileList += "Functions\" + $File;
    $FunctionsToExport += $Function;
};

$RunDate = Get-Date -Format 'yyyy-MM-dd';

$manifest = @{
    RootModule = 'THRUST.psm1'
    Path = 'E:\scripts\THRUST\THRUST.psd1'
    ModuleVersion = '1.0'
    CompatiblePSEditions = @('Core')
    Author = 'Various Authors'
    CompanyName = 'THRUST Contributors'
    Copyright = 
        'This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/'
    Description = 'Threat Hunting Using Data Snapshots'
    FileList = $FileList
    FunctionsToExport = $FunctionsToExport
}

New-ModuleManifest @manifest