#Requires -Version 5.1
<#
SYNOPSIS: UiGuide Agent - complete uninstall with one command line: everything install.ps1 put on this computer -
  the local server (program, PATH entry, settings, registered applications, knowledge bundles), the tools
  uiguide / uiguide-companion, the NuGet source "ui-guide-agent", the downloaded and cached packages, temp files.
USAGE:
  irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/uninstall.ps1 | iex
  powershell -File scripts/uninstall.ps1 [-KeepData] [-InstallRoot <dir>]
  -KeepData   keeps the server's data and settings (registered applications, bundles, appsettings.json) for a reinstall
Your projects are never changed by this script: take UiGuide Agent out of one project with  uiguide remove  in its
folder (one project at a time, before uninstalling - afterwards the tool is gone).
#>
[CmdletBinding()]
param(
  [switch]$KeepData,
  [string]$InstallRoot = ''
)

$ErrorActionPreference = 'Stop'
$baseDir = if ([string]::IsNullOrWhiteSpace($InstallRoot)) { Join-Path $env:LOCALAPPDATA 'ui-guide-agent' } else { $InstallRoot }
$appDir  = Join-Path $baseDir 'server'
$source  = 'ui-guide-agent'
$tools   = @('UiGuideAgent.Cli', 'UiGuideAgent.Companion', 'UiGuideAgent.Server.Host')
$failed  = $false

function Write-Step([string]$msg) { Write-Host "ui-guide-agent: $msg" }
$dotnet = [bool](Get-Command dotnet -ErrorAction SilentlyContinue)

# 2. running parts
Get-Process -Name 'uiguide-server', 'uiguide-companion' -ErrorAction SilentlyContinue | ForEach-Object {
  try { Stop-Process -Id $_.Id -Force; Write-Step "stopped $($_.ProcessName) (process $($_.Id))" } catch { }
}

if ($dotnet) {
  # 3. tools
  $installed = (& dotnet tool list --global) -join "`n"
  foreach ($t in $tools) {
    if ($installed -match "(?im)^$([regex]::Escape($t))\s") {
      & dotnet tool uninstall --global $t | Out-Null
      if ($LASTEXITCODE -eq 0) { Write-Step "tool $t uninstalled" } else { Write-Step "could not uninstall the tool $t"; $failed = $true }
    }
  }
  # 4. NuGet source + the packages cached by restore
  if (((& dotnet nuget list source) -join "`n") -match "\b$([regex]::Escape($source))\b") {
    & dotnet nuget remove source $source | Out-Null
    Write-Step "NuGet source '$source' removed"
  }
  $cache = ((& dotnet nuget locals global-packages --list) -replace '^\s*global-packages:\s*', '').Trim()
  if ($cache -and (Test-Path -LiteralPath $cache)) {
    Get-ChildItem -LiteralPath $cache -Directory -Filter 'uiguideagent.*' -ErrorAction SilentlyContinue | ForEach-Object {
      Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
      Write-Step "removed from the NuGet cache: $($_.Name)"
    }
  }
}

# 5. the install folder (server, packages, data, WebView2 data); -KeepData keeps data + appsettings.json
if (Test-Path -LiteralPath $baseDir) {
  try {
    if ($KeepData) {
      $settings = Join-Path $appDir 'appsettings.json'
      if (Test-Path -LiteralPath $settings) { Copy-Item -LiteralPath $settings -Destination (Join-Path $baseDir 'appsettings.kept.json') -Force }
      Get-ChildItem -LiteralPath $baseDir -Force | Where-Object { $_.Name -notin 'data', 'appsettings.kept.json' } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
      Write-Step "removed: $baseDir (kept: data, appsettings.kept.json - the next install puts the settings back)"
    } else {
      Remove-Item -LiteralPath $baseDir -Recurse -Force
      Write-Step "removed: $baseDir"
    }
  }
  catch {
    Write-Host "ui-guide-agent: could not remove everything in $baseDir (a file in use?). Close the applications using it and run this line again." -ForegroundColor Red
    $failed = $true
  }
} else {
  Write-Step "install folder not found (skipping): $baseDir"
}

# 6. PATH and temp files
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not [string]::IsNullOrEmpty($userPath)) {
  $parts = $userPath.Split(';') | Where-Object { $_ }
  if ($parts -contains $appDir) {
    [Environment]::SetEnvironmentVariable('Path', (($parts | Where-Object { $_ -ne $appDir }) -join ';'), 'User')
    Write-Step "removed from user PATH: $appDir"
  }
}
Get-ChildItem -Path $env:TEMP -Filter 'ui-guide-agent-*' -Force -ErrorAction SilentlyContinue | ForEach-Object {
  Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($failed) {
  Write-Host 'Done, with the problems above.' -ForegroundColor Yellow
  exit 1
}
Write-Host 'Done - UiGuide Agent removed from this computer. Your projects were not changed.' -ForegroundColor Green
