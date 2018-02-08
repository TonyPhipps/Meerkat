$RunDate = Get-Date -Format 'yyyy-MM-dd';

$InputList = "C:\Temp\Scope.csv";
$OutputPath = "C:\Temp\Hunt-Environmentvariables_{0}.csv" -f $RunDate;

$jobArguments = @{
    Name = "$_"
    Throttle = 20
    InputObject = (Get-Content $InputList -totalcount 10)
    FunctionsToLoad = "Hunt-Environmentvariables"
    ScriptBlock = [scriptblock]::Create('Hunt-Environmentvariables $_')
};

$stopwatch = New-Object System.Diagnostics.Stopwatch;
$stopwatch.Start();

Start-RSJob @JobArguments | Select-Object ID, Name, Command | Format-Table -Autosize;

# Job management 
While (Get-RSJob) { # So long as there is a job remaining 
    $CompletedJobs = Get-RSJob -State Completed;
    $RunningJobs = Get-RSJob -State Running;
    $NotStartedJobs = Get-RSJob -State NotStarted;
    $TimeStamp = Get-Date -Format 'yyyy/MM/dd hh:mm:ss';
    
    Write-Host -Object ("$TimeStamp - Saving $($CompletedJobs.Count) completed jobs. There are $($RunningJobs.Count)/$($NotStartedJobs.Count) jobs still running.");
    
    ForEach ($DoneJob in $CompletedJobs) {

        Receive-RSJob -Id $DoneJob.ID | Export-Csv $OutputPath -NoTypeInformation -Append;
        Stop-RSJob -Id $DoneJob.ID;
        Remove-RSJob -Id $DoneJob.ID;
    };

    Start-Sleep -Seconds 10;
};

$elapsed = $stopwatch.Elapsed;
Write-Host $elapsed;
