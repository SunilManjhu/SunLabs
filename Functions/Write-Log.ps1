function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Text,
        [Parameter(Mandatory = $false)]
        [switch]$Warning,
        [Parameter(Mandatory = $false)]
        [switch]$Failure,
        [Parameter(Mandatory = $false)]
        [switch]$Success,
        [Parameter(Mandatory = $false)]
        [switch]$Activity,
        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,
        [Parameter(Mandatory = $false)]
        [switch]$Highlight,
        [Parameter(Mandatory = $false)]
        [switch]$SubActivity,
        [Parameter(Mandatory = $false)]
        [switch]$LogOnly,
        [Parameter(Mandatory = $false)]
        [switch]$OutputStream,
        [Parameter(Mandatory = $false)]
        [switch]$HostOnly,
        [Parameter(Mandatory = $false)]
        [switch]$NoIndent,
        [Parameter(Mandatory = $false)]
        [switch]$ShowNotification
    )

    $HashArguments = @{}

    $info = $true
    $logLevel = 1    # 0 = Verbose, 1 = Info, 2 = Warning, 3 = Error

    # Get caller function name and add it to Text
    try {
        $caller = (Get-PSCallStack | Select-Object Command, Location, Arguments)[1].Command
        if ($caller -and $caller -like "*.ps1") { $caller = $caller -replace ".ps1", "" }
        if (-not $caller) { $caller = "<Script>" }
    }
    catch {
        $caller = "<Script>"
    }

    if ($caller -eq "<ScriptBlock>") {
        if ($global:ScriptBlockName) {
            $caller = $global:ScriptBlockName
        }
    }

    if ($Text -is [string]) { $Text = $Text.ToString().Trim() }
    # $Text = "[$caller] $Text"

    if ($ShowNotification.IsPresent) {
        Show-Notification -ToastText $Text
    }

    # Is Verbose?
    $IsVerbose = $false
    if ($MyInvocation.BoundParameters["Verbose"].IsPresent) {
        $IsVerbose = $true
    }

    If ($Success.IsPresent) {
        $info = $false
        $TextOutput = "  SUCCESS: $Text"
        # $Text = "SUCCESS: $Text"
        $HashArguments.Add("ForegroundColor", "Chartreuse")
    }

    If ($Activity.IsPresent) {
        $info = $false
        Set-TitleBar $Text
        Write-Host
        if ($NoNewLine.IsPresent) {
            $Text = "=== $Text"
        }
        else {
            $Text = "=== $Text`r`n"
        }

        $HashArguments.Add("ForegroundColor", "DeepSkyBlue")
    }

    If ($SubActivity.IsPresent -and -not $Activity.IsPresent) {
        $info = $false
        $Text = "  === $Text"
        $HashArguments.Add("ForegroundColor", "LightSkyBlue")
    }

    If ($Warning.IsPresent) {
        $info = $false
        $logLevel = 2
        $TextOutput = "  WARNING: $Text"
        # $Text = "WARNING: $Text"
        $HashArguments.Add("ForegroundColor", "Yellow")

    }

    If ($Failure.IsPresent) {
        $info = $false
        $logLevel = 3
        $TextOutput = "  ERROR: $Text"
        # $Text = "ERROR: $Text"
        $HashArguments.Add("ForegroundColor", "Red")

    }

    If ($IsVerbose) {
        $info = $false
        $logLevel = 0
        $TextOutput = "  VERBOSE: $Text"
        # $Text = "VERBOSE: $Text"
    }

    If ($Highlight.IsPresent) {
        $info = $false
        Write-Host
        $Text = "  +++ $Text"
        $HashArguments.Add("ForegroundColor", "DeepSkyBlue")
    }

    if ($info) {
        $HashArguments.Add("ForegroundColor", "White")
        $TextOutput = "  $Text"
        #$Text = "INFO: $Text"
    }

    # Write to output stream
    if ($OutputStream.IsPresent) {
        $Output = [PSCustomObject]@{
            Text     = $text
            Loglevel = $logLevel
        }
        if ($HashArguments) {
            foreach ($arg in $HashArguments.Keys) {
                $Output | Add-Member -MemberType NoteProperty -Name $arg -Value $HashArguments[$arg] -Force
            }
        }

        Write-Output $Output
    }

    # Write progress if output stream and failure present
    if ($OutputStream.IsPresent -and $Failure.IsPresent) {
        Write-Error $Text
        Write-Progress -Activity $Text -Status "Failed :-(" -Completed
    }

    # Write to console, if not logOnly and not OutputStream
    $writeHost = $false
    If (-not $LogOnly.IsPresent -and -not $OutputStream.IsPresent -and -not $IsVerbose) {
        $writeHost = $true
    }

    # Always log verbose to host, if VerboseEnabled
    if ($IsVerbose -and $Common.VerboseEnabled) {
        $writeHost = $true
    }

    # Suppress write-host when in-job
    if ($InJob.IsPresent) {
        $writeHost = $false
    }

    if ($writeHost) {
        if ($TextOutput) {
            if ($NoIndent.IsPresent) {
                $TextOutput = $TextOutput.Trim()
            }
            Write-Host2 $TextOutput @HashArguments
        }
        else {
            Write-Host2 $Text @HashArguments
        }
    }

    # Write to log, non verbose entries
    $write = $false
    if (-not $HostOnly.IsPresent -and -not $IsVerbose) {
        $write = $true
    }

    # Write verbose entries, if verbose logging enabled
    if ($IsVerbose -and $Common.VerboseEnabled) {
        $write = $true
    }

    if ($write) {
        $Text = $Text.ToString().Trim()
        try {
            $CallingFunction = Get-PSCallStack | Select-Object -first 2 | select-object -last 1
            $context = $CallingFunction.Command
            $file = $CallingFunction.Location
            $tid = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            $date = Get-Date -Format 'MM-dd-yyyy'
            $time = Get-Date -Format 'HH:mm:ss.fff'

            $logText = "<![LOG[$Text]LOG]!><time=""$time"" date=""$date"" component=""$caller"" context=""$context"" type=""$logLevel"" thread=""$tid"" file=""$file"">"
            $logText | Out-File $Common.LogPath -Append -Encoding utf8
        }
        catch {
            try {
                # Retry once and ignore if failed
                $logText | Out-File $Common.LogPath -Append -ErrorAction SilentlyContinue -Encoding utf8
            }
            catch {
                # ignore
            }
        }
    }
}