function Set-BackgroundImage {

    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the path to the image file")]
        [string] $file,        
        [Parameter(Mandatory = $true, HelpMessage = "Enter the alignment of the image")]
        [ValidateSet("center", "left", "right", "top", "bottom", "topLeft", "topRight", "bottomLeft", "bottomRight")]
        [string] $alignment,
        [Parameter(Mandatory = $true, HelpMessage = "Enter the opacity of the image as a percentage (5-100)")]
        [int] $opacityPercent,
        [Parameter(Mandatory = $true, HelpMessage = "Enter the stretch mode of the image")]
        [ValidateSet("none", "fill", "uniform", "uniformToFill")]
        [string] $stretchMode,
        [bool] $InJob = $false
    )
    
    if ($InJob) {
        return
    }
    if (-not (Test-Path $file)) {
        return 
    }
    
    
    $LocalAppData = $env:LOCALAPPDATA
    $SettingsJson = (Join-Path $LocalAppData "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json")
    Write-Host "Path : $($SettingsJson)"
    if (-not (Test-Path $SettingsJson)) {
        return 
    }

    if ($opacityPercent -lt 5) {
        $opacityPercent = 5        
    }

    if ($opacityPercent -gt 100) {
        $opacityPercent = 100
    }

    

    $a = Get-Content $SettingsJson | ConvertFrom-Json   
    $a | Add-Member -MemberType NoteProperty -Name "tabWidthMode" -Value "titleLength" -Force
    
    if (-not $a.profiles.defaults) {
        $defaults = [PSCustomObject]@{
            backgroundImage            = $file
            backgroundImageAlignment   = $alignment
            backgroundImageOpacity     = ($opacityPercent / 100)
            backgroundImageStretchMode = $stretchMode
            antialiasingMode           = "cleartype"
        }
        $a.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value $defaults -Force
    }
    else {
        $a.profiles.defaults | Add-Member -MemberType NoteProperty -Name "backgroundImage" -Value $file -Force
        $a.profiles.defaults | Add-Member -MemberType NoteProperty -Name "backgroundImageAlignment" -Value $alignment -Force
        $a.profiles.defaults | Add-Member -MemberType NoteProperty -Name "backgroundImageOpacity" -Value ($opacityPercent / 100) -Force
        $a.profiles.defaults | Add-Member -MemberType NoteProperty -Name "backgroundImageStretchMode" -Value $stretchMode -Force
        $a.profiles.defaults | Add-Member -MemberType NoteProperty -Name "antialiasingMode" -Value "cleartype" -Force
    
    }
    
    $a | ConvertTo-Json -Depth 100 | Out-File -encoding utf8 $SettingsJson
}

$image = (Join-Path $PSScriptRoot ".\Images\Robot.png")
Set-BackgroundImage $image "right" 5 "uniform"


