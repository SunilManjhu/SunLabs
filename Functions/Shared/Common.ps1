$global:common = [PSCustomObject]@{
    CachePath             = New-Directory -DirectoryPath (Join-Path $PSScriptRoot "cache")            # Path for Get-List cache files
}
