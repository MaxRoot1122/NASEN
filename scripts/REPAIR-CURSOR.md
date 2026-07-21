# Repair Cursor (corrupted popup / blank UI / GPU glitches)

One-shot repair for local Cursor. A cloud agent **cannot** edit your desktop install — run this on your machine after quitting Cursor.

## Quick start (safe repair)

### Windows
Double-click: `scripts/repair-cursor.cmd`  
Or PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\repair-cursor.ps1
```

### macOS
Double-click: `scripts/repair-cursor.command`  
Or Terminal:

```bash
chmod +x scripts/repair-cursor.sh scripts/repair-cursor.command
./scripts/repair-cursor.sh
```

### Linux

```bash
chmod +x scripts/repair-cursor.sh
./scripts/repair-cursor.sh
```

Then **reopen Cursor** and **start a new chat**.

## If still broken (full wipe of project UI state)

```bash
./scripts/repair-cursor.sh --full
```

```powershell
.\scripts\repair-cursor.ps1 -Full
```

This also clears `workspaceStorage` / History (local chats/tabs reset). A backup is saved under `Cursor/repair-backup-*`.

## What the repair does

| Step | Safe | Full |
|------|------|------|
| Force-quit Cursor | ✓ | ✓ |
| Disable hardware acceleration (`argv.json`) | ✓ | ✓ |
| Set `use-angle: gl` | ✓ | ✓ |
| Clear GPU / Code / Dawn / Shader / Service Worker caches | ✓ | ✓ |
| Clear Local + Session Storage | ✓ | ✓ |
| Remove corrupted layout keys from `state.vscdb` | ✓ | ✓ |
| Wipe `workspaceStorage` + History | | ✓ |

## After repair

1. Open Cursor
2. Start a **new** chat (old corrupted chats can keep spawning bad popups)
3. Avoid **Open Chat as Editor** for now
4. If needed: reinstall from https://cursor.com/download
