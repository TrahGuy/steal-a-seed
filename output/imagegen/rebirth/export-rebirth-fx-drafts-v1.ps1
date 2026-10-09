param(
 [Parameter(Mandatory=$true)][string]$BurstSource,
 [Parameter(Mandatory=$true)][string]$LeafSource,
 [Parameter(Mandatory=$true)][string]$SparkleSource,
 [Parameter(Mandatory=$true)][string]$AuraSource
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$fxFolder=$PSScriptRoot
$specs=@(
 @{Stem='rebirth-burst-v1';Path=$BurstSource;Size=1024;Grid=4;Tintable=$false},
 @{Stem='rebirth-leaf-v1';Path=$LeafSource;Size=512;Grid=2;Tintable=$true},
 @{Stem='rebirth-sparkle-v1';Path=$SparkleSource;Size=512;Grid=2;Tintable=$true},
 @{Stem='rebirth-aura-v1';Path=$AuraSource;Size=1024;Grid=4;Tintable=$true}
)
foreach($spec in $specs){
 foreach($suffix in @('-original.png','-draft.png')){
  if(Test-Path -LiteralPath (Join-Path $fxFolder ($spec.Stem+$suffix))){throw ('Refusing to overwrite: '+$spec.Stem+$suffix)}
 }
}
$all=@()
foreach($spec in $specs){
 $source=[System.Drawing.Bitmap]::new($spec.Path)
 $draft=[System.Drawing.Bitmap]::new($spec.Size,$spec.Size,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
 try{
  if($source.Width -ne $source.Height){throw 'Flipbook source must be square; no cropping or padding allowed.'}
  $g=[System.Drawing.Graphics]::FromImage($draft)
  try{
   $g.Clear([System.Drawing.Color]::Transparent)
   $g.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
   $g.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
   $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
   $g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
   $wrap=[System.Drawing.Imaging.ImageAttributes]::new()
   try{
    $wrap.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $g.DrawImage($source,[System.Drawing.Rectangle]::new(0,0,$spec.Size,$spec.Size),[single]0,[single]0,[single]$source.Width,[single]$source.Height,[System.Drawing.GraphicsUnit]::Pixel,$wrap)
   }finally{$wrap.Dispose()}
  }finally{$g.Dispose()}
  # Whole-sheet resampling only. No alpha, RGB, framing, crop or padding changes.
  $draftFile=$spec.Stem+'-draft.png';$originalFile=$spec.Stem+'-original.png'
  $draft.Save((Join-Path $fxFolder $draftFile),[System.Drawing.Imaging.ImageFormat]::Png)
  Copy-Item -LiteralPath $spec.Path -Destination (Join-Path $fxFolder $originalFile)
  $rect=[System.Drawing.Rectangle]::new(0,0,$spec.Size,$spec.Size)
  $locked=$draft.LockBits($rect,[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  try{
   if($locked.Stride -lt 0){throw 'Negative stride unsupported.'}
   $bytes=[byte[]]::new($locked.Stride*$spec.Size);$stride=$locked.Stride
   [System.Runtime.InteropServices.Marshal]::Copy($locked.Scan0,$bytes,0,$bytes.Length)
  }finally{$draft.UnlockBits($locked)}
  $cell=[int]($spec.Size/$spec.Grid);$frames=@();$globalMax=0;$colourSpreadMax=0
  for($row=0;$row -lt $spec.Grid;$row++){
   for($col=0;$col -lt $spec.Grid;$col++){
    $xmin=$cell;$ymin=$cell;$xmax=-1;$ymax=-1;$sum=0.0;$peak=0;$border=0;$significant=0;$centroidX=0.0;$centroidY=0.0
    for($y=0;$y -lt $cell;$y++){
     for($x=0;$x -lt $cell;$x++){
      $i=($row*$cell+$y)*$stride+($col*$cell+$x)*4
      $a=[int]$bytes[$i+3];$sum+=$a;$peak=[math]::Max($peak,$a);$centroidX+=$x*$a;$centroidY+=$y*$a
      if($x -lt 8 -or $x -ge $cell-8 -or $y -lt 8 -or $y -ge $cell-8){$border=[math]::Max($border,$a)}
      if($a -ge 8){
       $significant++;$xmin=[math]::Min($xmin,$x);$xmax=[math]::Max($xmax,$x);$ymin=[math]::Min($ymin,$y);$ymax=[math]::Max($ymax,$y)
       $rgb=@([int]$bytes[$i],[int]$bytes[$i+1],[int]$bytes[$i+2]);$rgbMax=[math]::Max($rgb[0],[math]::Max($rgb[1],$rgb[2]));$rgbMin=[math]::Min($rgb[0],[math]::Min($rgb[1],$rgb[2]));$colourSpreadMax=[math]::Max($colourSpreadMax,$rgbMax-$rgbMin)
      }
     }
    }
    $globalMax=[math]::Max($globalMax,$peak)
    $frames+=@{frame=$row*$spec.Grid+$col+1;meanAlpha=[math]::Round($sum/($cell*$cell),3);maxAlpha=$peak;margin8MaxAlpha=$border;significantPixels=$significant;significantBounds=@{x=$xmin;y=$ymin;width=if($xmax -ge 0){$xmax-$xmin+1}else{0};height=if($ymax -ge 0){$ymax-$ymin+1}else{0}};alphaCentroid=if($sum -gt 0){@{x=[math]::Round($centroidX/$sum,3);y=[math]::Round($centroidY/$sum,3)}}else{$null}}
   }
  }
  $all+=@{stem=$spec.Stem;draftFile=$draftFile;originalFile=$originalFile;nativeWidth=$source.Width;nativeHeight=$source.Height;width=$spec.Size;height=$spec.Size;grid=$spec.Grid;frameCount=$spec.Grid*$spec.Grid;cellSize=$cell;tintable=$spec.Tintable;cornerAlpha=@($draft.GetPixel(0,0).A,$draft.GetPixel($spec.Size-1,0).A,$draft.GetPixel(0,$spec.Size-1).A,$draft.GetPixel($spec.Size-1,$spec.Size-1).A);maxAlpha=$globalMax;maxRGBChannelSpreadAtSignificantAlpha=$colourSpreadMax;frames=$frames;status='draft, no cleanup applied'}
 }finally{$source.Dispose();$draft.Dispose()}
}
$all | ConvertTo-Json -Depth 10 -Compress
