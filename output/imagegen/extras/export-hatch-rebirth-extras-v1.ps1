param(
    [Parameter(Mandatory=$true)][string]$AtlasSource,
    [Parameter(Mandatory=$true)][string]$RaysSource,
    [Parameter(Mandatory=$true)][string]$LogoSource,
    [switch]$InspectOnly
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Rectangle].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class ExtrasPixelsV1 {
    static byte[] Read(Bitmap b, out int stride) {
        var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
        try {
            if(d.Stride<0) throw new Exception("Unsupported stride");
            stride=d.Stride;
            var p=new byte[stride*b.Height]; Marshal.Copy(d.Scan0,p,0,p.Length); return p;
        } finally { b.UnlockBits(d); }
    }
    public static int[] Columns(Bitmap b) {
        int stride; var p=Read(b,out stride); var v=new int[b.Width];
        for(int y=0;y<b.Height;y++) for(int x=0;x<b.Width;x++) if(p[y*stride+x*4+3]>=8) v[x]++;
        return v;
    }
    public static Rectangle Bounds(Bitmap b,int start,int end) {
        int stride; var p=Read(b,out stride); int lx=end,ty=b.Height,rx=-1,by=-1;
        for(int y=0;y<b.Height;y++) for(int x=start;x<end;x++) if(p[y*stride+x*4+3]>=8) {
            lx=Math.Min(lx,x);rx=Math.Max(rx,x);ty=Math.Min(ty,y);by=Math.Max(by,y);
        }
        if(rx<0) throw new Exception("Empty region");
        lx=Math.Max(start,lx-1);rx=Math.Min(end-1,rx+1);ty=Math.Max(0,ty-1);by=Math.Min(b.Height-1,by+1);
        return new Rectangle(lx,ty,rx-lx+1,by-ty+1);
    }
    public static int[] Stats(Bitmap b) {
        int stride;var p=Read(b,out stride);int peak=0,edge=0,spread=0,n=0;
        for(int y=0;y<b.Height;y++) for(int x=0;x<b.Width;x++) {
            int i=y*stride+x*4,a=p[i+3];peak=Math.Max(peak,a);
            if(x==0||y==0||x==b.Width-1||y==b.Height-1) edge=Math.Max(edge,a);
            if(a>0) {n++;int lo=Math.Min(p[i],Math.Min(p[i+1],p[i+2]));int hi=Math.Max(p[i],Math.Max(p[i+1],p[i+2]));spread=Math.Max(spread,hi-lo);}
        }
        return new int[]{peak,edge,spread,n};
    }
    public static void WhiteRaysExport(Bitmap b) {
        var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
        try {
            var p=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,p,0,p.Length);
            for(int y=0;y<b.Height;y++) for(int x=0;x<b.Width;x++) {
                int i=y*d.Stride+x*4;
                double luma=.2126*p[i+2]+.7152*p[i+1]+.0722*p[i];
                int a=(int)Math.Round(p[i+3]*(luma/255.0)*.8);
                a=Math.Min(a,204);if(a<4) a=0;
                p[i]=p[i+1]=p[i+2]=(byte)(a==0?0:255);p[i+3]=(byte)a;
            }
            Marshal.Copy(p,0,d.Scan0,p.Length);
        } finally {b.UnlockBits(d);}
    }
}
'@
$extrasFolder=$PSScriptRoot
$names=@('hatch','instant-hatch','hatch-timer','hatch-ready')
$targets=@('hatch-icons-v1-original.png','hatch-icons-v1.png','sunburst-rays-v1-original.png','sunburst-rays-v1.png','reborn-logo-v1-original.png','reborn-logo-v1.png')
foreach($name in $names){$targets+=($name+'-v1-512.png');$targets+=($name+'-v1-32.png');$targets+=($name+'-v1-24.png')}
if(-not $InspectOnly){foreach($name in $targets){if(Test-Path -LiteralPath (Join-Path $extrasFolder $name)){throw ('Refusing to overwrite: '+$name)}}}
function Graphics-For($bitmap) {
    $g=[System.Drawing.Graphics]::FromImage($bitmap)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return $g
}
function Rect-Data($r){return @{x=$r.X;y=$r.Y;width=$r.Width;height=$r.Height}}
function Metrics($b) {
    $s=[ExtrasPixelsV1]::Stats($b)
    return @{width=$b.Width;height=$b.Height;peakAlpha=$s[0];edgeAlphaMax=$s[1];activeRGBSpreadMax=$s[2];nontransparentPixels=$s[3];corners=@($b.GetPixel(0,0).A,$b.GetPixel($b.Width-1,0).A,$b.GetPixel(0,$b.Height-1).A,$b.GetPixel($b.Width-1,$b.Height-1).A)}
}
function Draw-Resampled($source,$dest,$rect,$crop) {
    $g=Graphics-For $dest;$wrap=[System.Drawing.Imaging.ImageAttributes]::new()
    try {
        $wrap.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $g.DrawImage($source,$rect,[single]$crop.X,[single]$crop.Y,[single]$crop.Width,[single]$crop.Height,[System.Drawing.GraphicsUnit]::Pixel,$wrap)
    } finally {$g.Dispose();$wrap.Dispose()}
}
$atlas=[System.Drawing.Bitmap]::new($AtlasSource)
$rays=[System.Drawing.Bitmap]::new($RaysSource)
$logo=[System.Drawing.Bitmap]::new($LogoSource)
$master=[System.Drawing.Bitmap]::new(2048,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
    $sourceMetrics=@{atlas=(Metrics $atlas);rays=(Metrics $rays);logo=(Metrics $logo)}
    $columns=[ExtrasPixelsV1]::Columns($atlas)
    $cuts=@(0)
    for($i=1;$i -lt 4;$i++){
        $expected=[int][math]::Round($i*$atlas.Width/4.0);$options=@()
        for($x=[math]::Max(0,$expected-100);$x -le [math]::Min($atlas.Width-1,$expected+100);$x++){if($columns[$x] -eq 0){$options+=$x}}
        if($options.Count -eq 0){throw ('No measured transparent gutter near cell '+$i)}
        $cuts+=[int]($options | Sort-Object {[math]::Abs($_-$expected)} | Select-Object -First 1)
    }
    $cuts+=$atlas.Width
    $frames=@();$rectangles=@();$mg=Graphics-For $master
    try {
        for($i=0;$i -lt 4;$i++){
            $crop=[ExtrasPixelsV1]::Bounds($atlas,$cuts[$i],$cuts[$i+1])
            $scale=430.0/[math]::Max($crop.Width,$crop.Height)
            $w=[int][math]::Round($crop.Width*$scale);$h=[int][math]::Round($crop.Height*$scale)
            $placement=[System.Drawing.Rectangle]::new([int][math]::Round((512-$w)/2.0),[int][math]::Round((512-$h)/2.0),$w,$h)
            $cell=[System.Drawing.Bitmap]::new(512,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                Draw-Resampled $atlas $cell $placement $crop
                $file=$names[$i]+'-v1-512.png';if(-not $InspectOnly){$cell.Save((Join-Path $extrasFolder $file),[System.Drawing.Imaging.ImageFormat]::Png)}
                $m=Metrics $cell;if($m.edgeAlphaMax -ne 0){throw 'Export icon border is not transparent'}
                $mg.DrawImageUnscaled($cell,$i*512,0)
                $smallMetrics=@{}
                foreach($smallSize in @(32,24)){
                    $small=[System.Drawing.Bitmap]::new($smallSize,$smallSize,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                    try {
                        Draw-Resampled $cell $small ([System.Drawing.Rectangle]::new(0,0,$smallSize,$smallSize)) ([System.Drawing.Rectangle]::new(0,0,512,512))
                        if(-not $InspectOnly){$small.Save((Join-Path $extrasFolder ($names[$i]+'-v1-'+$smallSize+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)}
                        $smallMetrics[$smallSize.ToString()]=(Metrics $small)
                    } finally {$small.Dispose()}
                }
                $rectangles+=@{name=$names[$i];file=$file;x=$i*512;y=0;width=512;height=512}
                $frames+=@{name=$names[$i];nativeRegion=@{x=$cuts[$i];y=0;width=$cuts[$i+1]-$cuts[$i];height=$atlas.Height};nativeCrop=(Rect-Data $crop);uniformScale=$scale;exportContentBounds=(Rect-Data $placement);final=$m;small=$smallMetrics}
            } finally {$cell.Dispose()}
        }
    } finally {$mg.Dispose()}
    if(-not $InspectOnly){$master.Save((Join-Path $extrasFolder 'hatch-icons-v1.png'),[System.Drawing.Imaging.ImageFormat]::Png)}
    $rayFinal=[System.Drawing.Bitmap]::new(1024,1024,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $logoFinal=[System.Drawing.Bitmap]::new(1024,384,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        # Full-source, aspect-preserving placement leaves an exact transparent outer border.
        Draw-Resampled $rays $rayFinal ([System.Drawing.Rectangle]::new(32,32,960,960)) ([System.Drawing.Rectangle]::new(0,0,$rays.Width,$rays.Height))
        # Requested white tintable texels and <=80% opacity, preserving light intensity in alpha.
        [ExtrasPixelsV1]::WhiteRaysExport($rayFinal)
        if(-not $InspectOnly){$rayFinal.Save((Join-Path $extrasFolder 'sunburst-rays-v1.png'),[System.Drawing.Imaging.ImageFormat]::Png)}
        $logoScale=[math]::Min(922.0/$logo.Width,346.0/$logo.Height)
        $lw=[int][math]::Round($logo.Width*$logoScale);$lh=[int][math]::Round($logo.Height*$logoScale)
        $logoPlacement=[System.Drawing.Rectangle]::new([int][math]::Round((1024-$lw)/2.0),[int][math]::Round((384-$lh)/2.0),$lw,$lh)
        Draw-Resampled $logo $logoFinal $logoPlacement ([System.Drawing.Rectangle]::new(0,0,$logo.Width,$logo.Height))
        if(-not $InspectOnly){$logoFinal.Save((Join-Path $extrasFolder 'reborn-logo-v1.png'),[System.Drawing.Imaging.ImageFormat]::Png)}
        $rayMetrics=Metrics $rayFinal;$logoMetrics=Metrics $logoFinal
        if($rayMetrics.edgeAlphaMax -ne 0 -or $logoMetrics.edgeAlphaMax -ne 0 -or $rayMetrics.peakAlpha -gt 204 -or $rayMetrics.activeRGBSpreadMax -ne 0){throw 'Final transparency/tint/opacity check failed'}
        if(-not $InspectOnly){
            Copy-Item -LiteralPath $AtlasSource -Destination (Join-Path $extrasFolder 'hatch-icons-v1-original.png')
            Copy-Item -LiteralPath $RaysSource -Destination (Join-Path $extrasFolder 'sunburst-rays-v1-original.png')
            Copy-Item -LiteralPath $LogoSource -Destination (Join-Path $extrasFolder 'reborn-logo-v1-original.png')
        }
        [pscustomobject]@{source=$sourceMetrics;atlas=(Metrics $master);rectangles=$rectangles;frames=$frames;rays=$rayMetrics;raysPlacement=@{x=32;y=32;width=960;height=960};logo=$logoMetrics;logoPlacement=(Rect-Data $logoPlacement);logoScale=$logoScale} | ConvertTo-Json -Depth 12 -Compress
    } finally {$rayFinal.Dispose();$logoFinal.Dispose()}
} finally {$atlas.Dispose();$rays.Dispose();$logo.Dispose();$master.Dispose()}
