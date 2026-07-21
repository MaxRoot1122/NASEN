# Repair Cursor (corrupted popup)

One-shot fix for garbled / corrupted Cursor popups. Disables hardware acceleration, sets ANGLE to `gl`, and clears GPU/Electron caches.

## Before you run

1. **Save your work**
2. **Quit Cursor completely** (all windows)

## Run it

### macOS / Linux

```bash
cd /path/to/nasen
chmod +x scripts/repair-cursor.sh
./scripts/repair-cursor.sh
```

### Windows (PowerShell)

```powershell
cd path\to\nasen
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\repair-cursor.ps1
```

Then reopen Cursor.

## What it changes

- Writes `%APPDATA%/Cursor/User/argv.json` (or macOS/Linux equivalent) with:
  - `disable-hardware-acceleration: true`
  - `use-angle: "gl"`
- Deletes `GPUCache`, `Code Cache`, `Cache`, `CachedData`
- Removes corrupted layout key `cursor/editorLayout.auxiliaryBarVisible` from workspace DBs when `sqlite3` is available

A timestamped backup of `argv.json` is saved under `Cursor/repair-backup-*`.
