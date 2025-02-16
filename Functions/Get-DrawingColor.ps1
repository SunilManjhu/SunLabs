Function Get-DrawingColor {
    [cmdletbinding()]
    [alias("gdc")]
    [OutputType("PSColorSample")]
    Param(
        [Parameter(Position = 0, HelpMessage = "Specify a color by name. Wildcards are allowed.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )

    Try {
        Add-Type -AssemblyName system.drawing -ErrorAction Stop
    }
    Catch {
        Throw "These functions require the [System.Drawing.Color] .NET Class"
    }

    Write-Verbose "Starting $($MyInvocation.MyCommand)"

    if ($PSBoundParameters.ContainsKey("Name")) {
        if ($Name[0] -match "\*") {
            Write-Verbose "Finding drawing color names that match $name"
            $colors = [system.drawing.color].GetProperties().name | Where-Object { $_ -like $name[0] }
        }
        else {
            $colors = @()
            foreach ($n in $name) {
                if ($n -as [system.drawing.color]) {
                    $colors += $n
                }
                else {
                    Write-Warning "The name $n does not appear to be a valid System.Drawing.Color value. Skipping this name."
                }
                Write-Verbose "Using parameter values: $($colors -join ',')"

            } #foreach name
        } #else
    } #if PSBoundParameters contains Name
    else {
        Write-Verbose "Geting all drawing color names"
        $colors = [system.drawing.color].GetProperties().name | Where-Object { $_ -notmatch "^\bIs|Name|[RGBA]\b" }
    }
    Write-Verbose "Processing $($colors.count) colors"
    if ($colors.count -gt 0) {
        foreach ($c in $colors) {
            Write-Verbose "...$c"
            $ansi = Get-RGB $c -OutVariable rgb | Convert-RGBtoAnsi
            #display an ANSI formatted sample string
            $sample = "$ansi$c$($psstyle.reset)"

            #write a custom object to the pipeline
            [PSCustomObject]@{
                PSTypeName = "PSColorSample"
                Name       = $c
                RGB        = $rgb
                ANSIString = $ansi.replace("`e", "``e")
                ANSI       = $ansi
                Sample     = $sample
            }
        }
    } #if colors.count > 0
    else {
        Write-Warning "No valid colors found."
    }
    Write-Verbose "Ending $($MyInvocation.MyCommand)"
}