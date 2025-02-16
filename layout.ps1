Import-Module .\Functions\Get-AllModules.ps1 -Force

$vms = Get-List -Type VM
if ($vms) {

    # $headerStyle = $PSStyle.Foreground.FromRgb(255, 255, 255) +  # White text
    $PSStyle.Foreground.FromRgb(255, 255, 255) +  # White text
    $PSStyle.Background.FromRgb(64, 116, 155)        # Dark blue background
    
    # Define colors for state and role
    $stateColor = @{ "Running" = "Green"; "Off" = "Red" }
    $roleColor = @{ "CAS" = "Yellow"; "Primary" = "Yellow"; "DC" = "White"; "SiteSystem" = "Yellow"; "DomainMember" = "Cyan" }

    # Extract properties and headers
    $properties = @("VmName", "Domain", "State", "Role", "SiteCode", "DeployedOS", "MemoryStartupGB", "DiskUsedGB", "SqlVersion", "LastKnownIP")
    $headers = @("VM Name", "Domain", "State", "Role", "Site Code", "Deployed OS", "Memory (GB)", "Disk Used (GB)", "SQL Version", "Last Known IP")

    # Calculate max width for each column (across ALL VMs for consistency)
    $columnWidths = foreach ($i in 0..($headers.Length - 1)) {
        $headerLength = $headers[$i].Length
        $maxDataLength = ($vms | ForEach-Object { 
                $value = $_.($properties[$i])
                if ($i -in 6, 7) { "$value GB" } else { "$value" } 
            } | Measure-Object -Property Length -Maximum).Maximum
        [Math]::Max($headerLength, $maxDataLength) + 2  # Add padding
    }

    # Group VMs by Domain
    $groups = $vms | Sort-Object -Property Domain, VmName | Group-Object -Property Domain

    # Display tables per domain
    foreach ($group in $groups) {
        $domainVMs = $group.Group

        # Print header for the domain
        for ($i = 0; $i -lt $headers.Length; $i++) {
            $width = $columnWidths[$i]
            Write-Host ("{0,-$width}" -f $headers[$i]) -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
        }
        Write-Host ""

        # Print rows for the domain
        foreach ($vm in $domainVMs) {
            $rowData = @(
                $vm.VmName,
                $vm.Domain,
                $vm.State,
                $vm.Role,
                $vm.SiteCode,
                $vm.DeployedOS,
                "$($vm.MemoryStartupGB) GB",
                "$([Math]::Round($vm.DiskUsedGB, 2)) GB",
                $vm.SqlVersion,
                $vm.LastKnownIP
            )

            for ($i = 0; $i -lt $headers.Length; $i++) {
                $value = $rowData[$i]
                $width = $columnWidths[$i]
                $formatString = "{0,-$width}"

                # Apply color logic
                if ($i -eq 2) {
                    # State column
                    Write-Host ($formatString -f $value) -NoNewline -ForegroundColor $stateColor[$value]
                }
                elseif ($i -eq 3) {
                    # Role column
                    Write-Host ($formatString -f $value) -NoNewline -ForegroundColor $roleColor[$value]
                }
                else {
                    Write-Host ($formatString -f $value) -NoNewline
                }
            }
            Write-Host ""  # Newline
        }

        # Add whitespace between tables
        Write-Host "`n"
    }
}
else {
    Write-Host "No VMs found." -ForegroundColor Red
}