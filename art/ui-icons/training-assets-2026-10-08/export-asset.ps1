param(
    [Parameter(Mandatory=$true)][string]$SourcePath,
    [Parameter(Mandatory=$true)][string]$AssetName
)
$ErrorActionPreference = 'Stop'
if ($AssetName -notmatch '^[a-z0-9-]+$') { throw 'AssetName must be a plain lowercase filename stem.' }
$assetFolder = $PSScriptRoot
$finalPath = Join-Path $assetFolder ($AssetName + '-512.png')
$previewPath = Join-Path $assetFolder ($AssetName + '-32.png')
$originalPath = Join-Path $assetFolder ($AssetName + '-original.png')
foreach ($assetPath in @($finalPath,$previewPath,$originalPath)) {
    if (Test-Path -LiteralPath $assetPath) { throw ('Refusing to overwrite: ' + $assetPath) }
}
Add-Type -AssemblyName System.Drawing
$assetBitmap = [System.Drawing.Bitmap]::new($SourcePath)
try {
    $assetRect = [System.Drawing.Rectangle]::new(0,0,$assetBitmap.Width,$assetBitmap.Height)
    $assetLocked = $assetBitmap.LockBits($assetRect,[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        if ($assetLocked.Stride -lt 0) { throw 'Unsupported negative source stride.' }
        $assetBytes = [byte[]]::new($assetLocked.Stride * $assetBitmap.Height)
        [System.Runtime.InteropServices.Marshal]::Copy($assetLocked.Scan0,$assetBytes,0,$assetBytes.Length)
        $assetMinX=$assetBitmap.Width; $assetMinY=$assetBitmap.Height; $assetMaxX=-1; $assetMaxY=-1
        for ($assetY=0; $assetY -lt $assetBitmap.Height; $assetY++) {
            $assetOffset=$assetY*$assetLocked.Stride+3
            for ($assetX=0; $assetX -lt $assetBitmap.Width; $assetX++) {
                if ($assetBytes[$assetOffset] -ge 8) {
                    if ($assetX -lt $assetMinX) { $assetMinX=$assetX }
                    if ($assetX -gt $assetMaxX) { $assetMaxX=$assetX }
                    if ($assetY -lt $assetMinY) { $assetMinY=$assetY }
                    if ($assetY -gt $assetMaxY) { $assetMaxY=$assetY }
                }
                $assetOffset+=4
            }
        }
    } finally { $assetBitmap.UnlockBits($assetLocked) }
    if ($assetMaxX -lt 0) { throw 'Image is empty.' }
    $assetMinX=[math]::Max(0,$assetMinX-1); $assetMinY=[math]::Max(0,$assetMinY-1)
    $assetMaxX=[math]::Min($assetBitmap.Width-1,$assetMaxX+1); $assetMaxY=[math]::Min($assetBitmap.Height-1,$assetMaxY+1)
    $assetCrop=[System.Drawing.Rectangle]::new($assetMinX,$assetMinY,$assetMaxX-$assetMinX+1,$assetMaxY-$assetMinY+1)
    $assetScale=460.0/[math]::Max($assetCrop.Width,$assetCrop.Height)
    $assetWidth=$assetCrop.Width*$assetScale; $assetHeight=$assetCrop.Height*$assetScale
    $assetPlacement=[System.Drawing.Rectangle]::new([int][math]::Round((512-$assetWidth)/2),[int][math]::Round((512-$assetHeight)/2),[int][math]::Round($assetWidth),[int][math]::Round($assetHeight))
    $assetFinal=[System.Drawing.Bitmap]::new(512,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $assetGraphics=[System.Drawing.Graphics]::FromImage($assetFinal)
        $assetWrap=[System.Drawing.Imaging.ImageAttributes]::new()
        try {
            $assetGraphics.Clear([System.Drawing.Color]::Transparent)
            $assetGraphics.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $assetGraphics.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $assetGraphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $assetGraphics.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $assetWrap.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
            $assetGraphics.DrawImage($assetBitmap,$assetPlacement,[single]$assetCrop.X,[single]$assetCrop.Y,[single]$assetCrop.Width,[single]$assetCrop.Height,[System.Drawing.GraphicsUnit]::Pixel,$assetWrap)
        } finally { $assetGraphics.Dispose(); $assetWrap.Dispose() }
        # Drop imperceptible alpha noise so empty PNG regions are exactly zero-alpha.
        $assetFinalLocked=$assetFinal.LockBits([System.Drawing.Rectangle]::new(0,0,512,512),[System.Drawing.Imaging.ImageLockMode]::ReadWrite,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $assetFinalBytes=[byte[]]::new($assetFinalLocked.Stride*512)
            [System.Runtime.InteropServices.Marshal]::Copy($assetFinalLocked.Scan0,$assetFinalBytes,0,$assetFinalBytes.Length)
            for ($assetByte=3; $assetByte -lt $assetFinalBytes.Length; $assetByte+=4) {
                if ($assetFinalBytes[$assetByte] -lt 8) {
                    $assetFinalBytes[$assetByte]=0
                    $assetFinalBytes[$assetByte-1]=0
                    $assetFinalBytes[$assetByte-2]=0
                    $assetFinalBytes[$assetByte-3]=0
                }
            }
            [System.Runtime.InteropServices.Marshal]::Copy($assetFinalBytes,0,$assetFinalLocked.Scan0,$assetFinalBytes.Length)
        } finally { $assetFinal.UnlockBits($assetFinalLocked) }
        $assetFinal.Save($finalPath,[System.Drawing.Imaging.ImageFormat]::Png)
        $assetPreview=[System.Drawing.Bitmap]::new(32,32,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $assetPreviewGraphics=[System.Drawing.Graphics]::FromImage($assetPreview)
            try {
                $assetPreviewGraphics.Clear([System.Drawing.Color]::Transparent)
                $assetPreviewGraphics.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $assetPreviewGraphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $assetPreviewGraphics.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $assetPreviewGraphics.DrawImage($assetFinal,[System.Drawing.Rectangle]::new(0,0,32,32))
            } finally { $assetPreviewGraphics.Dispose() }
            $assetPreview.Save($previewPath,[System.Drawing.Imaging.ImageFormat]::Png)
        } finally { $assetPreview.Dispose() }
        $assetEdgeMax=0
        for ($assetEdge=0; $assetEdge -lt 512; $assetEdge++) {
            $assetEdgeMax=[math]::Max($assetEdgeMax,$assetFinal.GetPixel($assetEdge,0).A)
            $assetEdgeMax=[math]::Max($assetEdgeMax,$assetFinal.GetPixel($assetEdge,511).A)
            $assetEdgeMax=[math]::Max($assetEdgeMax,$assetFinal.GetPixel(0,$assetEdge).A)
            $assetEdgeMax=[math]::Max($assetEdgeMax,$assetFinal.GetPixel(511,$assetEdge).A)
        }
        Copy-Item -LiteralPath $SourcePath -Destination $originalPath
        [pscustomobject]@{
            width=512; height=512; alphaEdgeMax=$assetEdgeMax
            centreAlpha=$assetFinal.GetPixel(256,256).A
            sourceCornerAlpha=@($assetBitmap.GetPixel(0,0).A,$assetBitmap.GetPixel($assetBitmap.Width-1,0).A,$assetBitmap.GetPixel(0,$assetBitmap.Height-1).A,$assetBitmap.GetPixel($assetBitmap.Width-1,$assetBitmap.Height-1).A)
            sourceBounds=@($assetCrop.X,$assetCrop.Y,$assetCrop.Width,$assetCrop.Height)
            fitLongestPixels=460
        } | ConvertTo-Json -Compress
    } finally { $assetFinal.Dispose() }
} finally { $assetBitmap.Dispose() }
