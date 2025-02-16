function Update-VMFromHyperV {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object] $vm,
        [Parameter(Mandatory = $false)]
        [object] $vmObject,
        [Parameter(Mandatory = $false)]
        [object] $vmNoteObject
    )
    if (-not $vmNoteObject) {
        try {
            if ($vm.Notes) {
                $vmNoteObject = $vm.Notes | convertFrom-Json -ErrorAction Stop
                #write-log -verbose $vmNoteObject
            }
        }
        catch {
            Write-Log -LogOnly -Failure "Could not convert Notes Object on $($vm.Name) $vmNoteObject"
        }
    }

    if ($vmNoteObject) {
        if ([String]::isnullorwhitespace($vmNoteObject.role)) {
            # If we dont have a vmName property, this is not one of our VM's
            $vmNoteObject = $null
        }
    }
    if (-not $vmObject) {
        $vmObject = $global:vm_List | Where-Object { $_.vmId -eq $vm.vmID }
    }
    if ($vmNoteObject) {
        $vmState = $vm.State.ToString()
        $adminUser = $vmNoteObject.adminName
        $inProgress = if ($vmNoteObject.inProgress) { $true } else { $false }

        $vmObject | Add-Member -MemberType NoteProperty -Name "adminName" -Value $adminUser -Force
        $vmObject | Add-Member -MemberType NoteProperty -Name "inProgress" -Value $inProgress -Force
        $vmObject | Add-Member -MemberType NoteProperty -Name "state" -Value $vmState -Force
        $vmObject | Add-Member -MemberType NoteProperty -Name "vmBuild" -Value $true -Force

        foreach ($prop in $vmNoteObject.PSObject.Properties) {
            $value = if ($prop.Value -is [string]) { $prop.Value.Trim() } else { $prop.Value }
            switch ($prop.Name) {
                "deployedOS" {
                    $vmObject | Add-Member -MemberType NoteProperty -Name "OperatingSystem" -Value $value -Force
                    $vmObject | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $value -Force
                }
                "sqlInstanceName" {
                    if (-not $vmObject.sqlPort) {
                        if ($vmObject.sqlInstanceName -eq "MSSQLSERVER") {
                            $vmObject | Add-Member -MemberType NoteProperty -Name "sqlPort" -Value 1433 -Force
                        }
                        else {
                            $vmObject | Add-Member -MemberType NoteProperty -Name "sqlPort" -Value 2433 -Force
                        }
                    }
                }
                default {
                    $vmObject | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $value -Force
                }
            }
        }
    }
    else {
        $vmObject | Add-Member -MemberType NoteProperty -Name "vmBuild" -Value $false -Force
    }

    if ($vmObject.Role -eq "DPMP") {
        $vmObject.Role = "SiteSystem"
    }

    #add missing Properties
    if ($vmObject.Role -in "SiteSystem", "CAS", "Primary") {
        if ($null -eq $vmObject.InstallRP) {
            $vmObject | Add-Member -MemberType NoteProperty -Name "InstallRP" -Value $false -Force
        }
        if ($null -eq $vmObject.InstallSUP) {
            $vmObject | Add-Member -MemberType NoteProperty -Name "InstallSUP" -Value $false -Force
        }
        if ($vmObject.Role -eq "SiteSystem") {
            if ($null -eq $vmObject.InstallMP) {
                $vmObject | Add-Member -MemberType NoteProperty -Name "InstallMP" -Value $false -Force
            }
            if ($null -eq $vmObject.InstallDP) {
                $vmObject | Add-Member -MemberType NoteProperty -Name "InstallDP" -Value $false -Force
            }
        }
    }

    if ($vmObject.SqlVersion) {
        foreach ($listVM in $global:vm_List) {
            if ($listVM.RemoteSQLVM -eq $vmObject.VmName) {
                if ($null -eq $vmObject.InstallRP) {
                    $vmObject | Add-Member -MemberType NoteProperty -Name "InstallRP" -Value $false -Force
                }
            }
        }
    }

}