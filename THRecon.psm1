# Make scripts available for use.

Get-ChildItem -Path $PSScriptRoot\Functions -Filter *.psm1 | ForEach-Object -Process { Import-Module $PSItem.FullName }
Get-ChildItem -Path $PSScriptRoot\Utilities -Filter *.psm1 | ForEach-Object -Process { Import-Module $PSItem.FullName }