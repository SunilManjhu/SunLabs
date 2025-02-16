function Get-VMFromHyperV {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object] $vm
    )

    #$diskSize = (Get-VHD -VMId $vm.ID | Measure-Object -Sum FileSize).Sum
    if (-not $common.InJob) {
        $sizeCache = Get-VMSizeCached -vm $vm
        $diskSizeGB = $sizeCache.diskSize / 1GB
        $memoryStartupGB = $sizeCache.MemoryStartup / 1GB
    }       

    if (-not $memoryStartupGB) {
        $memoryStartupGB = 0
    }

    if (-not $diskSizeGB) {
        $diskSizeGB = 0
    }

    $memoryGB = $vm.MemoryAssigned / 1GB

    if (-not $memoryGB) {
        $memoryGB = 0
    }
    $vmNet = Get-VMNetworkCached -vm $vm

    #VmState is now updated  in Update-VMFromHyperV
    #$vmState = $vm.State.ToString()

    $vmObject = [PSCustomObject]@{
        vmName          = $vm.Name
        vmId            = $vm.Id
        switch          = $vmNet.SwitchName
        memoryGB        = $memoryGB
        memoryStartupGB = $memoryStartupGB
        diskUsedGB      = [math]::Round($diskSizeGB, 2)
    }

    Update-VMFromHyperV -vm $vm -vmObject $vmObject -vmNoteObject $vmNoteObject
    return $vmObject
}