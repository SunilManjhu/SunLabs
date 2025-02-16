function Get-VMachine {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [switch]$Fallback
    )

    $vmFromList = Get-List -Type VM | Where-Object { $_.vmName -eq $Name }

    if ($vmFromList) {
        return (Get-VM -Id $vmFromList.vmId)
    }
    else {
        $vmFromList = Get-List -Type VM -SmartUpdate | Where-Object { $_.vmName -eq $Name }
        if ($vmFromList) {
            return (Get-VM -Id $vmFromList.vmId)
        }
        else {
            # VM may exist, without vmNotes object, try fallback if caller explicitly wants it.
            if ($Fallback.IsPresent) {
                return (Get-VM -Name $Name -ErrorAction SilentlyContinue)
            }

            return [System.Management.Automation.Internal.AutomationNull]::Value
        }
    }
}