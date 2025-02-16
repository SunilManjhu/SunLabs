
$global:vm_List = $null
function Get-List {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Type")]
        [ValidateSet("VM", "Switch", "Prefix", "UniqueDomain", "UniqueSwitch", "UniquePrefix", "Network", "UniqueNetwork", "ForestTrust")]
        [string] $Type,
        [Parameter(Mandatory = $false, ParameterSetName = "Type")]
        [string] $DomainName,
        [Parameter(Mandatory = $false, ParameterSetName = "Type")]
        [switch] $ResetCache,
        [Parameter(Mandatory = $false, ParameterSetName = "Type")]
        [switch] $SmartUpdate,
        [Parameter(Mandatory = $true, ParameterSetName = "FlushCache")]
        [switch] $FlushCache,
        [Parameter(Mandatory = $false, ParameterSetName = "Type")]
        [object] $DeployConfig
    )

    $doSmartUpdate = $SmartUpdate.IsPresent
    $inMutex = $false
    $return = $null
    #Get-PSCallStack | out-host
    if ($global:DisableSmartUpdate -eq $true) {
        $doSmartUpdate = $false
    }
    else {
        $mutexName = "GetList" + $pid
        $mtx = New-Object System.Threading.Mutex($false, $mutexName)
        #write-log "Attempting to acquire '$mutexName' Mutex" -LogOnly -Verbose
        [void]$mtx.WaitOne()
        $inMutex = $true
        #write-log "acquired '$mutexName' Mutex" -LogOnly -Verbose
    }
    try {

        if ($FlushCache.IsPresent) {
            $global:vm_List = $null
            return
        }

        if ($DeployConfig) {
            try {
                $DepoloyConfigJson = $DeployConfig | ConvertTo-Json -Depth 5
                $DeployConfigClone = $DepoloyConfigJson | ConvertFrom-Json
            }
            catch {
                write-log "Failed to convert DeployConfig: $DeployConfig" -Failure
                write-log "Failed to convert DeployConfig: $DepoloyConfigJson" -Failure
                Write-Log "$($_.ScriptStackTrace)" -LogOnly
            }

        }
        if ($ResetCache.IsPresent) {
            $global:vm_List = $null
        }

        if ($doSmartUpdate) {
            if ($global:vm_List) {
                try {
                    try {
                        $virtualMachines = Get-VM
                    }
                    catch {
                        start-sleep -seconds 3
                        $virtualMachines = Get-VM
                    }
                    foreach ( $oldListVM in $global:vm_List) {
                        if ($DomainName) {
                            if ($oldListVM.domain -ne $DomainName) {
                                continue
                            }
                        }
                        #Remove Missing VM's
                        if (-not ($virtualMachines.vmId -contains $oldListVM.vmID)) {
                            #write-host "removing $($oldListVM.vmID)"
                            $global:vm_List = $global:vm_List | Where-Object { $_.vmID -ne $oldListVM.vmID }
                        }
                    }
                    foreach ($vm in $virtualMachines) {
                        #if its missing, do a full add
                        $vmFromGlobal = $global:vm_List | Where-Object { $_.vmId -eq $vm.vmID }
                        if ($null -eq $vmFromGlobal) {
                            #    if (-not $global:vm_List.vmID -contains $vmID){
                            #write-host "adding missing vm $($vm.vmName)"
                            $vmObject = Get-VMFromHyperV -vm $vm
                            $global:vm_List += $vmObject
                        }
                        else {
                            if ($DomainName) {
                                if ($vmFromGlobal.domain -ne $DomainName) {
                                    continue
                                }
                            }
                            #else, update the existing entry.
                            Update-VMFromHyperV -vm $vm -vmObject $vmFromGlobal
                        }
                    }
                }
                finally {
                }
            }
        }

        if (-not $global:vm_List -and $inMutex) {

            try {
                #This may have been populated while waiting for mutex
                if (-not $global:vm_List) {
                    Write-Log "Obtaining '$Type' list and caching it." -Verbose
                    $return = @()
                    $virtualMachines = Get-VM
                    foreach ($vm in $virtualMachines) {

                        $vmObject = Get-VMFromHyperV -vm $vm

                        $return += $vmObject
                    }

                    $global:vm_List = $return
                }
            }
            finally {

            }

        }
        $return = $global:vm_List

        foreach ($vm in $return) {
            $vm | Add-Member -MemberType NoteProperty -Name "source" -Value "hyperv" -Force
        }
        if ($null -ne $DeployConfigClone) {

            $domain = $DeployConfigClone.vmoptions.domainName
            $network = $DeployConfigClone.vmoptions.network

            $prefix = $DeployConfigClone.vmoptions.prefix
            foreach ($vm in $DeployConfigClone.virtualMachines) {
                $found = $false
                if ($vm.hidden) {
                    continue
                }
                if ($vm.network) {
                    $network = $vm.network
                }
                else {
                    $network = $DeployConfigClone.vmoptions.network
                }
                foreach ($vm2 in $return) {
                    if ($vm2.vmName -eq $vm.vmName) {
                        $vm2.source = "config"
                        $found = $true
                    }
                }
                if ($found) {
                    $return = $return | where-object { $_.vmName -ne $vm.vmName }
                }
                $newVM = $vm
                $newVM | Add-Member -MemberType NoteProperty -Name "network" -Value $network -Force
                $newVM | Add-Member -MemberType NoteProperty -Name "Domain" -Value $domain -Force
                $newVM | Add-Member -MemberType NoteProperty -Name "prefix" -Value $prefix -Force
                $newVM | Add-Member -MemberType NoteProperty -Name "source" -Value "config" -Force
                $return += $newVM
            }
        }
        if ($DomainName) {
            $return = $return | Where-Object { $_.domain -and ($_.domain.ToLowerInvariant() -eq $DomainName.ToLowerInvariant()) }
        }

        $return = $return | Sort-Object -Property * #-Unique

        if ($Type -eq "VM") {
            return $return
        }

        # Include Internet subnets, filtering them out as-needed in Common.Remove
        if ($Type -eq "Switch") {
            return $return | where-object { -not [String]::IsNullOrWhiteSpace($_.Domain) } | Select-Object -Property 'Switch', Domain | Sort-Object -Property * -Unique
        }
        if ($Type -eq "Network") {
            return $return | where-object { -not [String]::IsNullOrWhiteSpace($_.Domain) } | Select-Object -Property Network, Domain | Sort-Object -Property * -Unique
        }
        if ($Type -eq "Prefix") {
            return $return | where-object { -not [String]::IsNullOrWhiteSpace($_.Domain) } | Select-Object -Property Prefix, Domain | Sort-Object -Property * -Unique
        }
        if ($Type -eq "UniqueDomain") {
            return $return | where-object { -not [String]::IsNullOrWhiteSpace($_.Domain) } | Select-Object -ExpandProperty Domain -Unique -ErrorAction SilentlyContinue
        }
        if ($Type -eq "ForestTrust") {

            return $return | where-object { -not [String]::IsNullOrWhiteSpace($_.Domain) } | Where-Object { $_.ForestTrust -ne "NONE" -and $_.ForestTrust } | Select-Object -Property @("ForestTrust", "Domain") -Unique -ErrorAction SilentlyContinue
        }
        if ($Type -eq "UniqueSwitch") {
            return $return | where-object { -not [String]::IsNullOrWhiteSpace($_.Domain) } | Select-Object -ExpandProperty 'Switch' -Unique -ErrorAction SilentlyContinue
        }
        if ($Type -eq "UniqueNetwork") {
            return $return | where-object { -not [String]::IsNullOrWhiteSpace($_.Domain) } | Select-Object -ExpandProperty Network -Unique -ErrorAction SilentlyContinue
        }
        if ($Type -eq "UniquePrefix") {
            return $return | where-object { -not [String]::IsNullOrWhiteSpace($_.Domain) } | Select-Object -ExpandProperty Prefix -Unique -ErrorAction SilentlyContinue
        }

    }
    catch {
        write-Log "Failed to get '$Type' list. $_" -Failure -LogOnly
        write-Log "Trace $($_.ScriptStackTrace)" -Failure -LogOnly
        return $null
    }
    finally {
        if ($mtx) {
            [void]$mtx.ReleaseMutex()
            [void]$mtx.Dispose()
            $mtx = $null
        }
    }
}
