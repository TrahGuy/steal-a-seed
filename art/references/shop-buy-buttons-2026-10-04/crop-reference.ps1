$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sourcePath = 'C:\Users\Maykel\AppData\Local\Temp\codex-clipboard-39d440de-e1a3-44f1-8509-6af9c05353aa.png'
$outputFolder = $PSScriptRoot
$sourceCopy = Join-Path $outputFolder 'source-exclusive-shop.png'
$rectangles = @(
    @{ Name = 'reference-buy-1099.png'; X = 225; Y = 171; W = 153; H = 78 },
    @{ Name = 'reference-buy-379.png'; X = 384; Y = 181; W = 151; H = 68 },
    @{ Name = 'reference-buy-149.png'; X = 542; Y = 181; W = 151; H = 68 },
    @{ Name = 'reference-robux-badge.png'; X = 576; Y = 194; W = 33; H = 33 }
)
foreach ($item in $rectangles) {
    if (Test-Path -LiteralPath (Join-Path $outputFolder $item.Name)) {
        throw ('Existing crop preserved: ' + $item.Name)
    }
}
if (Test-Path -LiteralPath $sourceCopy) { throw 'Existing source copy preserved.' }
Copy-Item -LiteralPath $sourcePath -Destination $sourceCopy
$bitmap = [System.Drawing.Bitmap]::new($sourcePath)
try {
    foreach ($item in $rectangles) {
        if ($item.X -lt 0 -or $item.Y -lt 0 -or ($item.X + $item.W) -gt $bitmap.Width -or ($item.Y + $item.H) -gt $bitmap.Height) {
            throw ('Crop outside screenshot: ' + $item.Name)
        }
        $rectangle = [System.Drawing.Rectangle]::new($item.X, $item.Y, $item.W, $item.H)
        $crop = $bitmap.Clone($rectangle, $bitmap.PixelFormat)
        try {
            $crop.Save((Join-Path $outputFolder $item.Name), [System.Drawing.Imaging.ImageFormat]::Png)
        } finally { $crop.Dispose() }
        Write-Output ($item.Name + ' ' + $item.W + 'x' + $item.H)
    }
} finally { $bitmap.Dispose() }
