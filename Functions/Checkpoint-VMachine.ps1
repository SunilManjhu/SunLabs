<#
.SYNOPSIS
Creates a checkpoint for a virtual machine and saves its notes to a file.

.DESCRIPTION
This function creates a checkpoint of the specified VM and saves its notes to a file named based on the snapshot name. 
If the checkpoint creation fails, it retries after 20 seconds and checks if the snapshot was created.

.PARAMETER Name
The name of the virtual machine.

.PARAMETER SnapshotName
The name of the snapshot to create.

.EXAMPLE
Checkpoint-VMachine -Name "VM1" -SnapshotName "Snapshot1"
#>

function Checkpoint-VMachine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$SnapshotName
    )

    $vMachine = Get-VMachine -Name $Name

    if ($vMachine) {
        try {
            Checkpoint-VM -VM $vMachine -SnapshotName $SnapshotName -ErrorAction Stop
        }
        catch {
            Start-Sleep -Seconds 20
            $snapshots = Get-VMSnapshot -VM $vMachine
            foreach ($snapshot in $snapshots) {
                if ($snapshot.Name -eq $SnapshotName) {
                    return $null
                }
            }
            throw
        }
    }
    return $null
}
