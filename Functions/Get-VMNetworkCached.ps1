$global:vmNetCache = $null
function Get-VMNetworkCached {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "VM Object")]
        [object] $vm,
        [Parameter(Mandatory = $false, ParameterSetName = "FlushCache")]
        [switch] $FlushCache
    )
    $jsonFile = $($vm.vmID).toString() + ".network.json"
    $cacheFile = Join-Path $global:common.CachePath $jsonFile

    $vmCacheEntry = $null
    if (Test-Path $cacheFile) {
        try {
            $vmCacheEntry = Get-Content $cacheFile | ConvertFrom-Json
        }
        catch {}
    }


    if ($vmCacheEntry) {
        if (Test-CacheValid -EntryTime $vmCacheEntry.EntryAdded -MaxHours 24) {
            return $vmCacheEntry
        }
    }


    # if we didnt return the cache entry, get new data, and add it to cache
    $vmNet = ($vm | Get-VMNetworkAdapter)
    $vmCacheEntry = [PSCustomObject]@{
        vmId       = $vm.vmID
        SwitchName = $vmNet.SwitchName
        #IPAddresses = $vmNet.IPAddresses
        EntryAdded = (Get-Date -format "MM/dd/yyyy HH:mm")
    }

    if ($vmNet.SwitchName) {
        ConvertTo-Json $vmCacheEntry | Out-File $cacheFile -Force
    }
    return $vmCacheEntry
}