$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sourcePath = 'C:\Users\Maykel\AppData\Local\Temp\codex-clipboard-b15ea569-2175-4c97-ae07-89edea1fe9ea.png'
$sourceCopy = Join-Path $PSScriptRoot 'reference-shop-header-full.png'
$rectangles = @(
    @{ Name = 'reference-header-title-and-icon.png'; X = 25; Y = 39; W = 385; H = 66 },
    @{ Name = 'reference-red-close-button.png'; X = 686; Y = 30; W = 69; H = 74 },
    @{ Name = 'reference-white-stud-strip.png'; X = 419; Y = 66; W = 253; H = 38 }
)
if (Test-Path -LiteralPath $sourceCopy) { throw 'Existing source copy preserved.' }
foreach ($item in $rectangles) {
    if (Test-Path -LiteralPath (Join-Path $PSScriptRoot $item.Name)) {
        throw ('Existing crop preserved: ' + $item.Name)
    }
}
$bitmap = [System.Drawing.Bitmap]::new($sourcePath)
try {
    foreach ($item in $rectangles) {
        if ($item.X -lt 0 -or $item.Y -lt 0 -or ($item.X + $item.W) -gt $bitmap.Width -or ($item.Y + $item.H) -gt $bitmap.Height) {
            throw ('Crop outside screenshot: ' + $item.Name)
        }
    }
    Copy-Item -LiteralPath $sourcePath -Destination $sourceCopy
    Write-Output ('Source: ' + $bitmap.Width + 'x' + $bitmap.Height)
    foreach ($item in $rectangles) {
        $rectangle = [System.Drawing.Rectangle]::new($item.X, $item.Y, $item.W, $item.H)
        $crop = $bitmap.Clone($rectangle, $bitmap.PixelFormat)
        try { $crop.Save((Join-Path $PSScriptRoot $item.Name), [System.Drawing.Imaging.ImageFormat]::Png) }
        finally { $crop.Dispose() }
        Write-Output ($item.Name + ': ' + $item.W + 'x' + $item.H)
    }
} finally { $bitmap.Dispose() }
