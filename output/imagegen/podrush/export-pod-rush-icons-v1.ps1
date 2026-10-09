param([Parameter(Mandatory=$true)][string]$RushSource,[Parameter(Mandatory=$true)][string]$MedalsSource,[switch]$InspectOnly)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Rectangle].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class PodRushPixelsV1 {
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
    $s=[PodRushPixelsV1]::Stats($b)
    return @{width=$b.Width;height=$b.Height;peakAlpha=$s[0];edgeAlphaMax=$s[1];activeRGBSpreadMax=$s[2];nontransparentPixels=$s[3];corners=@($b.GetPixel(0,0).A,$b.GetPixel($b.Width-1,0).A,$b.GetPixel(0,$b.Height-1).A,$b.GetPixel($b.Width-1,$b.Height-1).A)}
}
function Draw-Resampled($source,$dest,$rect,$crop) {
    $g=Graphics-For $dest;$wrap=[System.Drawing.Imaging.ImageAttributes]::new()
    try {
        $wrap.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $g.DrawImage($source,$rect,[single]$crop.X,[single]$crop.Y,[single]$crop.Width,[single]$crop.Height,[System.Drawing.GraphicsUnit]::Pixel,$wrap)
    } finally {$g.Dispose();$wrap.Dispose()}
}

$podrushFolder=$PSScriptRoot
$names=@('pod-rush-bronze','pod-rush-silver','pod-rush-gold')
$targets=@('pod-rush-v1-original.png','pod-rush-medals-v1-original.png','pod-rush-medals-v1.png')
foreach($stem in @('pod-rush')+$names){foreach($size in @(512,32,24)){$targets+=($stem+'-v1-'+$size+'.png')}}
if(-not $InspectOnly){foreach($name in $targets){if(Test-Path -LiteralPath (Join-Path $podrushFolder $name)){throw ('Refusing to overwrite: '+$name)}}}
function Export-One($source,$regionStart,$regionEnd,$stem) {
    $crop=[PodRushPixelsV1]::Bounds($source,$regionStart,$regionEnd)
    $scale=430.0/[math]::Max($crop.Width,$crop.Height)
    $w=[int][math]::Round($crop.Width*$scale);$h=[int][math]::Round($crop.Height*$scale)
    $placement=[System.Drawing.Rectangle]::new([int][math]::Round((512-$w)/2.0),[int][math]::Round((512-$h)/2.0),$w,$h)
    $cell=[System.Drawing.Bitmap]::new(512,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        Draw-Resampled $source $cell $placement $crop
        $m=Metrics $cell
        if($m.edgeAlphaMax -ne 0){throw ('Non-transparent exterior: '+$stem)}
        if(-not $InspectOnly){$cell.Save((Join-Path $podrushFolder ($stem+'-v1-512.png')),[System.Drawing.Imaging.ImageFormat]::Png)}
        $smallMetrics=@{}
        foreach($size in @(32,24)){
            $small=[System.Drawing.Bitmap]::new($size,$size,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                Draw-Resampled $cell $small ([System.Drawing.Rectangle]::new(0,0,$size,$size)) ([System.Drawing.Rectangle]::new(0,0,512,512))
                if(-not $InspectOnly){$small.Save((Join-Path $podrushFolder ($stem+'-v1-'+$size+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)}
                $smallMetrics[$size.ToString()]=Metrics $small
            } finally {$small.Dispose()}
        }
        return @{name=$stem;nativeRegion=@{x=$regionStart;y=0;width=$regionEnd-$regionStart;height=$source.Height};nativeCrop=(Rect-Data $crop);uniformScale=$scale;exportContentBounds=(Rect-Data $placement);final=$m;small=$smallMetrics;cell=$cell.Clone()}
    } finally {$cell.Dispose()}
}
$rush=[System.Drawing.Bitmap]::new($RushSource)
$medals=[System.Drawing.Bitmap]::new($MedalsSource)
$atlas=[System.Drawing.Bitmap]::new(1536,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
    $sourceMetrics=@{rush=(Metrics $rush);medals=(Metrics $medals)}
    $rushRecord=Export-One $rush 0 $rush.Width 'pod-rush'
    $rushRecord.cell.Dispose();$rushRecord.Remove('cell')
    $columns=[PodRushPixelsV1]::Columns($medals)
    $cuts=@(0)
    for($i=1;$i -lt 3;$i++){
        $expected=[int][math]::Round($i*$medals.Width/3.0);$options=@()
        for($x=[math]::Max(0,$expected-110);$x -le [math]::Min($medals.Width-1,$expected+110);$x++){if($columns[$x] -eq 0){$options+=$x}}
        if($options.Count -eq 0){throw ('No transparent medal gutter near cell '+$i)}
        $cuts+=[int]($options | Sort-Object {[math]::Abs($_-$expected)} | Select-Object -First 1)
    }
    $cuts+=$medals.Width
    $frames=@();$rectangles=@();$g=Graphics-For $atlas
    try {
        for($i=0;$i -lt 3;$i++){
            $record=Export-One $medals $cuts[$i] $cuts[$i+1] $names[$i]
            try {$g.DrawImageUnscaled($record.cell,$i*512,0)} finally {$record.cell.Dispose();$record.Remove('cell')}
            $frames+=$record
            $rectangles+=@{name=$names[$i];file=$names[$i]+'-v1-512.png';x=$i*512;y=0;width=512;height=512}
        }
    } finally {$g.Dispose()}
    if(-not $InspectOnly){
        $atlas.Save((Join-Path $podrushFolder 'pod-rush-medals-v1.png'),[System.Drawing.Imaging.ImageFormat]::Png)
        Copy-Item -LiteralPath $RushSource -Destination (Join-Path $podrushFolder 'pod-rush-v1-original.png')
        Copy-Item -LiteralPath $MedalsSource -Destination (Join-Path $podrushFolder 'pod-rush-medals-v1-original.png')
    }
    [pscustomobject]@{source=$sourceMetrics;rush=$rushRecord;medals=$frames;atlas=(Metrics $atlas);rectangles=$rectangles} | ConvertTo-Json -Depth 12 -Compress
} finally {$rush.Dispose();$medals.Dispose();$atlas.Dispose()}
