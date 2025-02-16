function Get-VMSizeCached {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "VM Object")]
        [object] $vm,
        [Parameter(Mandatory = $false, ParameterSetName = "FlushCache")]
        [switch] $FlushCache
    )

    $jsonFile = $($vm.vmID).toString() + ".disk.json"
    $cacheFile = Join-Path $global:common.CachePath $jsonFile
    Write-Log -hostonly "Cache File $cacheFile" -Verbose
    $vmCacheEntry = $null
    if (Test-Path $cacheFile) {
        try {
            $vmCacheEntry = Get-Content $cacheFile | ConvertFrom-Json
            if ($common.InJob) {
                return $vmCacheEntry
            }
        }
        catch {}
    }


    if ($vmCacheEntry) {
        if (Test-CacheValid -EntryTime $vmCacheEntry.EntryAdded -MaxHours 24) {
            if ($vmCacheEntry.diskSize -and $vmCacheEntry.diskSize -gt 0) {
                return $vmCacheEntry
            }
        }
    }


    #write-host "Making new Entry for $($vm.vmName)"
    # if we didnt return the cache entry, get new data, and add it to cache
    if (-not $Common.InJob) {
        $diskSize = (Get-ChildItem $vm.Path -Recurse | Measure-Object length -sum).sum
        $MemoryStartup = $vm.MemoryStartup
    }
    else {
        $diskSize = 0
        $MemoryStartup = 0
    }
    $MemoryStartup = $vm.MemoryStartup
    $vmCacheEntry = [PSCustomObject]@{
        vmId          = $vm.vmID
        diskSize      = $diskSize
        MemoryStartup = $MemoryStartup
        EntryAdded    = (Get-Date -format "MM/dd/yyyy HH:mm")
    }
    if (-not $Common.InJob) {
        ConvertTo-Json  $vmCacheEntry | Out-File $cacheFile -Force
    }
    return $vmCacheEntry
}