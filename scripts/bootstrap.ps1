#Requires -Version 5.1
<#
SYNOPSIS: UiGuide Agent local server - install or update with one command line, no installer.
USAGE:
  irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/bootstrap.ps1 | iex
  powershell -File scripts/bootstrap.ps1 [-ZipUrl <url or local zip>] [-InstallRoot <dir>] [-NoPath]
After install, open a NEW terminal and run:  uiguide-server
Alternative for .NET developers:            dotnet tool install -g UiGuideAgent.Server.Host
#>
[CmdletBinding()]
param(
  [string]$ZipUrl = '',
  [string]$InstallRoot = '',
  [switch]$NoPath
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 6) {
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

$repo    = 'DomitorAI/ui-guide-agent'
$baseDir = if ([string]::IsNullOrWhiteSpace($InstallRoot)) { Join-Path $env:LOCALAPPDATA 'ui-guide-agent' } else { $InstallRoot }
$appDir  = Join-Path $baseDir 'server'
$exeName = 'uiguide-server.exe'
$exePath = Join-Path $appDir $exeName

if ([string]::IsNullOrWhiteSpace($ZipUrl)) {
  $ZipUrl = "https://github.com/$repo/releases/latest/download/ui-guide-agent-server-win-x64.zip"
}

function Write-Step([string]$msg) {
  Write-Host "ui-guide-agent: $msg"
}

function Save-File([string]$source, [string]$dest) {
  if (Test-Path -LiteralPath $source) {
    Write-Step "copying $source"
    Copy-Item -LiteralPath $source -Destination $dest -Force
    return
  }
  Write-Step "downloading $source"
  try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $source -OutFile $dest -UseBasicParsing
  }
  catch {
    Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
    Write-Host 'ui-guide-agent: download failed - check the internet connection and rerun the command.' -ForegroundColor Red
    throw
  }
}

# --- Settings on update -------------------------------------------------------------------------------
# The new version's appsettings.json (its comments and every setting it knows) is installed, and your
# values are copied into it. A value equal to a default of an earlier version takes the new default.
# Settings this version does not know are kept. The previous file is saved as appsettings.json.bak.

# Defaults of earlier versions that changed (path -> earlier values, as compact JSON).
$PreviousDefaults = @{
  'UiGuide/Bundles/RetentionDays' = @('90')
  'UiGuide/Queue/Slots'           = @('2')
}

function Skip-JsonSpace($s, [string]$t) {
  while ($s.i -lt $t.Length) {
    $c = $t[$s.i]
    if ([char]::IsWhiteSpace($c)) { $s.i++ }
    elseif ($c -eq '/' -and $s.i + 1 -lt $t.Length -and $t[$s.i + 1] -eq '/') {
      while ($s.i -lt $t.Length -and $t[$s.i] -ne "`n") { $s.i++ }
    }
    elseif ($c -eq '/' -and $s.i + 1 -lt $t.Length -and $t[$s.i + 1] -eq '*') {
      $end = $t.IndexOf('*/', $s.i + 2)
      if ($end -lt 0) { throw 'unterminated comment' }
      $s.i = $end + 2
    }
    else { break }
  }
}

function Read-JsonString($s, [string]$t) {
  if ($t[$s.i] -ne '"') { throw "expected a string at $($s.i)" }
  $s.i++
  $sb = New-Object Text.StringBuilder
  while ($true) {
    if ($s.i -ge $t.Length) { throw 'unterminated string' }
    $c = $t[$s.i]
    if ($c -eq '"') { $s.i++; break }
    if ($c -eq '\') {
      $e = $t[$s.i + 1]
      switch -CaseSensitive ($e) {
        'n' { [void]$sb.Append("`n") } 't' { [void]$sb.Append("`t") } 'r' { [void]$sb.Append("`r") }
        'b' { [void]$sb.Append([char]8) } 'f' { [void]$sb.Append([char]12) }
        'u' { [void]$sb.Append([char][Convert]::ToInt32($t.Substring($s.i + 2, 4), 16)); $s.i += 4 }
        default { [void]$sb.Append($e) }
      }
      $s.i += 2
      continue
    }
    [void]$sb.Append($c); $s.i++
  }
  $sb.ToString()
}

# Every value of a JSON-with-comments text: path ('a/b/c') -> start, end, kind; objects also their braces and size.
function Read-JsonSpans([string]$t) {
  $s = @{ i = 0 }
  $spans = @{}
  Read-JsonValue $s $t @() $spans
  Skip-JsonSpace $s $t
  if ($s.i -lt $t.Length) { throw "unexpected text at $($s.i)" }
  $spans
}

function Read-JsonValue($s, [string]$t, [string[]]$path, $spans) {
  Skip-JsonSpace $s $t
  if ($s.i -ge $t.Length) { throw 'unexpected end' }
  $start = $s.i
  $c = $t[$s.i]
  if ($c -eq '{') {
    $s.i++
    $count = 0
    while ($true) {
      Skip-JsonSpace $s $t
      if ($s.i -ge $t.Length) { throw 'unterminated object' }
      if ($t[$s.i] -eq '}') { break }
      if ($t[$s.i] -eq ',') { $s.i++; continue }
      $key = Read-JsonString $s $t
      Skip-JsonSpace $s $t
      if ($t[$s.i] -ne ':') { throw "expected ':' at $($s.i)" }
      $s.i++
      Read-JsonValue $s $t ($path + $key) $spans
      $count++
    }
    $spans[($path -join '/')] = @{ Path = $path; Start = $start; End = $s.i + 1; Kind = 'object'; Count = $count }
    $s.i++
    return
  }
  if ($c -eq '[') {
    $depth = 0
    while ($s.i -lt $t.Length) {
      $ch = $t[$s.i]
      if ($ch -eq '"') { [void](Read-JsonString $s $t); continue }
      if ($ch -eq '/' -and ($t[$s.i + 1] -eq '/' -or $t[$s.i + 1] -eq '*')) { Skip-JsonSpace $s $t; continue }
      if ($ch -eq '[') { $depth++ } elseif ($ch -eq ']') { $depth--; if ($depth -eq 0) { $s.i++; break } }
      $s.i++
    }
    if ($depth -ne 0) { throw 'unterminated array' }
  }
  elseif ($c -eq '"') { [void](Read-JsonString $s $t) }
  else {
    while ($s.i -lt $t.Length -and ',}]/'.IndexOf($t[$s.i]) -lt 0 -and -not [char]::IsWhiteSpace($t[$s.i])) { $s.i++ }
    if ($s.i -eq $start) { throw "unexpected '$c' at $start" }
  }
  $spans[($path -join '/')] = @{ Path = $path; Start = $start; End = $s.i; Kind = 'value' }
}

# A value in a comparable form (0.30 = 0.3, spacing ignored).
function Get-JsonCanonical([string]$raw) {
  $sb = New-Object Text.StringBuilder
  $inStr = $false
  for ($k = 0; $k -lt $raw.Length; $k++) {
    $c = $raw[$k]
    if ($inStr) { [void]$sb.Append($c); if ($c -eq '\') { $k++; [void]$sb.Append($raw[$k]) } elseif ($c -eq '"') { $inStr = $false }; continue }
    if ($c -eq '"') { $inStr = $true; [void]$sb.Append($c); continue }
    if ($c -eq '/' -and $raw[$k + 1] -eq '/') { while ($k -lt $raw.Length -and $raw[$k] -ne "`n") { $k++ }; continue }
    if ($c -eq '/' -and $raw[$k + 1] -eq '*') { $end = $raw.IndexOf('*/', $k + 2); if ($end -lt 0) { throw 'unterminated comment' }; $k = $end + 1; continue }
    [void]$sb.Append($c)
  }
  $clean = [regex]::Replace($sb.ToString(), ',(\s*[}\]])', '$1')
  # wrapped in an object: Windows PowerShell 5.1 writes a top-level array as {"value":[...],"Count":n}
  $json = ConvertTo-Json -InputObject (ConvertFrom-Json -InputObject ('{"v":' + $clean + '}')) -Compress -Depth 20
  $json.Substring(5, $json.Length - 6)
}

function Get-JsonIndent([string]$t, [int]$at) {
  $lineStart = $t.LastIndexOf("`n", [Math]::Max(0, $at - 1)) + 1
  $m = [regex]::Match($t.Substring($lineStart), '^[ \t]*')
  $m.Value
}

# Returns @{ Text; Changed; Kept; Defaults; Extra; Skipped } or throws when either file cannot be read.
function Merge-Settings([string]$userText, [string]$newText) {
  $user = Read-JsonSpans $userText
  $tpl = Read-JsonSpans $newText
  if ($user[''].Kind -ne 'object' -or $tpl[''].Kind -ne 'object') { throw 'settings are not a JSON object' }
  $result = @{ Kept = @(); Defaults = @(); Extra = @(); Skipped = @() }
  $leaves = @($user.Values | Where-Object { $_.Kind -eq 'value' } | Sort-Object { $_.Start })
  $replace = @(); $missing = @()
  foreach ($u in $leaves) {
    $key = $u.Path -join '/'
    $raw = $userText.Substring($u.Start, $u.End - $u.Start)
    if (-not $tpl.ContainsKey($key)) { $missing += , @($u, $raw); continue }
    $n = $tpl[$key]
    if ($n.Kind -ne 'value') { $result.Skipped += $key; continue }
    $cu = Get-JsonCanonical $raw
    $cn = Get-JsonCanonical $newText.Substring($n.Start, $n.End - $n.Start)
    if ($cu -eq $cn) { continue }
    $old = @(); if ($PreviousDefaults.ContainsKey($key)) { $old = @($PreviousDefaults[$key] | ForEach-Object { Get-JsonCanonical $_ }) }
    if ($old -contains $cu) { $result.Defaults += "$key $cu -> $cn"; continue }
    $replace += @{ Start = $n.Start; End = $n.End; Text = $raw }
    $result.Kept += $key
  }
  $text = $newText
  foreach ($r in ($replace | Sort-Object { $_.Start } -Descending)) {
    $text = $text.Substring(0, $r.Start) + $r.Text + $text.Substring($r.End)
  }
  $nl = if ($newText.Contains("`r`n")) { "`r`n" } else { "`n" }
  foreach ($m in $missing) {
    $u = $m[0]; $raw = $m[1]
    $cur = Read-JsonSpans $text
    $k = $u.Path.Count - 1
    while ($k -gt 0 -and -not $cur.ContainsKey(($u.Path[0..($k - 1)] -join '/'))) { $k-- }
    $parentKey = if ($k -gt 0) { $u.Path[0..($k - 1)] -join '/' } else { '' }
    $parent = $cur[$parentKey]
    if ($parent.Kind -ne 'object') { $result.Skipped += ($u.Path -join '/'); continue }
    $rest = @($u.Path[$k..($u.Path.Count - 1)])
    $value = $raw
    for ($j = $rest.Count - 1; $j -ge 1; $j--) { $value = '{ ' + (ConvertTo-Json -InputObject $rest[$j]) + ': ' + $value + ' }' }
    $indent = (Get-JsonIndent $text $parent.Start) + '  '
    $entry = $nl + $indent + (ConvertTo-Json -InputObject $rest[0]) + ': ' + $value
    if ($parent.Count -gt 0) { $entry += ',' } else { $entry += $nl + (Get-JsonIndent $text $parent.Start) }
    $text = $text.Substring(0, $parent.Start + 1) + $entry + $text.Substring($parent.Start + 1)
    $result.Extra += ($u.Path -join '/')
  }
  # check: every value of yours is in the result, every other value is the new default
  $final = Read-JsonSpans $text
  [void](Get-JsonCanonical $text)
  foreach ($u in $leaves) {
    $key = $u.Path -join '/'
    if ($result.Skipped -contains $key -or ($result.Defaults | Where-Object { $_.StartsWith("$key ") })) { continue }
    $f = $final[$key]
    if (-not $f -or (Get-JsonCanonical $text.Substring($f.Start, $f.End - $f.Start)) -ne (Get-JsonCanonical $userText.Substring($u.Start, $u.End - $u.Start))) { throw "merge check failed: $key" }
  }
  foreach ($n in ($tpl.Values | Where-Object { $_.Kind -eq 'value' })) {
    $key = $n.Path -join '/'
    if ($result.Kept -contains $key) { continue }
    $f = $final[$key]
    if (-not $f -or (Get-JsonCanonical $text.Substring($f.Start, $f.End - $f.Start)) -ne (Get-JsonCanonical $newText.Substring($n.Start, $n.End - $n.Start))) { throw "merge check failed: $key" }
  }
  $result.Text = $text
  $result.Changed = ($text.Replace("`r`n", "`n") -ne $userText.Replace("`r`n", "`n"))
  $result
}
# -------------------------------------------------------------------------------------------------------

$running = Get-Process -Name 'uiguide-server' -ErrorAction SilentlyContinue |
  Where-Object { $_.Path -and $_.Path.StartsWith($appDir, [StringComparison]::OrdinalIgnoreCase) }
if ($running) {
  throw 'uiguide-server is running - stop it (Ctrl+C in its window) and rerun the command.'
}

$tmp = Join-Path $env:TEMP ('ui-guide-agent-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  $zip = Join-Path $tmp 'server.zip'
  Save-File $ZipUrl $zip

  $extract = Join-Path $tmp 'server'
  Write-Step 'extracting archive'
  Expand-Archive -Path $zip -DestinationPath $extract
  if (-not (Test-Path -LiteralPath (Join-Path $extract $exeName))) {
    throw "archive does not contain $exeName"
  }

  # Update: the program is replaced; your settings are moved into the new version's appsettings.json.
  $utf8 = New-Object Text.UTF8Encoding($false)
  $settings = Join-Path $appDir 'appsettings.json'
  $backup = Join-Path $appDir 'appsettings.json.bak'
  $kept = Join-Path $baseDir 'appsettings.kept.json'   # settings kept by  uninstall.ps1 -KeepData
  # appsettings.kept.json exists only after  uninstall -KeepData  or an update that did not finish:
  # then it holds your settings, not the server folder
  $userText = $null
  if (Test-Path -LiteralPath $kept) { $userText = [IO.File]::ReadAllText($kept) }
  elseif (Test-Path -LiteralPath $settings) { $userText = [IO.File]::ReadAllText($settings) }
  $previousBackup = $null
  if (Test-Path -LiteralPath $backup) { $previousBackup = [IO.File]::ReadAllText($backup) }
  # your settings go to a safe place first: if anything below fails, the next run takes them from there
  if ($null -ne $userText) { [IO.File]::WriteAllText($kept, $userText, $utf8) }
  # the folder's content is replaced, not the folder (a terminal or Explorer open in it does not block the update)
  if (Test-Path -LiteralPath $appDir) {
    try { Get-ChildItem -LiteralPath $appDir -Force | Remove-Item -Recurse -Force }
    catch {
      Write-Host "ui-guide-agent: a file in $appDir is in use - close what has it open (an editor, a terminal) and rerun the command." -ForegroundColor Red
      if ($null -ne $userText) { Write-Host "ui-guide-agent: your settings are safe in $kept - the next run puts them back." -ForegroundColor Yellow }
      throw
    }
  }
  New-Item -ItemType Directory -Path $appDir -Force | Out-Null
  Copy-Item -Path (Join-Path $extract '*') -Destination $appDir -Recurse
  if ($null -ne $userText) {
    $newText = [IO.File]::ReadAllText($settings)
    $merged = $null
    try { $merged = Merge-Settings $userText $newText } catch { $mergeError = $_.Exception.Message }
    if ($merged -and $merged.Changed) {
      [IO.File]::WriteAllText($backup, $userText, $utf8)
      [IO.File]::WriteAllText($settings, $merged.Text, $utf8)
      Write-Step "appsettings.json updated to this version - your values kept: $($merged.Kept.Count)"
      foreach ($d in $merged.Defaults) { Write-Step "  default of this version: $d" }
      foreach ($x in $merged.Extra) { Write-Step "  kept, not a setting of this version: $x" }
      foreach ($x in $merged.Skipped) { Write-Step "  not kept (its format changed in this version): $x" }
      Write-Step "  your previous file: $backup"
    }
    elseif ($merged) {
      [IO.File]::WriteAllText($settings, $userText, $utf8)
      if ($null -ne $previousBackup) { [IO.File]::WriteAllText($backup, $previousBackup, $utf8) }
      Write-Step 'kept your appsettings.json (already up to date)'
    }
    else {
      [IO.File]::WriteAllText((Join-Path $appDir 'appsettings.json.new'), $newText, $utf8)
      [IO.File]::WriteAllText($settings, $userText, $utf8)
      if ($null -ne $previousBackup) { [IO.File]::WriteAllText($backup, $previousBackup, $utf8) }
      Write-Host "ui-guide-agent: kept your appsettings.json unchanged - it could not be read ($mergeError)." -ForegroundColor Yellow
      Write-Host "ui-guide-agent: this version's settings, for comparison: $(Join-Path $appDir 'appsettings.json.new')" -ForegroundColor Yellow
    }
    Remove-Item -LiteralPath $kept -Force -ErrorAction SilentlyContinue
  }
  Write-Step "installed: $exePath"
}
finally {
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# Add the install folder to the user PATH (once).
if (-not $NoPath) {
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $parts = @()
  if (-not [string]::IsNullOrEmpty($userPath)) { $parts = @($userPath.Split(';') | Where-Object { $_ }) }
  if ($parts -notcontains $appDir) {
    [Environment]::SetEnvironmentVariable('Path', (($parts + $appDir) -join ';'), 'User')
    Write-Step "added to user PATH: $appDir"
  }
}

Write-Host ''
if ($NoPath) {
  Write-Host "Done. Run:  $exePath" -ForegroundColor Green
} else {
  Write-Host 'Done. Open a NEW terminal and run:  uiguide-server' -ForegroundColor Green
}
Write-Host "Settings: $(Join-Path $appDir 'appsettings.json')"
