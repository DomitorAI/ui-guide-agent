#Requires -Version 5.1
<#
SYNOPSIS: UiGuide Agent - makes the NuGet packages of the latest release available to `dotnet add package`
  and installs (or updates) the developer tool `uiguide`.
  Downloads the .nupkg files of the latest GitHub release into a local folder, registers that folder
  as the NuGet source "ui-guide-agent" (once) and installs the .NET tool UiGuideAgent.Cli (command `uiguide`).
  Run it again to get a newer release.
USAGE:
  irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/add-packages.ps1 | iex
  powershell -File scripts/add-packages.ps1 [-Folder <dir>] [-ConfigFile <NuGet.Config>] [-NoTool]
Then, in your project folder:  uiguide init   and   dotnet add package UiGuideAgent.Desktop
#>
[CmdletBinding()]
param(
  [string]$Folder = '',
  [string]$ConfigFile = '',
  [switch]$NoTool
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 6) {
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

$repo   = 'DomitorAI/ui-guide-agent'
$source = 'ui-guide-agent'
if ([string]::IsNullOrWhiteSpace($Folder)) { $Folder = Join-Path $env:LOCALAPPDATA 'ui-guide-agent\packages' }

function Write-Step([string]$msg) { Write-Host "ui-guide-agent: $msg" }

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
  throw 'The .NET SDK is required (dotnet). Install it from https://dotnet.microsoft.com/download and run this again.'
}

$release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest" -Headers @{ 'User-Agent' = 'ui-guide-agent-add-packages' }
$assets = @($release.assets | Where-Object { $_.name -like '*.nupkg' })
if ($assets.Count -eq 0) { throw "Release $($release.tag_name) has no NuGet packages." }

New-Item -ItemType Directory -Path $Folder -Force | Out-Null
foreach ($a in $assets) {
  $dest = Join-Path $Folder $a.name
  if (-not (Test-Path -LiteralPath $dest)) {
    Write-Step "downloading $($a.name)"
    Invoke-WebRequest -Uri $a.browser_download_url -OutFile $dest -UseBasicParsing
  }
}

$configArgs = @()
if ($ConfigFile) { $configArgs = @('--configfile', $ConfigFile) }
$known = (& dotnet nuget list source @configArgs) -join "`n"
if ($known -notmatch "\b$([regex]::Escape($source))\b") {
  & dotnet nuget add source $Folder --name $source @configArgs | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Could not register the NuGet source.' }
  Write-Step "NuGet source '$source' added: $Folder"
} elseif ($known -notmatch [regex]::Escape($Folder)) {
  # registered earlier for another folder: it must point where the packages are now
  & dotnet nuget update source $source --source $Folder @configArgs | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Could not update the NuGet source.' }
  Write-Step "NuGet source '$source' now points to $Folder"
} else {
  Write-Step "NuGet source '$source' already registered"
}

# the developer tool (uiguide) and the Companion (uiguide-companion): installed, or brought to the release's version
$toolVersion = $release.tag_name.TrimStart('v')
foreach ($t in @(@{ Id = 'UiGuideAgent.Cli'; Command = 'uiguide' }, @{ Id = 'UiGuideAgent.Companion'; Command = 'uiguide-companion' })) {
  $tool = $t.Id
  if ($NoTool -or -not ($assets | Where-Object { $_.name -like "$tool.*.nupkg" })) { continue }
  $installed = (& dotnet tool list --global) -join "`n"
  $verb = if ($installed -match "(?im)^$([regex]::Escape($tool))\s") { 'update' } else { 'install' }
  & dotnet tool $verb --global $tool --version $toolVersion --add-source $Folder | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Could not $verb the tool $tool $toolVersion." }
  Write-Step "tool '$($t.Command)' $toolVersion ready (open a NEW terminal if the command is not found)"
}

Write-Host "Done ($($release.tag_name)). In your project folder run:  uiguide init  (it says what to add: UiGuideAgent.Desktop, UiGuideAgent.Web or the Companion)" -ForegroundColor Green
