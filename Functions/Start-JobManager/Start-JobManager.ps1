[CmdletBinding()]
param(
[Parameter(Mandatory=$true)][array]$ServersWithArguments,
[Parameter(Mandatory=$true)][scriptblock]$ScriptBlock,
[Parameter(Mandatory=$false)][bool]$DisplayReceiveJob = $true,
[Parameter(Mandatory=$false)][bool]$DisplayReceiveJobInVerboseFunction, 
[Parameter(Mandatory=$false)][bool]$NeedReturnData = $false,
[Parameter(Mandatory=$false)][scriptblock]$VerboseFunctionCaller,
[Parameter(Mandatory=$false)][scriptblock]$HostFunctionCaller
)

#Function Version 1.1
Function Write-VerboseWriter {
param(
[Parameter(Mandatory=$true)][string]$WriteString 
)
    if($VerboseFunctionCaller -eq $null)
    {
        Write-Verbose $WriteString
    }
    else 
    {
        &$VerboseFunctionCaller $WriteString
    }
}

Function Write-HostWriter {
param(
[Parameter(Mandatory=$true)][string]$WriteString 
)
    if($HostFunctionCaller -eq $null)
    {
        Write-Host $WriteString
    }
    else
    {
        &$HostFunctionCaller $WriteString    
    }
}

$passedVerboseFunctionCaller = $false
$passedHostFunctionCaller = $false
if($VerboseFunctionCaller -ne $null){$passedVerboseFunctionCaller = $true}
if($HostFunctionCaller -ne $null){$passedHostFunctionCaller = $true}

Function Start-Jobs {
    Write-VerboseWriter("Calling Start-Jobs")
    foreach($serverObject in $ServersWithArguments)
    {
        $server = $serverObject.ServerName
        $argumentList = $serverObject.ArgumentList
        Write-VerboseWriter("Starting job on server {0}" -f $server)
        Invoke-Command -ComputerName $server -ScriptBlock $ScriptBlock -ArgumentList $argumentList -AsJob -JobName $server | Out-Null
    }
}

Function Confirm-JobsPending {
    $jobs = Get-Job
    if($jobs -ne $null)
    {
        return $true 
    }
    return $false
}

Function Wait-JobsCompleted {
    Write-VerboseWriter("Calling Wait-JobsCompleted")
    [System.Diagnostics.Stopwatch]$timer = [System.Diagnostics.Stopwatch]::StartNew()
    while(Confirm-JobsPending)
    {
        $completedJobs = Get-Job | Where-Object {$_.State -ne "Running"}
        if($completedJobs -eq $null)
        {
            Start-Sleep 1 
            continue 
        }

        $returnData = @{}
        foreach($job in $completedJobs)
        {
            $receiveJobNull = $false 
            $jobName = $job.Name 
            Write-VerboseWriter("Job {0} received. State: {1} | HasMoreData: {2}" -f $job.Name, $job.State,$job.HasMoreData)
            if($NeedReturnData -eq $false -and $DisplayReceiveJob -eq $false -and $job.HasMoreData -eq $true)
            {
                Write-VerboseWriter("This job has data and you provided you didn't want to return it or display it.")
            }
            $receiveJob = Receive-Job $job 
            Remove-Job $job
            if($receiveJob -eq $null)
            {
                $receiveJobNull = $True 
                Write-VerboseWriter("Job {0} didn't have any receive job data" -f $jobName)
            }
            if($DisplayReceiveJobInVerboseFunction -and(-not($receiveJobNull)))
            {
                Write-VerboseWriter("[JobName: {0}] : {1}" -f $jobName, $receiveJob)
            }
            elseif($DisplayReceiveJob -and (-not($receiveJobNull)))
            {
                Write-HostWriter $receiveJob
            }
            if($NeedReturnData)
            {
                $returnData.Add($job.Name, $receiveJob)
            }
        }
    }
    $timer.Stop()
    Write-VerboseWriter("Waiting for jobs to complete took {0} seconds" -f $timer.Elapsed.TotalSeconds)
    if($NeedReturnData)
    {
        return $returnData
    }
    return $null 
}

[System.Diagnostics.Stopwatch]$timerMain = [System.Diagnostics.Stopwatch]::StartNew()
Write-VerboseWriter("Calling Start-JobManager")
Write-VerboseWriter("Passed: [bool]DisplayReceiveJob: {0} | [bool]DisplayReceiveJobInVerboseFunction: {1} | [bool]NeedReturnData:{2} | [scriptblock]VerboseFunctionCaller: {3} | [scriptblock]HostFunctionCaller: {4}" -f $DisplayReceiveJob,
$DisplayReceiveJobInVerboseFunction,
$NeedReturnData,
$passedVerboseFunctionCaller,
$passedHostFunctionCaller)

Start-Jobs
$data = Wait-JobsCompleted
$timerMain.Stop()
Write-VerboseWriter("Exiting: Start-JobManager | Time in Start-JobManager: {0} seconds" -f $timerMain.Elapsed.TotalSeconds)
if($NeedReturnData)
{
    return $data
}
return $null