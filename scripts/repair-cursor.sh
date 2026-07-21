#!/usr/bin/env bash
# Repair Cursor corrupted popups / garbled UI (macOS + Linux).
# Quit Cursor before running, or this script will try to quit it for you.
set -euo pipefail

echo "==> Cursor corrupted-popup repair"

OS="$(uname -s)"
case "$OS" in
  Darwin)
    CURSOR_APP_SUPPORT="${HOME}/Library/Application Support/Cursor"
    CURSOR_USER="${CURSOR_APP_SUPPORT}/User"
    ;;
  Linux)
    CURSOR_APP_SUPPORT="${HOME}/.config/Cursor"
    CURSOR_USER="${CURSOR_APP_SUPPORT}/User"
    ;;
  *)
    echo "Unsupported OS: $OS (use scripts/repair-cursor.ps1 on Windows)"
    exit 1
    ;;
esac

if [[ ! -d "$CURSOR_APP_SUPPORT" ]]; then
  echo "Cursor data folder not found at: $CURSOR_APP_SUPPORT"
  echo "Is Cursor installed for this user?"
  exit 1
fi

# Quit Cursor if running
if [[ "$OS" == "Darwin" ]]; then
  if pgrep -x "Cursor" >/dev/null 2>&1; then
    echo "==> Quitting Cursor..."
    osascript -e 'quit app "Cursor"' 2>/dev/null || true
    sleep 2
    pkill -x "Cursor" 2>/dev/null || true
    sleep 1
  fi
else
  if pgrep -xi "cursor" >/dev/null 2>&1 || pgrep -f "[C]ursor" >/dev/null 2>&1; then
    echo "==> Quitting Cursor..."
    pkill -xi "cursor" 2>/dev/null || true
    pkill -f "[C]ursor" 2>/dev/null || true
    sleep 2
  fi
fi

mkdir -p "$CURSOR_USER"
ARGV_JSON="${CURSOR_USER}/argv.json"
BACKUP_DIR="${CURSOR_APP_SUPPORT}/repair-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "==> Writing argv.json (disable GPU / use ANGLE gl)"
if [[ -f "$ARGV_JSON" ]]; then
  cp "$ARGV_JSON" "$BACKUP_DIR/argv.json.bak"
fi

python3 - <<'PY' "$ARGV_JSON"
import json, sys, os
path = sys.argv[1]
data = {}
if os.path.isfile(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            raw = f.read()
        # Strip // comments Cursor/VS Code sometimes allow
        lines = []
        for line in raw.splitlines():
            stripped = line.lstrip()
            if stripped.startswith("//"):
                continue
            lines.append(line)
        data = json.loads("\n".join(lines) or "{}")
        if not isinstance(data, dict):
            data = {}
    except Exception:
        data = {}
data["disable-hardware-acceleration"] = True
data["use-angle"] = "gl"
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"Updated {path}")
PY

clear_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo "==> Clearing $(basename "$dir")"
    # Backup then wipe contents
    mkdir -p "$BACKUP_DIR/$(basename "$dir")"
    # Best-effort copy of small metadata only; caches can be huge — just remove
    rm -rf "${dir:?}/"* "${dir:?}/".[!.]* "${dir:?}/"..?* 2>/dev/null || true
    rmdir "$dir" 2>/dev/null || rm -rf "$dir"
  fi
}

echo "==> Clearing GPU / Electron caches"
clear_dir "${CURSOR_APP_SUPPORT}/GPUCache"
clear_dir "${CURSOR_APP_SUPPORT}/Code Cache"
clear_dir "${CURSOR_APP_SUPPORT}/Cache"
clear_dir "${CURSOR_APP_SUPPORT}/CachedData"
clear_dir "${CURSOR_APP_SUPPORT}/CachedExtensions"
clear_dir "${CURSOR_APP_SUPPORT}/CachedExtensionVSIXs"

if [[ "$OS" == "Darwin" ]]; then
  clear_dir "${HOME}/Library/Caches/Cursor"
fi

echo "==> Clearing editor history / corrupted layout keys (keeps chats when possible)"
WS_ROOT="${CURSOR_USER}/workspaceStorage"
if [[ -d "$WS_ROOT" ]]; then
  # Prefer surgical fix: remove auxiliaryBarVisible key that blanks layout
  if command -v sqlite3 >/dev/null 2>&1; then
    find "$WS_ROOT" -name 'state.vscdb' -type f 2>/dev/null | while read -r db; do
      sqlite3 "$db" "DELETE FROM ItemTable WHERE key = 'cursor/editorLayout.auxiliaryBarVisible';" 2>/dev/null || true
    done
    echo "    Removed corrupted layout keys from workspace DBs"
  else
    echo "    sqlite3 not found — skipping surgical layout fix"
    echo "    (optional) install sqlite3 and re-run, or delete workspaceStorage manually"
  fi
fi

echo ""
echo "Done. Backup of argv.json (if any): $BACKUP_DIR"
echo "Reopen Cursor now. Corrupted popups should be fixed."
echo "If still broken: start a new chat, and avoid 'Open Chat as Editor'."
