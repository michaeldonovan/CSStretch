$ErrorActionPreference = "Stop"

# Find QRes.exe
$scriptDir = if (-not $PSScriptRoot) { 
    Split-Path -Parent (Convert-Path ([Environment]::GetCommandLineArgs()[0])) 
  } 
  else {
    $PSScriptRoot 
  }
  
$QResPath = "$($scriptDir)\QRes.exe"

if (!([System.IO.File]::Exists($QResPath))) {
    Write-Information "Could not find QRes.exe in directory with this script. Looking in PATH"
}

$QResPath = $(Get-Command -CommandType Application -Name QRes.exe | Select-Object -first 1 -Property Source).Source

$TARGET_ASPECT = if ($env:CSSTRETCH_ASPECT) { $env:CSSTRETCH_ASPECT } else { 4/3 };
$TARGET_ASPECT = [math]::Round($TARGET_ASPECT, 2)


# Save the current screen resolution
$currentResolution = & $QResPath /S
if ($LastExitCode -ne 0)
{
    Write-Error 'Failed to get current resolution'
    exit
}

$regex = [regex]::Match($currentResolution, '(\d+)x(\d+), (\d+) bits @ (\d+) Hz')
$oldResolution = @{
    Width = $regex.Groups[1].Value
    Height = $regex.Groups[2].Value
    ColorDepth = $regex.Groups[3].Value
    RefreshRate = $regex.Groups[4].Value
}


Write-Information "Target: $TARGET_ASPECT"


# List available modes
$modes = & $QResPath -L
if ($LastExitCode -ne 0)
{
    Write-Error 'Failed to list available resolutions'
    exit
}

# Filter and select highest 16:9 resolution
$regex = "\b(\d+)x(\d+),\s+(\d+)\s+bits\s+@(\s+\d+)\s+Hz"
$matches = [regex]::Matches($modes, $regex)
$bestres = @{
    Width = 0
    Height = 0
    RefreshRate = 0
    Pixels = 0
}

foreach ($match in $matches) {
    $resolution = $match.Value -replace ', \d+ bits', ''
    $width = [int]$match.Groups[1].Value
    $height = [int]$match.Groups[2].Value
    $refresh = [int]$match.Groups[4].Value

    $aspectRatio = [math]::Round($width / $height, 2)
    
    if ($aspectRatio -eq $TARGET_ASPECT) {
   
        $pixels = $width * $height
        if ($pixels -gt $bestres.Pixels) {
            $bestres.Width = $width
            $bestres.Height = $height
            $bestres.RefreshRate = $refresh
            $bestres.Pixels = $pixels
        }
        elseif ($pixels -eq $bestres.Pixels -and $refresh -gt $bestres.RefreshRate) {
            $bestres.RefreshRate = $refresh
        }
    }
}

if ($bestres.Width -eq 0 -or $bestres.Height -eq 0) {
    Write-Error 'Failed to find supported resolution for aspect ratio $TARGET_ASPECT'
    exit
}


Write-Information "Best match: $($bestres.Width)x$($bestres.Height) @ $($bestres.RefreshRate) Hz"

# Change resolution
if ([int]$env:CSSTRETCH_NO_REFRESH_RATE -eq $true -or $oldResolution.RefreshRate -eq $bestres.RefreshRate){
    & $QResPath /X:$($bestres.Width) /Y:$($bestres.Height) | out-null
}else {
    & $QResPath /X:$($bestres.Width) /Y:$($bestres.Height) /R:$($bestres.RefreshRate) | out-null
}

if ($LastExitCode -ne 0)
{
    Write-Error 'Failed to set new resolution'
    exit
}

# Start the game
Start-Process "steam://rungameid/730"
if ($LastExitCode -ne 0)
{
    Write-Error 'Failed to launch CS2'
    exit
}
Start-Sleep -Seconds 5

# Wait until CS2 exists
do {
    $process = Get-Process -Name "cs2" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
} while ($process)


# Restore the current screen resolution
if ([int]$env:CSSTRETCH_NO_REFRESH_RATE -eq $true -or $oldResolution.RefreshRate -eq $bestres.RefreshRate){
    & $QResPath /X:$($oldResolution.Width) /Y:$($oldResolution.Height) | out-null
}else {
    & $QResPath /X:$($oldResolution.Width) /Y:$($oldResolution.Height) /R:$($oldResolution.RefreshRate) | out-null
}

if ($LastExitCode -ne 0)
{
    Write-Error 'Failed to restore old resolution'
    exit
}