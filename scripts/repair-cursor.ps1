# Full Cursor repair for Windows.
# Fixes corrupted popups, blank UI, GPU glitches, and bad workspace layout state.
#
# Usage (PowerShell):
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\scripts\repair-cursor.ps1
#   .\scripts\repair-cursor.ps1 -Full
#
# Or double-click: scripts\repair-cursor.cmd

param(
  [switch]$Full,
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: .\scripts\repair-cursor.ps1 [-Full]"
  Write-Host "  -Full  Also clear workspaceStorage / History (resets local chats)"
  exit 0
}

$ErrorActionPreference = "Continue"
$mode = if ($Full) { "FULL" } else { "SAFE" }
Write-Host "==> Cursor full repair (mode: $mode)"

$appSupport = Join-Path $env:APPDATA "Cursor"
$userDir = Join-Path $appSupport "User"
$localCursor = Join-Path $env:LOCALAPPDATA "Cursor"
$localPrograms = Join-Path $env:LOCALAPPDATA "Programs\cursor"

if (-not (Test-Path $appSupport)) {
  Write-Error "Cursor data folder not found at: $appSupport`nIs Cursor installed for this user?"
  exit 1
}

Write-Host "==> Quitting Cursor..."
Get-Process -Name "Cursor","cursor" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$backupDir = Join-Path $appSupport ("repair-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
New-Item -ItemType Directory -Force -Path $userDir | Out-Null

$argvPath = Join-Path $userDir "argv.json"
Write-Host "==> Writing argv.json (disable GPU / use ANGLE gl)"
if (Test-Path $argvPath) {
  Copy-Item $argvPath (Join-Path $backupDir "argv.json.bak") -Force
}
@"
{
  "disable-hardware-acceleration": true,
  "use-angle": "gl"
}
"@ | Set-Content -Path $argvPath -Encoding UTF8
Write-Host "Updated $argvPath"

$settingsPath = Join-Path $userDir "settings.json"
Write-Host "==> Ensuring settings.json exists"
if (Test-Path $settingsPath) {
  Copy-Item $settingsPath (Join-Path $backupDir "settings.json.bak") -Force
} elseif (-not (Test-Path $settingsPath)) {
  "{}" | Set-Content -Path $settingsPath -Encoding UTF8
}

function Clear-CursorPath([string]$path) {
  if (Test-Path $path) {
    Write-Host "==> Clearing $(Split-Path $path -Leaf)"
    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Write-Host "==> Clearing GPU / Electron / Chromium caches"
$cacheNames = @(
  "GPUCache",
  "Code Cache",
  "Cache",
  "CachedData",
  "CachedExtensions",
  "CachedExtensionVSIXs",
  "CachedProfilesData",
  "DawnGraphiteCache",
  "DawnWebGPUCache",
  "ShaderCache",
  "Service Worker",
  "Local Storage",
  "Session Storage",
  "Shared Dictionary",
  "blob_storage",
  "Crashpad",
  "Crash Reports",
  "VideoDecodeStats",
  "WebStorage",
  "logs"
)

foreach ($name in $cacheNames) {
  Clear-CursorPath (Join-Path $appSupport $name)
  Clear-CursorPath (Join-Path $localCursor $name)
}

Write-Host "==> Repairing corrupted workspace layout keys (keeps chats)"
$wsRoot = Join-Path $userDir "workspaceStorage"
$globalRoot = Join-Path $userDir "globalStorage"
$layoutKeys = @(
  "cursor/editorLayout.auxiliaryBarVisible",
  "workbench.auxiliaryBar.hidden",
  "workbench.panel.hidden"
)
$sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue

function Repair-StateDb([string]$root) {
  if (-not (Test-Path $root)) { return }
  Get-ChildItem -Path $root -Filter "state.vscdb" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    if ($sqlite) {
      foreach ($key in $layoutKeys) {
        & sqlite3 $_.FullName "DELETE FROM ItemTable WHERE key = '$key';" 2>$null
      }
    }
    Remove-Item -LiteralPath ($_.FullName + ".backup") -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath ($_.FullName + "-wal") -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath ($_.FullName + "-shm") -Force -ErrorAction SilentlyContinue
  }
}

if ($sqlite) {
  Repair-StateDb $wsRoot
  Repair-StateDb $globalRoot
  Write-Host "    Cleaned state.vscdb files"
} else {
  Write-Host "    sqlite3 not found — surgical DB repair skipped (use -Full to wipe workspaceStorage)"
}

if ($Full) {
  Write-Host "==> FULL mode: clearing workspaceStorage / History"
  Write-Host "    WARNING: local chat history / open tabs will be reset"
  if (Test-Path $wsRoot) {
    Copy-Item $wsRoot (Join-Path $backupDir "workspaceStorage.bak") -Recurse -Force -ErrorAction SilentlyContinue
    Clear-CursorPath $wsRoot
  }
  Clear-CursorPath (Join-Path $userDir "History")
  Clear-CursorPath (Join-Path $globalRoot "storage.json")
}

$stamp = Join-Path $userDir ".cursor-repair-stamp"
@"
repairedAt=$(Get-Date -Format o)
mode=$mode
backup=$backupDir
"@ | Set-Content -Path $stamp -Encoding UTF8

Write-Host ""
Write-Host "Repair complete."
Write-Host "Backup: $backupDir"
Write-Host "Reopen Cursor now."
Write-Host ""
Write-Host "After reopen:"
Write-Host "  1. Start a NEW chat (old corrupted chats can keep spawning bad popups)"
Write-Host "  2. Avoid 'Open Chat as Editor' for now"
Write-Host "  3. If still broken, re-run: .\scripts\repair-cursor.ps1 -Full"
Write-Host "  4. Last resort: reinstall from https://cursor.com/download"

if (Test-Path (Join-Path $localPrograms "Cursor.exe")) {
  Write-Host ""
  Write-Host "Optional GPU-safe launch:"
  Write-Host ("  & '{0}' --disable-gpu --disable-extensions" -f (Join-Path $localPrograms "Cursor.exe"))
}
