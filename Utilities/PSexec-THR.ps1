Param(
    #Local Parameters
    [string]$ModulePath = "C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon\",
    [string]$Output = "C:\Temp\Results",
    [string]$ModuleName = "THRecon.psm1",
    [string]$PSExec = "C:\Program Files\Sysinternals",
    
    #Remote Parameters
    [string]$Computer = "127.0.0.1",
    [string]$RemoteModulePath = "c$\Windows\Toolkit",
    [string]$RemoteOutputPath = "c:\Windows\Toolkit\Results",
    [string]$Command = "Invoke-THR"
)

if($Command -like "*output*"){
    Write-Error -Message "Specify remote output via -RemoteOutputPath parameter."
    exit
}

$Command = $Command + " -Output $RemoteOutputPath"

# Prepare NTFS/Share path versions
$ModuleShare = $RemoteModulePath.Replace(':', '$')
$ModuleNTFS = $RemoteModulePath.Replace('$', ':')
$OutputShare = $RemoteOutputPath.Replace(':', '$')

# Stage files
Copy-Item $ModulePath -Recurse -Force -Destination \\$Computer\$ModuleShare

# Import modulea and execute command
& $PSExec\PsExec.exe \\$Computer -accepteula powershell -ExecutionPolicy ByPass -nologo -command "& {import-module $ModuleNTFS\$ModuleName; & $Command}"

# Retrieve Results
Copy-Item \\$Computer\$OutputShare -Recurse -Force -Destination $Output

# Cleanup
Remove-Item \\$Computer\$OutputShare -Recurse -Force
Remove-Item \\$Computer\$ModuleShare -Recurse -Force
