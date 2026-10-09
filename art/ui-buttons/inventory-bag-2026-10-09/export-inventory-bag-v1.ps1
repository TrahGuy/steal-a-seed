param([Parameter(Mandatory=$true)][string]$SourcePath)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Rectangle].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class InventoryPixelsV1 {
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
    $s=[InventoryPixelsV1]::Stats($b)
    return @{width=$b.Width;height=$b.Height;peakAlpha=$s[0];edgeAlphaMax=$s[1];activeRGBSpreadMax=$s[2];nontransparentPixels=$s[3];corners=@($b.GetPixel(0,0).A,$b.GetPixel($b.Width-1,0).A,$b.GetPixel(0,$b.Height-1).A,$b.GetPixel($b.Width-1,$b.Height-1).A)}
}
function Draw-Resampled($source,$dest,$rect,$crop) {
    $g=Graphics-For $dest;$wrap=[System.Drawing.Imaging.ImageAttributes]::new()
    try {
        $wrap.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $g.DrawImage($source,$rect,[single]$crop.X,[single]$crop.Y,[single]$crop.Width,[single]$crop.Height,[System.Drawing.GraphicsUnit]::Pixel,$wrap)
    } finally {$g.Dispose();$wrap.Dispose()}
}

$inventoryFolder=$PSScriptRoot
foreach($name in @('inventory-bag-studded-v1-original.png','inventory-bag-studded-v1-512.png','inventory-bag-studded-v1-32.png')) {
    if(Test-Path -LiteralPath (Join-Path $inventoryFolder $name)){throw ('Refusing to overwrite: '+$name)}
}
$source=[System.Drawing.Bitmap]::new($SourcePath)
$final=[System.Drawing.Bitmap]::new(512,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$small=[System.Drawing.Bitmap]::new(32,32,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
    Draw-Resampled $source $final ([System.Drawing.Rectangle]::new(0,0,512,512)) ([System.Drawing.Rectangle]::new(0,0,$source.Width,$source.Height))
    Draw-Resampled $final $small ([System.Drawing.Rectangle]::new(0,0,32,32)) ([System.Drawing.Rectangle]::new(0,0,512,512))
    $final.Save((Join-Path $inventoryFolder 'inventory-bag-studded-v1-512.png'),[System.Drawing.Imaging.ImageFormat]::Png)
    $small.Save((Join-Path $inventoryFolder 'inventory-bag-studded-v1-32.png'),[System.Drawing.Imaging.ImageFormat]::Png)
    Copy-Item -LiteralPath $SourcePath -Destination (Join-Path $inventoryFolder 'inventory-bag-studded-v1-original.png')
    [pscustomobject]@{original=(Metrics $source);final=(Metrics $final);small=(Metrics $small);crop=$false;padding=$false;pixelRecolour=$false} | ConvertTo-Json -Depth 5 -Compress
} finally {$source.Dispose();$final.Dispose();$small.Dispose()}
