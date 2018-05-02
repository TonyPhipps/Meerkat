Function Copy-WithProgress { # https://blogs.technet.microsoft.com/heyscriptingguy/2015/12/20/build-a-better-copy-item-cmdlet-2/

    Param(
        $Source,
        $Destination
    )

    $Source = $Source.tolower()
    $Filelist = Get-Childitem $Source –Recurse
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