#Requires -Version 5.1
<#
SYNOPSIS: UiGuide Agent - complete install (or update) with one command line:
  the local server, the NuGet packages (local source "ui-guide-agent") and the tools uiguide / uiguide-companion.
USAGE:
  irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/install.ps1 | iex
  powershell -File scripts/install.ps1 [-ServerOnly | -NoServer] [-InstallRoot <dir>] [-NoPath]
Run it again to update to the latest release (your server settings are kept).
Remove everything:  irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/uninstall.ps1 | iex
#>
[CmdletBinding()]
param(
  [switch]$ServerOnly,   # only the server (e.g. a machine that only runs it)
  [switch]$NoServer,     # only packages + tools (e.g. the server runs elsewhere)
  [string]$InstallRoot = '',
  [string]$ZipUrl = '',
  [switch]$NoPath
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 6) {
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}
$raw = 'https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts'
$baseDir = if ([string]::IsNullOrWhiteSpace($InstallRoot)) { Join-Path $env:LOCALAPPDATA 'ui-guide-agent' } else { $InstallRoot }

# the two parts: next to this file when run from a clone, else from GitHub (irm | iex has no file)
function Get-Part([string]$name) {
  if ($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot $name))) { return Join-Path $PSScriptRoot $name }
  $dest = Join-Path $env:TEMP ("ui-guide-agent-" + [Guid]::NewGuid().ToString('N') + "-$name")
  Invoke-WebRequest -Uri "$raw/$name" -OutFile $dest -UseBasicParsing
  return $dest
}

if (-not $NoServer) {
  $bootstrap = Get-Part 'bootstrap.ps1'
  $serverArgs = @{ InstallRoot = $baseDir }
  if ($ZipUrl) { $serverArgs.ZipUrl = $ZipUrl }
  if ($NoPath) { $serverArgs.NoPath = $true }
  & $bootstrap @serverArgs
}

if (-not $ServerOnly) {
  if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    & (Get-Part 'add-packages.ps1') -Folder (Join-Path $baseDir 'packages')
  } else {
    Write-Host 'ui-guide-agent: the .NET SDK (dotnet) is not installed - the packages and the tools uiguide / uiguide-companion are skipped.' -ForegroundColor Yellow
    Write-Host '                Install it from https://dotnet.microsoft.com/download and run this line again.' -ForegroundColor Yellow
  }
}

Get-ChildItem -Path $env:TEMP -Filter 'ui-guide-agent-*-*.ps1' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host 'UiGuide Agent installed. Next:' -ForegroundColor Green
if (-not $NoServer) { Write-Host "  1. set your LLM in $(Join-Path $baseDir 'server\appsettings.json') (the key only as the environment variable Llm__ApiKey), then start: uiguide-server" }
if ($NoServer) { Write-Host '  in your project folder (a NEW terminal):  uiguide init --server https://<your company''s server>   - it says what to add and prints the line for the server''s administrator' }
elseif (-not $ServerOnly) { Write-Host '  2. in your project folder (a NEW terminal):  uiguide init   - it says what to add for your kind of application' }
