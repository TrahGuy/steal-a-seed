param(
    [Parameter(Mandatory=$true)][string]$RunnerSource,
    [Parameter(Mandatory=$true)][string]$PropsSource,
    [Parameter(Mandatory=$true)][string]$GroundSource,
    [Parameter(Mandatory=$true)][string]$BackdropSource
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sproutFolder = $PSScriptRoot

# Mechanical exports requested in the art brief: cell crops, uniform resampling,
# common pivots/baselines, preserved source images. Never paint or invent art.
function Get-Pixels([System.Drawing.Bitmap]$bitmap) {
    $rect = [System.Drawing.Rectangle]::new(0,0,$bitmap.Width,$bitmap.Height)
    $locked = $bitmap.LockBits($rect,[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        if ($locked.Stride -lt 0) { throw 'Negative stride is not supported.' }
        $bytes = [byte[]]::new($locked.Stride * $bitmap.Height)
        [System.Runtime.InteropServices.Marshal]::Copy($locked.Scan0,$bytes,0,$bytes.Length)
        return @{ Bytes=$bytes; Stride=$locked.Stride }
    } finally { $bitmap.UnlockBits($locked) }
}
function Get-Bounds($pixels, [System.Drawing.Rectangle]$rect) {
    $minX=$rect.Right; $minY=$rect.Bottom; $maxX=-1; $maxY=-1
    for ($y=$rect.Top; $y -lt $rect.Bottom; $y++) {
        $offset=$y*$pixels.Stride+$rect.Left*4+3
        for ($x=$rect.Left; $x -lt $rect.Right; $x++) {
            if ($pixels.Bytes[$offset] -ge 8) {
                $minX=[math]::Min($minX,$x); $minY=[math]::Min($minY,$y)
                $maxX=[math]::Max($maxX,$x); $maxY=[math]::Max($maxY,$y)
            }
            $offset+=4
        }
    }
    if ($maxX -lt 0) { throw 'Empty sprite cell.' }
    return [System.Drawing.Rectangle]::new($minX,$minY,$maxX-$minX+1,$maxY-$minY+1)
}
function Set-Quality([System.Drawing.Graphics]$graphics) {
    $graphics.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
}
function Draw-Crop($graphics,$bitmap,$dest,$crop) {
    $wrap=[System.Drawing.Imaging.ImageAttributes]::new()
    try {
        $wrap.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $graphics.DrawImage($bitmap,$dest,[single]$crop.X,[single]$crop.Y,[single]$crop.Width,[single]$crop.Height,[System.Drawing.GraphicsUnit]::Pixel,$wrap)
    } finally { $wrap.Dispose() }
}
function Rect-Data($r) { return @{ x=$r.X; y=$r.Y; width=$r.Width; height=$r.Height } }
function Alpha-Stats($bitmap) {
    $pixels=Get-Pixels $bitmap
    $min=255; $max=0
    for($i=3; $i -lt $pixels.Bytes.Length; $i+=4) {
        $min=[math]::Min($min,$pixels.Bytes[$i]); $max=[math]::Max($max,$pixels.Bytes[$i])
    }
    $edge=0
    for($x=0;$x -lt $bitmap.Width;$x++) {
        $edge=[math]::Max($edge,$bitmap.GetPixel($x,0).A)
        $edge=[math]::Max($edge,$bitmap.GetPixel($x,$bitmap.Height-1).A)
    }
    for($y=0;$y -lt $bitmap.Height;$y++) {
        $edge=[math]::Max($edge,$bitmap.GetPixel(0,$y).A)
        $edge=[math]::Max($edge,$bitmap.GetPixel($bitmap.Width-1,$y).A)
    }
    return @{ minAlpha=$min; maxAlpha=$max; exteriorEdgeMaxAlpha=$edge; cornerAlpha=@($bitmap.GetPixel(0,0).A,$bitmap.GetPixel($bitmap.Width-1,0).A,$bitmap.GetPixel(0,$bitmap.Height-1).A,$bitmap.GetPixel($bitmap.Width-1,$bitmap.Height-1).A) }
}
function Seam-Stats($bitmap) {
    $sum=0.0; $max=0; $equal=0
    for($y=0;$y -lt $bitmap.Height;$y++) {
        $left=$bitmap.GetPixel(0,$y); $right=$bitmap.GetPixel($bitmap.Width-1,$y)
        $diff=@([math]::Abs([int]$left.R-[int]$right.R),[math]::Abs([int]$left.G-[int]$right.G),[math]::Abs([int]$left.B-[int]$right.B))
        foreach($v in $diff) { $sum+=$v; $max=[math]::Max($max,$v) }
        if(($diff | Measure-Object -Sum).Sum -eq 0) { $equal++ }
    }
    return @{ exactlyMatching=$equal -eq $bitmap.Height; matchingRows=$equal; totalRows=$bitmap.Height; meanAbsoluteRGBDifference=[math]::Round($sum/($bitmap.Height*3),3); maxChannelDifference=$max }
}

$runnerNames=@('run-1','run-2','run-3','run-4','hop','hit','ready','cheer')
$propNames=@('boulder','thorn-weed','fallen-log','broken-pot','heart-full','heart-empty','dust','impact')
$stems=@('sprout-dash-runner-v1','sprout-dash-props-v1','sprout-dash-ground-v1','sprout-dash-backdrop-v1')
$expected=@()
foreach($stem in $stems) { $expected+=Join-Path $sproutFolder ($stem+'.png'); $expected+=Join-Path $sproutFolder ($stem+'-original.png') }
foreach($name in $runnerNames) { $expected+=Join-Path $sproutFolder ('runner-'+$name+'-v1.png') }
foreach($name in $propNames) { $expected+=Join-Path $sproutFolder ('prop-'+$name+'-v1.png') }
$expected+=Join-Path $sproutFolder 'sprout-dash-tile-seams-v1.png'
foreach($path in $expected) { if(Test-Path -LiteralPath $path) { throw ('Refusing to overwrite: '+$path) } }

$metadata=@{}
$nativeSources=@($RunnerSource,$PropsSource,$GroundSource,$BackdropSource)
for($kind=0;$kind -lt 2;$kind++) {
    $stem=$stems[$kind]; $names=if($kind -eq 0) { $runnerNames } else { $propNames }
    $original=Join-Path $sproutFolder ($stem+'-original.png')
    $bitmap=[System.Drawing.Bitmap]::new($nativeSources[$kind])
    $prefix=if($kind -eq 0){'runner-'}else{'prop-'}
    $sheet=[System.Drawing.Bitmap]::new(1024,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $pixels=Get-Pixels $bitmap
        $nativeCells=@(); $bounds=@()
        for($i=0;$i -lt 8;$i++) {
            $col=$i%4; $row=[int][math]::Floor($i/4)
            $x0=[int][math]::Floor($col*$bitmap.Width/4); $x1=[int][math]::Floor(($col+1)*$bitmap.Width/4)
            $y0=[int][math]::Floor($row*$bitmap.Height/2); $y1=[int][math]::Floor(($row+1)*$bitmap.Height/2)
            $cell=[System.Drawing.Rectangle]::new($x0,$y0,$x1-$x0,$y1-$y0)
            $nativeCells+=$cell; $bounds+=Get-Bounds $pixels $cell
        }
        $commonScale=150.0/$bounds[6].Height
        $rectangles=@(); $frames=@()
        $graphics=[System.Drawing.Graphics]::FromImage($sheet)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent); Set-Quality $graphics
            for($i=0;$i -lt 8;$i++) {
                $b=$bounds[$i]; $col=$i%4; $row=[int][math]::Floor($i/4)
                $scale=$commonScale; $base=224
                $anchor=($b.Left+$b.Right)/2.0
                if($kind -eq 0) {
                    # A horizontal slice halfway down the visible sprite tracks
                    # the torso rather than the leaf/arm/foot extremes.
                    $slice=[int][math]::Floor($b.Top+$b.Height/2)
                    $sliceLeft=$b.Right; $sliceRight=$b.Left
                    for($x=$b.Left;$x -lt $b.Right;$x++) {
                        if($pixels.Bytes[$slice*$pixels.Stride+$x*4+3] -ge 8) { $sliceLeft=[math]::Min($sliceLeft,$x); $sliceRight=[math]::Max($sliceRight,$x) }
                    }
                    $anchor=($sliceLeft+$sliceRight+1)/2.0
                    if($i -eq 4) { $base=184 }
                } else {
                    $targetHeight=@(75,85,60,70,80,80,35,80)[$i]
                    $scale=$targetHeight/[double]$b.Height
                    if($i -eq 2) { $scale=[math]::Min($scale,150.0/$b.Width) }
                    if($i -eq 4 -or $i -eq 5 -or $i -eq 7) { $base=128+($b.Height*$scale)/2 }
                }
                $w=[int][math]::Round($b.Width*$scale); $h=[int][math]::Round($b.Height*$scale)
                $dx=[int][math]::Round(128-($anchor-$b.Left)*$scale); $dy=[int][math]::Round($base)-$h
                if($dx -lt 32 -or $dy -lt 32 -or $dx+$w -gt 224 -or $dy+$h -gt 224) { throw ('Sprite exceeds safe cell margins: '+$names[$i]) }
                $dest=[System.Drawing.Rectangle]::new($col*256+$dx,$row*256+$dy,$w,$h)
                Draw-Crop $graphics $bitmap $dest $b
                $rectangles+=@{ name=$names[$i]; x=$col*256; y=$row*256; width=256; height=256; file=$prefix+$names[$i]+'-v1.png' }
                $frames+=@{ name=$names[$i]; nativeCell=(Rect-Data $nativeCells[$i]); nativeAlphaBounds=(Rect-Data $b); exportContentBounds=@{ x=$dx;y=$dy;width=$w;height=$h }; baselineY=[int][math]::Round($base); uniformScale=$scale; torsoAnchorMethod=if($kind -eq 0){'alpha span midpoint at half visible height'}else{'visible bounds midpoint'} }
            }
        } finally { $graphics.Dispose() }
        Copy-Item -LiteralPath $nativeSources[$kind] -Destination $original
        $sheetPath=Join-Path $sproutFolder ($stem+'.png')
        $sheet.Save($sheetPath,[System.Drawing.Imaging.ImageFormat]::Png)
        for($i=0;$i -lt 8;$i++) {
            $rect=[System.Drawing.Rectangle]::new(($i%4)*256,[int][math]::Floor($i/4)*256,256,256)
            $cellImage=$sheet.Clone($rect,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try { $cellImage.Save((Join-Path $sproutFolder $rectangles[$i].file),[System.Drawing.Imaging.ImageFormat]::Png) } finally { $cellImage.Dispose() }
        }
        $metadata[$stem]=@{ source=$stem+'.png';width=1024;height=512;columns=4;rows=2;nativeSource=$stem+'-original.png';nativeWidth=$bitmap.Width;nativeHeight=$bitmap.Height;rectangles=$rectangles;frames=$frames;alpha=(Alpha-Stats $sheet);nativeCornerAlpha=@($bitmap.GetPixel(0,0).A,$bitmap.GetPixel($bitmap.Width-1,0).A,$bitmap.GetPixel(0,$bitmap.Height-1).A,$bitmap.GetPixel($bitmap.Width-1,$bitmap.Height-1).A);notes=@('Final source is the normalized upload atlas, not the preserved native generation.','Coordinates are top-left; right/bottom exclusive. Use final 256x256 cell rectangles.','Native bounds and normalization transforms are recorded separately.','Standing/ground contact baseline is y224 in each export cell; hop y184. No painting or nonuniform stretching.','Visually review animation identity/poses and collision fit before production wiring.') }
    } finally { $bitmap.Dispose();$sheet.Dispose() }
}

for($kind=2;$kind -lt 4;$kind++) {
    $stem=$stems[$kind]; $original=Join-Path $sproutFolder ($stem+'-original.png')
    Copy-Item -LiteralPath $nativeSources[$kind] -Destination $original
    $bitmap=[System.Drawing.Bitmap]::new($original)
    $outHeight=if($kind -eq 2){256}else{512}
    $output=[System.Drawing.Bitmap]::new(1024,$outHeight,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $crop=[System.Drawing.Rectangle]::new(0,0,$bitmap.Width,$bitmap.Height)
        $contact=$null
        if($kind -eq 2) {
            # Find the first almost full-width neutral charcoal row below grass.
            for($y=0;$y -lt $bitmap.Height;$y++) {
                $grey=0; $count=0
                for($x=0;$x -lt $bitmap.Width;$x+=8) {
                    $p=$bitmap.GetPixel($x,$y);$count++
                    if([math]::Abs([int]$p.R-[int]$p.G) -le 8 -and [math]::Abs([int]$p.G-[int]$p.B) -le 8 -and $p.R -lt 150) { $grey++ }
                }
                if($grey/$count -ge 0.9) { $contact=$y;break }
            }
            if($null -eq $contact) { throw 'Could not find belt top; manual review required.' }
            $cropHeight=[int][math]::Round($bitmap.Width/4.0)
            $cropY=[int][math]::Round($contact-$cropHeight*96.0/512)
            $cropY=[math]::Max(0,[math]::Min($cropY,$bitmap.Height-$cropHeight))
            $crop=[System.Drawing.Rectangle]::new(0,$cropY,$bitmap.Width,$cropHeight)
        }
        $graphics=[System.Drawing.Graphics]::FromImage($output)
        try { Set-Quality $graphics; Draw-Crop $graphics $bitmap ([System.Drawing.Rectangle]::new(0,0,1024,$outHeight)) $crop } finally { $graphics.Dispose() }
        $output.Save((Join-Path $sproutFolder ($stem+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)
        $metadata[$stem]=@{source=$stem+'.png';width=1024;height=$outHeight;columns=1;rows=1;nativeSource=$stem+'-original.png';nativeWidth=$bitmap.Width;nativeHeight=$bitmap.Height;nativeCrop=(Rect-Data $crop);rectangles=@(@{name=if($kind -eq 2){'ground'}else{'backdrop'};x=0;y=0;width=1024;height=$outHeight});alpha=(Alpha-Stats $output);horizontalSeam=(Seam-Stats $output);nativeGroundContactY=$contact;exportGroundContactY=if($null -ne $contact){[math]::Round(($contact-$crop.Y)*$outHeight/$crop.Height,3)}else{$null};notes=@('Opaque generated art, uniform resampling only; source preserved.','Ground uses a vertical 4:1 crop with running contact near y48 in the 1024x256 export.','Horizontal seams are measured, not assumed perfect. exactlyMatching=false means strict seamless-edge requirement is not met.','Use as a review draft until motion/tiling fit is approved; no Roblox upload or game wiring.')}
    } finally { $bitmap.Dispose();$output.Dispose() }
}

# Side-by-side repeat evidence, not a new creative asset.
$seams=[System.Drawing.Bitmap]::new(2048,768,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$seamGraphics=[System.Drawing.Graphics]::FromImage($seams)
try {
    for($kind=2;$kind -lt 4;$kind++) {
        $tile=[System.Drawing.Bitmap]::new((Join-Path $sproutFolder ($stems[$kind]+'.png')))
        try {
            $top=if($kind -eq 2){0}else{256}
            $seamGraphics.DrawImageUnscaled($tile,0,$top); $seamGraphics.DrawImageUnscaled($tile,1024,$top)
        } finally { $tile.Dispose() }
    }
    $seams.Save((Join-Path $sproutFolder 'sprout-dash-tile-seams-v1.png'),[System.Drawing.Imaging.ImageFormat]::Png)
} finally { $seamGraphics.Dispose();$seams.Dispose() }
$metadata | ConvertTo-Json -Depth 12 -Compress
