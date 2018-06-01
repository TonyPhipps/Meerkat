#
# Module manifest for module 'THRecon'
#
# Generated by: Various Authors
#
# Generated on: 2018-05-31
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'THRecon.psm1'

# Version number of this module.
ModuleVersion = '1.0'

# Supported PSEditions
CompatiblePSEditions = 'Core'

# ID used to uniquely identify this module
GUID = 'edbeb67f-d737-4ca3-b0f3-25fb5e2e3d76'

# Author of this module
Author = 'Various Authors'

# Company or vendor of this module
CompanyName = 'THRecon Contributors'

# Copyright statement for this module
Copyright = 'This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/'

# Description of the functionality provided by this module
Description = 'Threat Hunting Using Data Snapshots'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Get-THR_ADS', 'Get-THR_ARP', 'Get-THR_Autoruns', 'Get-THR_BitLocker', 
               'Get-THR_Certificates', 'Get-THR_Computer', 'Get-THR_DLLs', 
               'Get-THR_DNS', 'Get-THR_Drivers', 'Get-THR_EnvVars', 
               'Get-THR_EventLogs', 'Get-THR_GroupMembers', 'Get-THR_Handles', 
               'Get-THR_Hardware', 'Get-THR_Hosts', 'Get-THR_Hotfixes', 'Get-THR_MAC', 
               'Get-THR_MRU', 'Get-THR_NetAdapters', 'Get-THR_NetRoute', 
               'Get-THR_Processes', 'Get-THR_RecycleBin', 'Get-THR_Registry', 
               'Get-THR_SCCM_BHO', 'Get-THR_SCCM_Computer', 'Get-THR_SCCM_EnvVars', 
               'Get-THR_SCCM_GroupMembers', 'Get-THR_SCCM_LogicalDisks', 
               'Get-THR_SCCM_Services', 'Get-THR_SCCM_Sessions', 
               'Get-THR_SCCM_Software', 'Get-THR_SCCM_USBDevices', 
               'Get-THR_SCCM_WinEvents', 'Get-THR_ScheduledTasks', 
               'Get-THR_Services', 'Get-THR_Sessions', 'Get-THR_Shares', 
               'Get-THR_Software', 'Get-THR_Strings', 'Get-THR_TCPConnections', 
               'Get-THR_TPM', 'Invoke-THR', 'Invoke-THR_PSexec', 'Add-WinEventXMLData', 
               'Invoke-Portscan', 'Test-SharePermissions'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = 'THRecon.psd1', 'THRecon.psm1', 'Functions\Get-THR_ADS.psm1', 
               'Functions\Get-THR_ARP.psm1', 'Functions\Get-THR_Autoruns.psm1', 
               'Functions\Get-THR_BitLocker.psm1', 
               'Functions\Get-THR_Certificates.psm1', 
               'Functions\Get-THR_Computer.psm1', 'Functions\Get-THR_DLLs.psm1', 
               'Functions\Get-THR_DNS.psm1', 'Functions\Get-THR_Drivers.psm1', 
               'Functions\Get-THR_EnvVars.psm1', 
               'Functions\Get-THR_EventLogs.psm1', 
               'Functions\Get-THR_GroupMembers.psm1', 
               'Functions\Get-THR_Handles.psm1', 'Functions\Get-THR_Hardware.psm1', 
               'Functions\Get-THR_Hosts.psm1', 'Functions\Get-THR_Hotfixes.psm1', 
               'Functions\Get-THR_MAC.psm1', 'Functions\Get-THR_MRU.psm1', 
               'Functions\Get-THR_NetAdapters.psm1', 
               'Functions\Get-THR_NetRoute.psm1', 
               'Functions\Get-THR_Processes.psm1', 
               'Functions\Get-THR_RecycleBin.psm1', 
               'Functions\Get-THR_Registry.psm1', 
               'Functions\Get-THR_SCCM_BHO.psm1', 
               'Functions\Get-THR_SCCM_Computer.psm1', 
               'Functions\Get-THR_SCCM_EnvVars.psm1', 
               'Functions\Get-THR_SCCM_GroupMembers.psm1', 
               'Functions\Get-THR_SCCM_LogicalDisks.psm1', 
               'Functions\Get-THR_SCCM_Services.psm1', 
               'Functions\Get-THR_SCCM_Sessions.psm1', 
               'Functions\Get-THR_SCCM_Software.psm1', 
               'Functions\Get-THR_SCCM_USBDevices.psm1', 
               'Functions\Get-THR_SCCM_WinEvents.psm1', 
               'Functions\Get-THR_ScheduledTasks.psm1', 
               'Functions\Get-THR_Services.psm1', 
               'Functions\Get-THR_Sessions.psm1', 'Functions\Get-THR_Shares.psm1', 
               'Functions\Get-THR_Software.psm1', 'Functions\Get-THR_Strings.psm1', 
               'Functions\Get-THR_TCPConnections.psm1', 
               'Functions\Get-THR_TPM.psm1', 'Functions\Invoke-THR.psm1', 
               'Functions\Invoke-THR_PSexec.psm1', 
               'Utilities\Add-WinEventXMLData.psm1', 
               'Utilities\Invoke-Portscan.psm1', 
               'Utilities\Test-SharePermissions.psm1'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

