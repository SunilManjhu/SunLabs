function Invoke-SnapshotDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Domain To SnapShot")]
        [string] $domain,
        [Parameter(Mandatory = $false, HelpMessage = "Comment")]
        [string] $comment = "",
        [Parameter(Mandatory = $false, HelpMessage = "Quiet Mode")]
        [bool] $quiet = $false
    )



    $vms = Get-List -type vm -DomainName $domain

    $date = Get-Date -Format "yyyy-MM-dd hh.mmtt"
    $snapshot = $date + " (MemLabs) " + $comment

    $failures = 0
    if (-not $quiet) {
        Write-Log "Snapshotting Virtual Machines in '$domain'" -Activity
        Write-Log "Domain $domain has $(($vms | Measure-Object).Count) resources"
    }
    foreach ($vm in $vms) {
        $complete = $false
        $tries = 0
        While ($complete -ne $true) {
            try {
                if ($tries -gt 10) {
                    $failures++
                    return $failures
                }
                if (-not $quiet) {
                    Show-StatusEraseLine "Checkpointing $($vm.VmName) to [$($snapshot)]" -indent
                }

                Checkpoint-VM -Name $vm.VmName -SnapshotName $snapshot -ErrorAction Stop
                $complete = $true
                if (-not $quiet) {
                    Write-GreenCheck "Checkpoint $($vm.VmName) to [$($snapshot)] Complete"
                }
            }
            catch {
                # Write-RedX "Checkpoint $($vm.VmName) to [$($snapshot)] Failed. Retrying. See Logs for error."
                # write-log "Error: $_" -LogOnly
                # $tries++
                # stop-vm2 -name $vm.VmName
                # Start-Sleep 10
                Write-Host $_.Exception
            }
        }
    }
    return $failures
}