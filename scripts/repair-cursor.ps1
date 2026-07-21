# Repair Cursor corrupted popups / garbled UI (Windows).
# Quit Cursor before running, or this script will try to quit it for you.
# Run in PowerShell:
#   Set-ExecutionPolicy -Scope Process Bypass; .\scripts\repair-cursor.ps1

$ErrorActionPreference = "Stop"
Write-Host "==> Cursor corrupted-popup repair"

$appSupport = Join-Path $env:APPDATA "Cursor"
$userDir = Join-Path $appSupport "User"
$localCursor = Join-Path $env:LOCALAPPDATA "Cursor"

if (-not (Test-Path $appSupport)) {
  Write-Error "Cursor data folder not found at: $appSupport`nIs Cursor installed for this user?"
}

Write-Host "==> Quitting Cursor..."
Get-Process -Name "Cursor" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$backupDir = Join-Path $appSupport ("repair-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
New-Item -ItemType Directory -Force -Path $userDir | Out-Null

$argvPath = Join-Path $userDir "argv.json"
Write-Host "==> Writing argv.json (disable GPU / use ANGLE gl)"

if (Test-Path $argvPath) {
  Copy-Item $argvPath (Join-Path $backupDir "argv.json.bak") -Force
}

# Always write a clean argv.json for this repair (backed up above if present)
@"
{
  "disable-hardware-acceleration": true,
  "use-angle": "gl"
}
"@ | Set-Content -Path $argvPath -Encoding UTF8
Write-Host "Updated $argvPath"

function Clear-CursorDir([string]$path) {
  if (Test-Path $path) {
    Write-Host "==> Clearing $(Split-Path $path -Leaf)"
    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Write-Host "==> Clearing GPU / Electron caches"
Clear-CursorDir (Join-Path $appSupport "GPUCache")
Clear-CursorDir (Join-Path $appSupport "Code Cache")
Clear-CursorDir (Join-Path $appSupport "Cache")
Clear-CursorDir (Join-Path $appSupport "CachedData")
Clear-CursorDir (Join-Path $appSupport "CachedExtensions")
Clear-CursorDir (Join-Path $appSupport "CachedExtensionVSIXs")
Clear-CursorDir (Join-Path $localCursor "GPUCache")
Clear-CursorDir (Join-Path $localCursor "Code Cache")

Write-Host "==> Clearing corrupted layout keys (keeps chats when possible)"
$wsRoot = Join-Path $userDir "workspaceStorage"
if (Test-Path $wsRoot) {
  $sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue
  if ($sqlite) {
    Get-ChildItem -Path $wsRoot -Filter "state.vscdb" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
      & sqlite3 $_.FullName "DELETE FROM ItemTable WHERE key = 'cursor/editorLayout.auxiliaryBarVisible';" 2>$null
    }
    Write-Host "    Removed corrupted layout keys from workspace DBs"
  } else {
    Write-Host "    sqlite3 not found — skipping surgical layout fix"
  }
}

Write-Host ""
Write-Host "Done. Backup of argv.json (if any): $backupDir"
Write-Host "Reopen Cursor now. Corrupted popups should be fixed."
Write-Host "If still broken: start a new chat, and avoid 'Open Chat as Editor'."
