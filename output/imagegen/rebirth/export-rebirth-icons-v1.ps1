param([Parameter(Mandatory=$true)][string]$SourcePath)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$rebirthFolder=$PSScriptRoot
$names=@('rebirth-emblem','mill','cash-reset','title-badge')
$outputs=@('rebirth-icons-v1-original.png','rebirth-icons-v1.png','rebirth-icons-v1-upload-1024.png','rebirth-icons-v1-qa-32.png')
foreach($name in $names){$outputs+=($name+'-v1-512.png');$outputs+=($name+'-v1-32.png')}
foreach($name in $outputs){if(Test-Path -LiteralPath (Join-Path $rebirthFolder $name)){throw ('Refusing to overwrite: '+$name)}}
$source=[System.Drawing.Bitmap]::new($SourcePath)
$master=[System.Drawing.Bitmap]::new(2048,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$upload=[System.Drawing.Bitmap]::new(1024,256,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$qa=[System.Drawing.Bitmap]::new(128,32,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
function New-QualityGraphics($bitmap){
    $g=[System.Drawing.Graphics]::FromImage($bitmap)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return $g
}
function Rect-Data($rect){return @{x=$rect.X;y=$rect.Y;width=$rect.Width;height=$rect.Height}}
function Get-EdgeAlpha($bitmap){
    $max=0
    for($x=0;$x -lt $bitmap.Width;$x++){$max=[math]::Max($max,$bitmap.GetPixel($x,0).A);$max=[math]::Max($max,$bitmap.GetPixel($x,$bitmap.Height-1).A)}
    for($y=0;$y -lt $bitmap.Height;$y++){$max=[math]::Max($max,$bitmap.GetPixel(0,$y).A);$max=[math]::Max($max,$bitmap.GetPixel($bitmap.Width-1,$y).A)}
    return $max
}
try{
    $locked=$source.LockBits([System.Drawing.Rectangle]::new(0,0,$source.Width,$source.Height),[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try{
        if($locked.Stride -lt 0){throw 'Negative stride unsupported.'}
        $bytes=[byte[]]::new($locked.Stride*$source.Height)
        [System.Runtime.InteropServices.Marshal]::Copy($locked.Scan0,$bytes,0,$bytes.Length)
        $stride=$locked.Stride
    }finally{$source.UnlockBits($locked)}
    $columns=[int[]]::new($source.Width)
    for($y=0;$y -lt $source.Height;$y++){
        $off=$y*$stride+3
        for($x=0;$x -lt $source.Width;$x++){if($bytes[$off] -ge 8){$columns[$x]++};$off+=4}
    }
    # Locate real transparent gutters instead of clipping on guessed quarters.
    $cuts=@(0)
    for($i=1;$i -lt 4;$i++){
        $expected=[int][math]::Round($i*$source.Width/4.0)
        $candidates=@()
        for($x=[math]::Max(0,$expected-80);$x -le [math]::Min($source.Width-1,$expected+80);$x++){
            if($columns[$x] -eq 0){$candidates+=$x}
        }
        if($candidates.Count -eq 0){throw ('No transparent gutter at boundary '+$i+'; image edit required.')}
        $cut=$candidates | Sort-Object {[math]::Abs($_-$expected)} | Select-Object -First 1
        $cuts+=[int]$cut
    }
    $cuts+=$source.Width
    $frames=@();$masterRects=@();$uploadRects=@()
    $masterGraphics=New-QualityGraphics $master
    $qaGraphics=New-QualityGraphics $qa
    try{
        for($i=0;$i -lt 4;$i++){
            $minX=$cuts[$i+1];$minY=$source.Height;$maxX=-1;$maxY=-1
            for($y=0;$y -lt $source.Height;$y++){
                $off=$y*$stride+$cuts[$i]*4+3
                for($x=$cuts[$i];$x -lt $cuts[$i+1];$x++){
                    if($bytes[$off] -ge 8){$minX=[math]::Min($minX,$x);$maxX=[math]::Max($maxX,$x);$minY=[math]::Min($minY,$y);$maxY=[math]::Max($maxY,$y)}
                    $off+=4
                }
            }
            if($maxX -lt 0){throw ('Empty icon: '+$names[$i])}
            $minX=[math]::Max($cuts[$i],$minX-1);$maxX=[math]::Min($cuts[$i+1]-1,$maxX+1)
            $minY=[math]::Max(0,$minY-1);$maxY=[math]::Min($source.Height-1,$maxY+1)
            $crop=[System.Drawing.Rectangle]::new($minX,$minY,$maxX-$minX+1,$maxY-$minY+1)
            $scale=360.0/[math]::Max($crop.Width,$crop.Height)
            $w=[int][math]::Round($crop.Width*$scale);$h=[int][math]::Round($crop.Height*$scale)
            $dx=[int][math]::Round((512-$w)/2.0);$dy=[int][math]::Round((512-$h)/2.0)
            $cell=[System.Drawing.Bitmap]::new(512,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $small=[System.Drawing.Bitmap]::new(32,32,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try{
                $g=New-QualityGraphics $cell;$wrap=[System.Drawing.Imaging.ImageAttributes]::new()
                try{
                    $wrap.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
                    $g.DrawImage($source,[System.Drawing.Rectangle]::new($dx,$dy,$w,$h),[single]$crop.X,[single]$crop.Y,[single]$crop.Width,[single]$crop.Height,[System.Drawing.GraphicsUnit]::Pixel,$wrap)
                }finally{$g.Dispose();$wrap.Dispose()}
                $cell.Save((Join-Path $rebirthFolder ($names[$i]+'-v1-512.png')),[System.Drawing.Imaging.ImageFormat]::Png)
                $g=New-QualityGraphics $small
                try{$g.DrawImage($cell,[System.Drawing.Rectangle]::new(0,0,32,32))}finally{$g.Dispose()}
                $small.Save((Join-Path $rebirthFolder ($names[$i]+'-v1-32.png')),[System.Drawing.Imaging.ImageFormat]::Png)
                $masterGraphics.DrawImageUnscaled($cell,$i*512,0)
                $qaGraphics.DrawImageUnscaled($small,$i*32,0)
                $masterRects+=@{name=$names[$i];x=$i*512;y=0;width=512;height=512;file=$names[$i]+'-v1-512.png'}
                $uploadRects+=@{name=$names[$i];x=$i*256;y=0;width=256;height=256}
                $frames+=@{name=$names[$i];nativeRegion=@{x=$cuts[$i];y=0;width=$cuts[$i+1]-$cuts[$i];height=$source.Height};nativeCrop=(Rect-Data $crop);exportContentBounds=@{x=$dx;y=$dy;width=$w;height=$h};uniformScale=$scale;cellExteriorMaxAlpha=(Get-EdgeAlpha $cell);smallExteriorMaxAlpha=(Get-EdgeAlpha $small)}
            }finally{$cell.Dispose();$small.Dispose()}
        }
    }finally{$masterGraphics.Dispose();$qaGraphics.Dispose()}
    $master.Save((Join-Path $rebirthFolder 'rebirth-icons-v1.png'),[System.Drawing.Imaging.ImageFormat]::Png)
    $g=New-QualityGraphics $upload
    try{$g.DrawImage($master,[System.Drawing.Rectangle]::new(0,0,1024,256))}finally{$g.Dispose()}
    $upload.Save((Join-Path $rebirthFolder 'rebirth-icons-v1-upload-1024.png'),[System.Drawing.Imaging.ImageFormat]::Png)
    $qa.Save((Join-Path $rebirthFolder 'rebirth-icons-v1-qa-32.png'),[System.Drawing.Imaging.ImageFormat]::Png)
    Copy-Item -LiteralPath $SourcePath -Destination (Join-Path $rebirthFolder 'rebirth-icons-v1-original.png')
    [pscustomobject]@{
        nativeWidth=$source.Width;nativeHeight=$source.Height
        nativeCornerAlpha=@($source.GetPixel(0,0).A,$source.GetPixel($source.Width-1,0).A,$source.GetPixel(0,$source.Height-1).A,$source.GetPixel($source.Width-1,$source.Height-1).A)
        masterWidth=2048;masterHeight=512;uploadWidth=1024;uploadHeight=256
        masterExteriorMaxAlpha=(Get-EdgeAlpha $master);uploadExteriorMaxAlpha=(Get-EdgeAlpha $upload)
        rectangles=$masterRects;uploadRectangles=$uploadRects;frames=$frames
    } | ConvertTo-Json -Depth 10 -Compress
}finally{$source.Dispose();$master.Dispose();$upload.Dispose();$qa.Dispose()}
