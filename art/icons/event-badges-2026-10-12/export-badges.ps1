param([switch]$ApprovedExteriorCleanup)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$taskDrawingRefs=@([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Color].Assembly.Location,[System.Object].Assembly.Location)
Add-Type -ReferencedAssemblies $taskDrawingRefs -TypeDefinition @'
using System;
using System.Drawing;
public class BadgePixelStats {
 public int Width, Height, MinX, MinY, MaxX, MaxY, BoundsWidth, BoundsHeight;
 public long AlphaPixels, TransparentPixels, OutsideCircleAlphaPixels, OutsideCircleVisiblePixels;
 public double CenterX, CenterY, FittedRadius, MaximumAlphaRadius;
 public int[] CornerAlpha;
 public int MaximumEdgeAlpha;
 public string PixelFormat;
}
public static class BadgePixels {
 public static BadgePixelStats Scan(Bitmap b, int minAlpha=1) {
  var s=new BadgePixelStats();
  s.Width=b.Width;s.Height=b.Height;s.PixelFormat=b.PixelFormat.ToString();
  s.MinX=b.Width;s.MinY=b.Height;s.MaxX=-1;s.MaxY=-1;
  s.CornerAlpha=new int[]{b.GetPixel(0,0).A,b.GetPixel(b.Width-1,0).A,b.GetPixel(0,b.Height-1).A,b.GetPixel(b.Width-1,b.Height-1).A};
  for(int y=0;y<b.Height;y++) for(int x=0;x<b.Width;x++) {
   int a=b.GetPixel(x,y).A;
   if(x==0||y==0||x==b.Width-1||y==b.Height-1)s.MaximumEdgeAlpha=Math.Max(s.MaximumEdgeAlpha,a);
   if(a<minAlpha){s.TransparentPixels++;continue;}
   s.AlphaPixels++;
   s.MinX=Math.Min(s.MinX,x);s.MinY=Math.Min(s.MinY,y);
   s.MaxX=Math.Max(s.MaxX,x);s.MaxY=Math.Max(s.MaxY,y);
  }
  if(s.AlphaPixels==0)throw new Exception("Empty image");
  s.BoundsWidth=s.MaxX-s.MinX+1;s.BoundsHeight=s.MaxY-s.MinY+1;
  s.CenterX=(s.MinX+s.MaxX)*0.5;s.CenterY=(s.MinY+s.MaxY)*0.5;
  s.FittedRadius=Math.Max(s.BoundsWidth,s.BoundsHeight)*0.5;
  for(int y=s.MinY;y<=s.MaxY;y++) for(int x=s.MinX;x<=s.MaxX;x++) {
   int a=b.GetPixel(x,y).A;if(a<minAlpha)continue;
   double dx=x-s.CenterX,dy=y-s.CenterY,rad=Math.Sqrt(dx*dx+dy*dy);
   s.MaximumAlphaRadius=Math.Max(s.MaximumAlphaRadius,rad);
   if(rad>s.FittedRadius+1.5){s.OutsideCircleAlphaPixels++;if(a>=16)s.OutsideCircleVisiblePixels++;}
  }
  return s;
 }
 public static long ClearOutside(Bitmap b, double cx, double cy, double radius) {
  long cleared=0;double r2=radius*radius;
  for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++) {
   double dx=x-cx,dy=y-cy;
   if(dx*dx+dy*dy>r2 && b.GetPixel(x,y).A>0){b.SetPixel(x,y,Color.FromArgb(0,0,0,0));cleared++;}
  }
  return cleared;
 }
 public static long OutsideCount(Bitmap b, double cx, double cy, double radius) {
  long count=0;double r2=radius*radius;
  for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++) {
   double dx=x-cx,dy=y-cy;if(dx*dx+dy*dy>r2 && b.GetPixel(x,y).A>0)count++;
  }
  return count;
 }
}
'@
$taskDir=$PSScriptRoot
$taskManifest=Get-Content -LiteralPath (Join-Path $taskDir 'generation-manifest.json') -Raw | ConvertFrom-Json
$taskTightDir='D:\KAPE\Steal an Artifact\art\icons\tight'
$taskNativeDir=Join-Path $taskDir 'originals'
foreach($taskFolder in @($taskTightDir,$taskNativeDir)){if(-not(Test-Path -LiteralPath $taskFolder)){[void](New-Item -ItemType Directory -Path $taskFolder)}}
$taskChecks=@()
foreach($taskEntry in $taskManifest.entries){
 $taskMasterPath=Join-Path $taskDir $taskEntry.file
 $taskTightPath=Join-Path $taskTightDir $taskEntry.file
 $taskNativeCopy=Join-Path $taskNativeDir ($taskEntry.key+'-native.png')
 foreach($taskTarget in @($taskMasterPath,$taskTightPath)){if((Test-Path -LiteralPath $taskTarget)-and-not$ApprovedExteriorCleanup){throw ('Refusing to overwrite: '+$taskTarget)}}
 $taskNative=[System.Drawing.Bitmap]::new($taskEntry.native)
 try{
  $taskNativeStats=[BadgePixels]::Scan($taskNative)
  $taskVisibleStats=[BadgePixels]::Scan($taskNative,16)
  if($taskNative.Width-ne$taskNative.Height){throw ('Not square: '+$taskEntry.file)}
  if($taskNativeStats.CornerAlpha|Where-Object{$_-ne0}){throw ('Opaque native corner: '+$taskEntry.file)}
  if($taskNativeStats.TransparentPixels-eq0){throw ('No native alpha: '+$taskEntry.file)}
  if(-not(Test-Path -LiteralPath $taskNativeCopy)){Copy-Item -LiteralPath $taskEntry.native -Destination $taskNativeCopy}
  $taskNativeHash=(Get-FileHash -LiteralPath $taskEntry.native -Algorithm SHA256).Hash
  if($taskNativeHash-ne(Get-FileHash -LiteralPath $taskNativeCopy -Algorithm SHA256).Hash){throw 'Native copy hash mismatch'}
  $taskFramingStats=$taskNativeStats
  $taskSourceSide=[double]([math]::Max($taskNativeStats.BoundsWidth,$taskNativeStats.BoundsHeight)+4)
  if($ApprovedExteriorCleanup){$taskFramingStats=$taskVisibleStats;$taskSourceSide=[double](2*$taskVisibleStats.MaximumAlphaRadius+6)}
  $taskSourceRect=[System.Drawing.RectangleF]::new(
   [single]($taskFramingStats.CenterX+0.5-$taskSourceSide/2),
   [single]($taskFramingStats.CenterY+0.5-$taskSourceSide/2),
   [single]$taskSourceSide,[single]$taskSourceSide)
  $taskVariants=@(
   @{Name='master';Path=$taskMasterPath;ArtSide=471.04},
   @{Name='tight';Path=$taskTightPath;ArtSide=(512.0/1.04)}
  )
  $taskVariantStats=@()
  foreach($taskVariant in $taskVariants){
   $taskOut=[System.Drawing.Bitmap]::new(512,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
   try{
    $taskG=[System.Drawing.Graphics]::FromImage($taskOut)
    try{
     $taskG.Clear([System.Drawing.Color]::Transparent)
     $taskG.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
     $taskG.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
     $taskG.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
     $taskG.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
     $taskMargin=(512-$taskVariant.ArtSide)/2
     $taskDest=[System.Drawing.RectangleF]::new([single]$taskMargin,[single]$taskMargin,[single]$taskVariant.ArtSide,[single]$taskVariant.ArtSide)
     $taskG.DrawImage($taskNative,$taskDest,$taskSourceRect,[System.Drawing.GraphicsUnit]::Pixel)
    }finally{$taskG.Dispose()}
    $taskClearedPixels=0
    $taskCircleRadius=$taskVariant.ArtSide/2
    if($ApprovedExteriorCleanup){$taskClearedPixels=[BadgePixels]::ClearOutside($taskOut,255.5,255.5,$taskCircleRadius)}
    $taskStrictOutside=[BadgePixels]::OutsideCount($taskOut,255.5,255.5,$taskCircleRadius)
    if($ApprovedExteriorCleanup-and$taskStrictOutside-ne0){throw 'Exterior cleanup left nonzero alpha'}
    $taskOut.Save($taskVariant.Path,[System.Drawing.Imaging.ImageFormat]::Png)
   }finally{$taskOut.Dispose()}
   $taskReadBack=[System.Drawing.Bitmap]::new($taskVariant.Path)
   try{
    $taskStats=[BadgePixels]::Scan($taskReadBack)
    if($taskStats.CornerAlpha|Where-Object{$_-ne0}){throw ('Nonzero exported corner: '+$taskVariant.Path)}
    if($taskStats.MaximumEdgeAlpha-ne0){throw ('Nonzero exported edge: '+$taskVariant.Path)}
    $taskVariantStats+=@{Variant=$taskVariant.Name;Path=$taskVariant.Path;Stats=$taskStats;ConfiguredCircleCenter=@(255.5,255.5);ConfiguredCircleRadius=$taskCircleRadius;ClearedExteriorPixels=$taskClearedPixels;StrictAlphaPixelsOutsideConfiguredCircle=$taskStrictOutside}
   }finally{$taskReadBack.Dispose()}
  }
  $taskChecks+=@{Key=$taskEntry.key;Name=$taskEntry.name;File=$taskEntry.file;NativeSource=$taskEntry.native;NativeCopy=$taskNativeCopy;NativeSHA256=$taskNativeHash;NativeStats=$taskNativeStats;NativeVisibleAlpha16Stats=$taskVisibleStats;SquareSourceCrop=@($taskSourceRect.X,$taskSourceRect.Y,$taskSourceRect.Width,$taskSourceRect.Height);Variants=$taskVariantStats}
 }finally{$taskNative.Dispose()}
}
$taskSheetPath=Join-Path $taskDir 'sheet.png'
if((Test-Path -LiteralPath $taskSheetPath)-and-not$ApprovedExteriorCleanup){throw 'Sheet already exists'}
$taskSheet=[System.Drawing.Bitmap]::new(1160,954,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$taskSheetG=[System.Drawing.Graphics]::FromImage($taskSheet)
$taskTitleFont=[System.Drawing.Font]::new('Arial',17,[System.Drawing.FontStyle]::Bold)
$taskLabelFont=[System.Drawing.Font]::new('Arial',10,[System.Drawing.FontStyle]::Bold)
$taskSmallFont=[System.Drawing.Font]::new('Arial',9)
$taskFormat=[System.Drawing.StringFormat]::new()
$taskFormat.Alignment=[System.Drawing.StringAlignment]::Center
$taskFormat.LineAlignment=[System.Drawing.StringAlignment]::Center
$taskColumns=@()
$taskShortNames=@('MIST','RAIN','STORM','DISCO','TICKETS','POD RUSH','LUCK')
for($taskIndex=0;$taskIndex-lt$taskManifest.entries.Count;$taskIndex++){
 $taskColumns+=@{Label=$taskShortNames[$taskIndex];Path=(Join-Path $taskTightDir $taskManifest.entries[$taskIndex].file)}
}
$taskColumns+=@{Label='FLAT RAIN';Path=$taskManifest.flatComparands[0]}
$taskColumns+=@{Label='FLAT DISCO';Path=$taskManifest.flatComparands[1]}
$taskBackdrops=@(
 @{Name='SKY BLUE';Color=[System.Drawing.Color]::FromArgb(100,190,235);Ink=[System.Drawing.Color]::FromArgb(10,28,47)},
 @{Name='FIELD GREEN';Color=[System.Drawing.Color]::FromArgb(88,180,60);Ink=[System.Drawing.Color]::FromArgb(8,36,18)},
 @{Name='NIGHT HUD';Color=[System.Drawing.Color]::FromArgb(17,25,39);Ink=[System.Drawing.Color]::FromArgb(238,245,255)}
)
try{
 $taskSheetG.Clear([System.Drawing.Color]::FromArgb(29,34,42))
 $taskSheetG.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $taskSheetG.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
 $taskSheetG.DrawString('EVENT BADGES - REAL DISPLAY SIZES',$taskTitleFont,[System.Drawing.Brushes]::White,18,12)
 $taskSheetG.DrawString('Tight copies shown at actual 64 / 40 / 30 / 24 pixels. Last two columns: current flat icons.',$taskSmallFont,[System.Drawing.Brushes]::White,20,44)
 for($taskPanel=0;$taskPanel-lt3;$taskPanel++){
  $taskBackdrop=$taskBackdrops[$taskPanel]
  $taskBaseY=72+$taskPanel*284
  $taskBackBrush=[System.Drawing.SolidBrush]::new($taskBackdrop.Color)
  $taskInkBrush=[System.Drawing.SolidBrush]::new($taskBackdrop.Ink)
  try{
   $taskSheetG.FillRectangle($taskBackBrush,0,$taskBaseY,1160,280)
   $taskSheetG.DrawString($taskBackdrop.Name,$taskLabelFont,$taskInkBrush,[System.Drawing.RectangleF]::new(8,$taskBaseY+8,116,30),$taskFormat)
   for($taskCol=0;$taskCol-lt$taskColumns.Count;$taskCol++){
    $taskSheetG.DrawString($taskColumns[$taskCol].Label,$taskSmallFont,$taskInkBrush,[System.Drawing.RectangleF]::new(132+$taskCol*112,$taskBaseY+8,112,30),$taskFormat)
   }
   $taskRows=@(
    @{Size=64;Y=52;Height=78},
    @{Size=40;Y=130;Height=50},
    @{Size=30;Y=180;Height=46},
    @{Size=24;Y=226;Height=40}
   )
   foreach($taskRow in $taskRows){
    $taskRowCenter=$taskBaseY+$taskRow.Y+$taskRow.Height/2
    $taskSheetG.DrawString(($taskRow.Size.ToString()+' px'),$taskLabelFont,$taskInkBrush,[System.Drawing.RectangleF]::new(8,$taskBaseY+$taskRow.Y,116,$taskRow.Height),$taskFormat)
    for($taskCol=0;$taskCol-lt$taskColumns.Count;$taskCol++){
     $taskIcon=[System.Drawing.Bitmap]::new($taskColumns[$taskCol].Path)
     try{
      $taskIconX=[int](132+$taskCol*112+(112-$taskRow.Size)/2)
      $taskIconY=[int]($taskRowCenter-$taskRow.Size/2)
      $taskSheetG.DrawImage($taskIcon,[System.Drawing.Rectangle]::new($taskIconX,$taskIconY,$taskRow.Size,$taskRow.Size))
     }finally{$taskIcon.Dispose()}
    }
   }
  }finally{$taskInkBrush.Dispose();$taskBackBrush.Dispose()}
 }
 $taskSheetG.DrawString('No runtime / Studio test. At 24px, main silhouettes matter; small glints and bevels are secondary.',$taskSmallFont,[System.Drawing.Brushes]::White,18,934)
 $taskSheet.Save($taskSheetPath,[System.Drawing.Imaging.ImageFormat]::Png)
}finally{
 $taskFormat.Dispose();$taskSmallFont.Dispose();$taskLabelFont.Dispose();$taskTitleFont.Dispose();$taskSheetG.Dispose();$taskSheet.Dispose()
}
@{GeneratedOn='2026-10-12';ApprovedExteriorCleanup=$ApprovedExteriorCleanup.IsPresent;Export='proportional bicubic exports; when explicitly approved, frame by alpha>=16 visible disc and clear only exterior pixels outside centred circular boundary';CircleCheck='strict all-alpha count outside configured centred circle, with no tolerance; separate fitted bbox check allows1.5px antialias';MasterCanvas='512x512 RGBA';TightCanvas='512x512 RGBA, about2% padding per side relative to disc';Sheet=@{Path=$taskSheetPath;Width=1160;Height=954;Sizes=@(64,40,30,24);Backgrounds=@('sky blue','field green','night HUD');UsesTightCopies=$true};Badges=$taskChecks} | ConvertTo-Json -Depth 12 -Compress

