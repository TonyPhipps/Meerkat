# Make scripts available for use.

Get-ChildItem -Path .\Functions -Filter *.psm1 | ForEach-Object -Process { Import-Module $PSItem.FullName };
Get-ChildItem -Path .\Utilities -Filter *.psm1 | ForEach-Object -Process { Import-Module $PSItem.FullName };