param([switch]$ResumeOwnedOutputs)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$taskRefs=@([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Color].Assembly.Location,[System.Object].Assembly.Location)
Add-Type -ReferencedAssemblies $taskRefs -TypeDefinition @'
using System;
using System.Drawing;
public class PodBundlePixels {
 public int Width,Height,MinX,MinY,MaxX,MaxY,BoundsWidth,BoundsHeight,MaximumEdgeAlpha;
 public long TransparentPixels,NonzeroAlphaPixels;
 public int[] CornerAlpha;
 public string PixelFormat;
 public static PodBundlePixels Scan(Bitmap b) {
  var s=new PodBundlePixels();s.Width=b.Width;s.Height=b.Height;s.MinX=b.Width;s.MinY=b.Height;s.MaxX=-1;s.MaxY=-1;
  s.PixelFormat=b.PixelFormat.ToString();s.CornerAlpha=new int[]{b.GetPixel(0,0).A,b.GetPixel(b.Width-1,0).A,b.GetPixel(0,b.Height-1).A,b.GetPixel(b.Width-1,b.Height-1).A};
  for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++){
   int a=b.GetPixel(x,y).A;if(a==0)s.TransparentPixels++;else s.NonzeroAlphaPixels++;
   if(x==0||y==0||x==b.Width-1||y==b.Height-1)s.MaximumEdgeAlpha=Math.Max(s.MaximumEdgeAlpha,a);
   if(a<16)continue;s.MinX=Math.Min(s.MinX,x);s.MinY=Math.Min(s.MinY,y);s.MaxX=Math.Max(s.MaxX,x);s.MaxY=Math.Max(s.MaxY,y);
  }
  if(s.MaxX<0)throw new Exception("No visible object");
  s.BoundsWidth=s.MaxX-s.MinX+1;s.BoundsHeight=s.MaxY-s.MinY+1;return s;
 }
}
'@
$taskDir=$PSScriptRoot
$taskManifest=Get-Content -LiteralPath (Join-Path $taskDir 'generation-manifest.json') -Raw | ConvertFrom-Json
$taskTightDir='D:\KAPE\Steal an Artifact\art\icons\tight'
$taskOriginalDir=Join-Path $taskDir 'originals'
foreach($taskFolder in @($taskTightDir,$taskOriginalDir)){if(-not(Test-Path -LiteralPath $taskFolder)){[void](New-Item -ItemType Directory -Path $taskFolder)}}
$taskResults=@()
foreach($taskEntry in $taskManifest.entries){
 $taskMaster=Join-Path $taskDir $taskEntry.file
 $taskTight=Join-Path $taskTightDir $taskEntry.file
 $taskOriginal=Join-Path $taskOriginalDir ($taskEntry.key+'-native.png')
 foreach($taskTarget in @($taskMaster,$taskTight)){if((Test-Path -LiteralPath $taskTarget)-and-not$ResumeOwnedOutputs){throw ('Refusing to overwrite: '+$taskTarget)}}
 $taskImage=[System.Drawing.Bitmap]::new($taskEntry.native)
 try{
  if($taskImage.Width-ne$taskImage.Height){throw 'Not square'}
  $taskNativeStats=[PodBundlePixels]::Scan($taskImage)
  if($taskNativeStats.CornerAlpha|Where-Object{$_-ge16}){throw ('Native corner is visibly opaque: '+$taskEntry.file)}
  if($taskNativeStats.TransparentPixels-eq0){throw 'Native lacks genuine alpha'}
  if(-not(Test-Path -LiteralPath $taskOriginal)){Copy-Item -LiteralPath $taskEntry.native -Destination $taskOriginal}
  $taskNativeHash=(Get-FileHash -LiteralPath $taskEntry.native -Algorithm SHA256).Hash
  if($taskNativeHash-ne(Get-FileHash -LiteralPath $taskOriginal -Algorithm SHA256).Hash){throw 'Original copy mismatch'}
  $taskSourceSide=[double]([math]::Max($taskNativeStats.BoundsWidth,$taskNativeStats.BoundsHeight)+8)
  $taskCx=($taskNativeStats.MinX+$taskNativeStats.MaxX+1)/2.0
  $taskCy=($taskNativeStats.MinY+$taskNativeStats.MaxY+1)/2.0
  $taskSourceRect=[System.Drawing.RectangleF]::new([single]($taskCx-$taskSourceSide/2),[single]($taskCy-$taskSourceSide/2),[single]$taskSourceSide,[single]$taskSourceSide)
  $taskVariants=@(@{Name='master';Path=$taskMaster;ArtSize=409.6},@{Name='tight';Path=$taskTight;ArtSize=(512.0/1.04)})
  $taskVariantResults=@()
  foreach($taskVariant in $taskVariants){
   $taskOut=[System.Drawing.Bitmap]::new(512,512,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
   try{
    $taskG=[System.Drawing.Graphics]::FromImage($taskOut)
    try{
     $taskG.Clear([System.Drawing.Color]::Transparent)
     $taskG.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
     $taskG.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
     $taskG.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
     $taskMargin=(512-$taskVariant.ArtSize)/2.0
     $taskDest=[System.Drawing.RectangleF]::new([single]$taskMargin,[single]$taskMargin,[single]$taskVariant.ArtSize,[single]$taskVariant.ArtSize)
     $taskG.DrawImage($taskImage,$taskDest,$taskSourceRect,[System.Drawing.GraphicsUnit]::Pixel)
    }finally{$taskG.Dispose()}
    $taskOut.Save($taskVariant.Path,[System.Drawing.Imaging.ImageFormat]::Png)
   }finally{$taskOut.Dispose()}
   $taskReadBack=[System.Drawing.Bitmap]::new($taskVariant.Path)
   try{
    $taskStats=[PodBundlePixels]::Scan($taskReadBack)
    if($taskStats.CornerAlpha|Where-Object{$_-ne0}){throw 'Export corner not transparent'}
    if($taskStats.MaximumEdgeAlpha-ne0){throw 'Export touches canvas edge'}
    $taskVariantResults+=@{Variant=$taskVariant.Name;Path=$taskVariant.Path;SHA256=(Get-FileHash -LiteralPath $taskVariant.Path -Algorithm SHA256).Hash;Stats=$taskStats}
   }finally{$taskReadBack.Dispose()}
  }
  $taskResults+=@{Key=$taskEntry.key;File=$taskEntry.file;NativeSource=$taskEntry.native;NativeCopy=$taskOriginal;NativeSHA256=$taskNativeHash;NativeStats=$taskNativeStats;SquareSourceCrop=@($taskSourceRect.X,$taskSourceRect.Y,$taskSourceRect.Width,$taskSourceRect.Height);Variants=$taskVariantResults}
 }finally{$taskImage.Dispose()}
}
$taskColumns=@()
$taskNames=@('POD 1','PODS 3','POD HEAP','POD CHEST','GIFT 1','GIFT 3','GIFT HEAP','GIFT CHEST')
for($taskIndex=0;$taskIndex-lt$taskManifest.entries.Count;$taskIndex++){
 $taskColumns+=@{Name=$taskNames[$taskIndex];Master=(Join-Path $taskDir $taskManifest.entries[$taskIndex].file);Tight=(Join-Path $taskTightDir $taskManifest.entries[$taskIndex].file)}
}
foreach($taskCompare in $taskManifest.comparands){$taskColumns+=@{Name=$taskCompare.name;Master=$taskCompare.path;Tight=$taskCompare.path}}
$taskTitleFont=[System.Drawing.Font]::new('Arial',20,[System.Drawing.FontStyle]::Bold)
$taskLabelFont=[System.Drawing.Font]::new('Arial',14,[System.Drawing.FontStyle]::Bold)
$taskSmallFont=[System.Drawing.Font]::new('Arial',12)
$taskFormat=[System.Drawing.StringFormat]::new()
$taskFormat.Alignment=[System.Drawing.StringAlignment]::Center
$taskFormat.LineAlignment=[System.Drawing.StringAlignment]::Center
$taskBackdrops=@(
 @{Name='LIGHT';Color=[System.Drawing.Color]::FromArgb(243,245,247);Ink=[System.Drawing.Color]::FromArgb(18,27,40)},
 @{Name='SHOP GREEN #4BE015';Color=[System.Drawing.Color]::FromArgb(75,224,21);Ink=[System.Drawing.Color]::FromArgb(10,31,13)}
)
function Draw-PodBundleSheet {
 param([string]$Path,[bool]$Full)
 if(Test-Path -LiteralPath $Path){throw ('Sheet exists: '+$Path)}
 if($Full){$taskWidth=5596;$taskHeight=1848;$taskHeader=72;$taskPanelHeight=876;$taskLabelWidth=132;$taskColWidth=544;$taskRows=@(@{Size=512;Y=80},@{Size=128;Y=638},@{Size=64;Y=786})}
 else{$taskWidth=1568;$taskHeight=532;$taskHeader=72;$taskPanelHeight=218;$taskLabelWidth=104;$taskColWidth=144;$taskRows=@(@{Size=128;Y=48},@{Size=64;Y=184})}
 if(-not$Full){$taskHeight=688;$taskPanelHeight=292}
 $taskCanvas=[System.Drawing.Bitmap]::new($taskWidth,$taskHeight,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
 $taskGraphics=[System.Drawing.Graphics]::FromImage($taskCanvas)
 try{
  $taskGraphics.Clear([System.Drawing.Color]::FromArgb(30,35,43))
  $taskGraphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $taskGraphics.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $taskGraphics.DrawString('MYSTERIOUS POD BUNDLES - SHOP FAMILY CHECK',$taskTitleFont,[System.Drawing.Brushes]::White,18,8)
  $taskCaption=if($Full){'512px masters, then 128/64px tight copies; final two columns are existing SPEED 3 / CASH 4. PNGs themselves have no labels.'}else{'Actual 128px / 64px tight-copy previews. Final two columns are existing Shop icons. No live Studio test.'}
  $taskGraphics.DrawString($taskCaption,$taskSmallFont,[System.Drawing.Brushes]::White,18,42)
  for($taskPanel=0;$taskPanel-lt2;$taskPanel++){
   $taskBaseY=$taskHeader+$taskPanel*$taskPanelHeight
   $taskBackdrop=$taskBackdrops[$taskPanel]
   $taskBrush=[System.Drawing.SolidBrush]::new($taskBackdrop.Color)
   $taskInk=[System.Drawing.SolidBrush]::new($taskBackdrop.Ink)
   try{
    $taskGraphics.FillRectangle($taskBrush,0,$taskBaseY,$taskWidth,$taskPanelHeight-4)
    $taskGraphics.DrawString($taskBackdrop.Name,$taskSmallFont,$taskInk,8,$taskBaseY+6)
    for($taskCol=0;$taskCol-lt$taskColumns.Count;$taskCol++){
     $taskGraphics.DrawString($taskColumns[$taskCol].Name,$taskSmallFont,$taskInk,[System.Drawing.RectangleF]::new($taskLabelWidth+$taskCol*$taskColWidth,$taskBaseY+18,$taskColWidth,28),$taskFormat)
    }
    foreach($taskRow in $taskRows){
     $taskGraphics.DrawString(($taskRow.Size.ToString()+' px'),$taskLabelFont,$taskInk,[System.Drawing.RectangleF]::new(0,$taskBaseY+$taskRow.Y,$taskLabelWidth,$taskRow.Size),$taskFormat)
     for($taskCol=0;$taskCol-lt$taskColumns.Count;$taskCol++){
      $taskIconPath=if($Full-and$taskRow.Size-eq512){$taskColumns[$taskCol].Master}else{$taskColumns[$taskCol].Tight}
      $taskIcon=[System.Drawing.Bitmap]::new($taskIconPath)
      try{
       $taskIconX=[int]($taskLabelWidth+$taskCol*$taskColWidth+($taskColWidth-$taskRow.Size)/2)
       $taskIconY=[int]($taskBaseY+$taskRow.Y)
       $taskGraphics.DrawImage($taskIcon,[System.Drawing.Rectangle]::new($taskIconX,$taskIconY,$taskRow.Size,$taskRow.Size))
      }finally{$taskIcon.Dispose()}
     }
    }
   }finally{$taskBrush.Dispose();$taskInk.Dispose()}
  }
  $taskGraphics.DrawString('Upload individual icon PNGs only; not this comparison sheet. All pods CLOSED; no hatch outcomes shown.',$taskSmallFont,[System.Drawing.Brushes]::White,18,$taskHeight-25)
  $taskCanvas.Save($Path,[System.Drawing.Imaging.ImageFormat]::Png)
 }finally{$taskGraphics.Dispose();$taskCanvas.Dispose()}
 return @{Path=$Path;Width=$taskWidth;Height=$taskHeight;Sizes=if($Full){@(512,128,64)}else{@(128,64)}}
}
try{
 $taskSheet=Draw-PodBundleSheet -Path (Join-Path $taskDir 'sheet.png') -Full $true
 $taskPreview=Draw-PodBundleSheet -Path (Join-Path $taskDir 'sheet-preview-128-64.png') -Full $false
}finally{$taskFormat.Dispose();$taskSmallFont.Dispose();$taskLabelFont.Dispose();$taskTitleFont.Dispose()}
@{GeneratedOn='2026-10-12';Method='built-in generation plus mechanical proportional alpha-preserving crop/resize only';Framing='alpha>=16 visible bounds used only for crop measurement; 8 native pixels of antialias margin; no global alpha threshold erasing, painting or masks';MasterCanvas='512x512 RGBA, object about80%';TightCanvas='512x512 RGBA, about2% padding per side';Sheet=$taskSheet;SmallSheet=$taskPreview;Icons=$taskResults}|ConvertTo-Json -Depth 10 -Compress

