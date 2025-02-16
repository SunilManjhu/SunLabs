function Test-CacheValid {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $EntryTime,
        [Parameter(Mandatory = $true)]
        [int] $MaxHours
    )
    $LastUpdateTime = [Datetime]::ParseExact($EntryTime, 'MM/dd/yyyy HH:mm', $null)
    $datediff = New-TimeSpan -Start $LastUpdateTime -End (Get-Date)
    if ($datediff.Hours -lt $MaxHours) {
        return $true
    }
    return $false
}