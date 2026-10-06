$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$jobs = @(
    @{
        Source = 'C:\Users\Maykel\AppData\Local\Temp\codex-clipboard-b1dbca3f-288b-4884-be01-ae22b5f4f412.png'
        Copy = 'source-walk-toggle.png'
        Crops = @(@{ Name = 'reference-walk-toggle.png'; X = 8; Y = 33; W = 175; H = 67 })
    },
    @{
        Source = 'C:\Users\Maykel\AppData\Local\Temp\codex-clipboard-2c8a3460-8e70-497e-a572-16679523993d.png'
        Copy = 'source-night-timer.png'
        Crops = @(
            @{ Name = 'reference-night-timer.png'; X = 85; Y = 42; W = 159; H = 68 },
            @{ Name = 'reference-moon-cloud-icon.png'; X = 91; Y = 46; W = 66; H = 55 }
        )
    }
)
foreach ($job in $jobs) {
    $targets = @($job.Copy) + @($job.Crops | ForEach-Object { $_.Name })
    foreach ($target in $targets) {
        if (Test-Path -LiteralPath (Join-Path $PSScriptRoot $target)) { throw ('Existing file preserved: ' + $target) }
    }
    $bitmap = [System.Drawing.Bitmap]::new($job.Source)
    try {
        foreach ($item in $job.Crops) {
            if (($item.X + $item.W) -gt $bitmap.Width -or ($item.Y + $item.H) -gt $bitmap.Height) { throw ('Crop out of bounds: ' + $item.Name) }
        }
        Copy-Item -LiteralPath $job.Source -Destination (Join-Path $PSScriptRoot $job.Copy)
        foreach ($item in $job.Crops) {
            $rectangle = [System.Drawing.Rectangle]::new($item.X,$item.Y,$item.W,$item.H)
            $crop = $bitmap.Clone($rectangle,$bitmap.PixelFormat)
            try { $crop.Save((Join-Path $PSScriptRoot $item.Name),[System.Drawing.Imaging.ImageFormat]::Png) }
            finally { $crop.Dispose() }
            Write-Output ($item.Name + ': ' + $item.W + 'x' + $item.H)
        }
    } finally { $bitmap.Dispose() }
}
