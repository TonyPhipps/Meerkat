param(
    #Local Parameters
    [string]$ModulePath = "C:\Users\$env:UserName\Documents\WindowsPowerShell\Modules\THRecon\",
    [string]$Output = "C:\Temp\Results\",
    [string]$ModuleName = "THRecon.psm1",
    [string]$PSExec = "C:\Program Files\Sysinternals",
    
    #Remote Parameters
    [string]$Computer = "127.0.0.1",
    [string]$RemoteModulePath = "c:\Windows\Toolkit\",
    [string]$RemoteOutputPath = "c:\Windows\Toolkit\Results\",
    [string]$Command = "Invoke-THR"
)

function Copy-WithProgress { # https://blogs.technet.microsoft.com/heyscriptingguy/2015/12/20/build-a-better-copy-item-cmdlet-2/

    param(
        $Source,
        $Destination
    )

    $Source = $Source.tolower()
    $Filelist = Get-Childitem $Source -Recurse
    $Total = $Filelist.count
    $Position = 0

    New-Item -ItemType Directory -Path $Destination -Force

    foreach ($File in $Filelist) {
        
        $Filename = $File.Fullname.tolower().replace($Source,"")
        $DestinationFile = ($Destination + $Filename)
        
        Copy-Item $File.FullName -Destination $DestinationFile -Recurse -Force
        
        $Position++
        Write-Progress -Activity "Copying data from $Source to $Destination" -Status "Copying File $Filename" -PercentComplete (($Position/$total)*100)
    }

    Write-Progress -Activity "Copying data from $Source to $Destination" -Completed
}

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
#Copy-Item $ModulePath -Recurse -Force -Destination \\$Computer\$ModuleShare
Copy-WithProgress -Source "$ModulePath" -Destination "\\$Computer\$ModuleShare"

# Import modules and execute command as system
& $PSExec\PsExec.exe -s \\$Computer -accepteula powershell -ExecutionPolicy ByPass -nologo -command "& {import-module $ModuleNTFS\$ModuleName; & $Command}"

# Retrieve Results
Copy-WithProgress -Source \\$Computer\$OutputShare -Destination $Output

# Cleanup
Remove-Item \\$Computer\$OutputShare -Recurse -Force
Remove-Item \\$Computer\$ModuleShare -Recurse -Force
