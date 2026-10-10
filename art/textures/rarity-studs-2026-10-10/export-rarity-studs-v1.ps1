$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Rectangle].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class RarityStudPixelsV1 {
 public static int[] Alpha(Bitmap b) {
  var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  try {
   if(d.Stride<0) throw new Exception("Unsupported stride");
   var p=new byte[d.Stride*b.Height]; Marshal.Copy(d.Scan0,p,0,p.Length);
   int lo=255,hi=0,edge=255;
   for(int y=0;y<b.Height;y++) for(int x=0;x<b.Width;x++) {
    int a=p[y*d.Stride+x*4+3]; lo=Math.Min(lo,a);hi=Math.Max(hi,a);
    if(x==0||y==0||x==b.Width-1||y==b.Height-1) edge=Math.Min(edge,a);
   }
   return new int[]{lo,hi,edge};
  } finally { b.UnlockBits(d); }
 }
}
'@
function Save-RgbResize($source,[string]$path,[int]$size) {
 $dest=[System.Drawing.Bitmap]::new($size,$size,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
 $g=[System.Drawing.Graphics]::FromImage($dest)
 $wrap=[System.Drawing.Imaging.ImageAttributes]::new()
 try {
  $g.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
  $g.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $wrap.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
  $g.DrawImage($source,[System.Drawing.Rectangle]::new(0,0,$size,$size),0,0,$source.Width,$source.Height,[System.Drawing.GraphicsUnit]::Pixel,$wrap)
  $dest.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
 } finally {$wrap.Dispose();$g.Dispose();$dest.Dispose()}
}
$raritySources=@(
    @{Name='studs-pearl-white-v1.png'; Source='C:\Users\Maykel\.codex\generated_images\01a041d8-8273-7f31-885d-87e3bd28a713\exec-1871fb2a-9749-44eb-a4da-0003c2b15d6c.png'}
    @{Name='studs-obsidian-silver-v1.png'; Source='C:\Users\Maykel\.codex\generated_images\01a041d8-8273-7f31-885d-87e3bd28a713\exec-d094b5d3-08e9-44e6-b52a-1dcfb1c2bbbf.png'}
    @{Name='studs-midnight-holo-v1.png'; Source='C:\Users\Maykel\.codex\generated_images\01a041d8-8273-7f31-885d-87e3bd28a713\exec-2ae6e917-eb74-4265-85cc-8f9c0067a3b1.png'}
)
foreach($entry in $raritySources) {
 $rarityFinalPath=Join-Path $PSScriptRoot $entry.Name
 $rarityPreviewPath=Join-Path $PSScriptRoot ($entry.Name.Replace('.png','-preview-512.png'))
 foreach($target in @($rarityFinalPath,$rarityPreviewPath)) {
  if(Test-Path -LiteralPath $target) { throw ('Refusing to overwrite: '+$target) }
 }
 $source=[System.Drawing.Bitmap]::new($entry.Source)
 try {
  $alpha=[RarityStudPixelsV1]::Alpha($source)
  if($source.Width -ne $source.Height -or $alpha[0] -ne 255) {throw ('Source must be square and fully opaque: '+$entry.Name)}
  $nativeExact=$source.Width -eq 1254 -and $source.PixelFormat -eq [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
  if($nativeExact) {Copy-Item -LiteralPath $entry.Source -Destination $rarityFinalPath}
  else {Save-RgbResize $source $rarityFinalPath 1254}
  Save-RgbResize $source $rarityPreviewPath 512
  $final=[System.Drawing.Bitmap]::new($rarityFinalPath)
  $preview=[System.Drawing.Bitmap]::new($rarityPreviewPath)
  try {
   $a=[RarityStudPixelsV1]::Alpha($final);$pa=[RarityStudPixelsV1]::Alpha($preview)
   $pngBytes=[System.IO.File]::ReadAllBytes($rarityFinalPath)
   $previewBytes=[System.IO.File]::ReadAllBytes($rarityPreviewPath)
   if($final.Width -ne 1254 -or $final.Height -ne 1254 -or $pngBytes[25] -ne 2 -or $a[0] -ne 255) {throw ('Final format/opacity failed: '+$entry.Name)}
   if($preview.Width -ne 512 -or $preview.Height -ne 512 -or $previewBytes[25] -ne 2 -or $pa[0] -ne 255) {throw ('Preview failed: '+$entry.Name)}
   $sourceHash=(Get-FileHash -LiteralPath $entry.Source -Algorithm SHA256).Hash
   $finalHash=(Get-FileHash -LiteralPath $rarityFinalPath -Algorithm SHA256).Hash
   if($nativeExact -and $sourceHash -ne $finalHash) {throw 'Native copy identity failed'}
   [pscustomobject]@{
    Name=$entry.Name; Width=$final.Width; Height=$final.Height; PngColourType=$pngBytes[25];
    AlphaMin=$a[0];AlphaMax=$a[1];ExteriorAlphaMin=$a[2];PreviewWidth=$preview.Width;PreviewAlphaMin=$pa[0];
    NativeSourceWidth=$source.Width; NativeCopyExact=$nativeExact;SourceHash=$sourceHash;FinalHash=$finalHash;
    Cropped=$false;Recoloured=$false
   } | ConvertTo-Json -Compress
  } finally {$final.Dispose();$preview.Dispose()}
 } finally {$source.Dispose()}
}
