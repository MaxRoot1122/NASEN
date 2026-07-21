#!/usr/bin/env bash
# Full Cursor repair for macOS + Linux.
# Fixes corrupted popups, blank UI, GPU glitches, and bad workspace layout state.
#
# Usage:
#   ./scripts/repair-cursor.sh          # safe repair (recommended)
#   ./scripts/repair-cursor.sh --full   # also wipe workspaceStorage / heavier state
#
# Quit Cursor before running (script will force-quit if needed).
set -euo pipefail

FULL=0
for arg in "$@"; do
  case "$arg" in
    --full|-f) FULL=1 ;;
    --help|-h)
      echo "Usage: $0 [--full]"
      echo "  --full  Also clear workspaceStorage, History, Local/Session Storage"
      exit 0
      ;;
  esac
done

echo "==> Cursor full repair (mode: $([[ $FULL -eq 1 ]] && echo FULL || echo SAFE))"

OS="$(uname -s)"
case "$OS" in
  Darwin)
    CURSOR_APP_SUPPORT="${HOME}/Library/Application Support/Cursor"
    CURSOR_USER="${CURSOR_APP_SUPPORT}/User"
    CURSOR_CACHES=("${HOME}/Library/Caches/Cursor")
    # Optional todesktop caches (may not exist)
    shopt -s nullglob
    for p in "${HOME}/Library/Caches/com.todesktop."*; do
      CURSOR_CACHES+=("$p")
    done
    shopt -u nullglob
    ;;
  Linux)
    CURSOR_APP_SUPPORT="${HOME}/.config/Cursor"
    CURSOR_USER="${CURSOR_APP_SUPPORT}/User"
    CURSOR_CACHES=("${HOME}/.cache/Cursor" "${HOME}/.cache/cursor")
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
SETTINGS_JSON="${CURSOR_USER}/settings.json"
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
        lines = []
        for line in raw.splitlines():
            if line.lstrip().startswith("//"):
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

echo "==> Ensuring settings.json GPU-safe defaults"
if [[ -f "$SETTINGS_JSON" ]]; then
  cp "$SETTINGS_JSON" "$BACKUP_DIR/settings.json.bak"
fi
python3 - <<'PY' "$SETTINGS_JSON"
import json, sys, os
path = sys.argv[1]
data = {}
if os.path.isfile(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            raw = f.read()
        lines = []
        for line in raw.splitlines():
            if line.lstrip().startswith("//"):
                continue
            lines.append(line)
        data = json.loads("\n".join(lines) or "{}")
        if not isinstance(data, dict):
            data = {}
    except Exception:
        data = {}
# Prefer Stable over Early Access for fewer UI regressions
data.setdefault("update.mode", "default")
data["window.titleBarStyle"] = data.get("window.titleBarStyle", "custom")
# Reduce animation/GPU compositing stress that can corrupt overlays
data.setdefault("window.commandCenter", True)
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"Updated {path}")
PY

clear_path() {
  local target="$1"
  # shellcheck disable=SC2086
  for path in $target; do
    if [[ -e "$path" ]]; then
      echo "==> Clearing $(basename "$path")"
      rm -rf "$path"
    fi
  done
}

echo "==> Clearing GPU / Electron / Chromium caches"
CACHE_NAMES=(
  GPUCache
  "Code Cache"
  Cache
  CachedData
  CachedExtensions
  CachedExtensionVSIXs
  CachedProfilesData
  DawnGraphiteCache
  DawnWebGPUCache
  ShaderCache
  "Service Worker"
  "Local Storage"
  "Session Storage"
  "Shared Dictionary"
  blob_storage
  Crashpad
  "Crash Reports"
  VideoDecodeStats
  WebStorage
  logs
)

for name in "${CACHE_NAMES[@]}"; do
  clear_path "${CURSOR_APP_SUPPORT}/${name}"
done

for cache in "${CURSOR_CACHES[@]}"; do
  clear_path "$cache"
done

echo "==> Repairing corrupted workspace layout keys (keeps chats)"
WS_ROOT="${CURSOR_USER}/workspaceStorage"
GLOBAL_ROOT="${CURSOR_USER}/globalStorage"
LAYOUT_KEYS=(
  "cursor/editorLayout.auxiliaryBarVisible"
  "workbench.auxiliaryBar.hidden"
  "workbench.panel.hidden"
)

if command -v sqlite3 >/dev/null 2>&1; then
  if [[ -d "$WS_ROOT" ]]; then
    while IFS= read -r -d '' db; do
      for key in "${LAYOUT_KEYS[@]}"; do
        sqlite3 "$db" "DELETE FROM ItemTable WHERE key = '$key';" 2>/dev/null || true
      done
      # Drop backup DBs that can re-corrupt on restore
      rm -f "${db}.backup" "${db}-wal" "${db}-shm" 2>/dev/null || true
    done < <(find "$WS_ROOT" -name 'state.vscdb' -type f -print0 2>/dev/null)
    echo "    Cleaned workspace state.vscdb files"
  fi
  if [[ -d "$GLOBAL_ROOT" ]]; then
    while IFS= read -r -d '' db; do
      for key in "${LAYOUT_KEYS[@]}"; do
        sqlite3 "$db" "DELETE FROM ItemTable WHERE key = '$key';" 2>/dev/null || true
      done
      rm -f "${db}.backup" "${db}-wal" "${db}-shm" 2>/dev/null || true
    done < <(find "$GLOBAL_ROOT" -name 'state.vscdb' -type f -print0 2>/dev/null)
    echo "    Cleaned globalStorage state.vscdb files"
  fi
else
  echo "    sqlite3 not found — install it for surgical DB repair, or re-run with --full"
fi

if [[ $FULL -eq 1 ]]; then
  echo "==> FULL mode: clearing workspaceStorage, History, and sticky UI state"
  echo "    WARNING: local chat history / open tabs for projects will be reset"
  if [[ -d "$WS_ROOT" ]]; then
    cp -a "$WS_ROOT" "$BACKUP_DIR/workspaceStorage.bak" 2>/dev/null || true
    clear_path "$WS_ROOT"
  fi
  clear_path "${CURSOR_USER}/History"
  clear_path "${CURSOR_USER}/globalStorage/storage.json"
  # Sticky editor/composer layout files
  find "$CURSOR_USER" -maxdepth 2 -name '*.vscdb.backup' -delete 2>/dev/null || true
fi

# Write a small marker so user can confirm repair ran
cat > "${CURSOR_USER}/.cursor-repair-stamp" <<EOF
repairedAt=$(date -u +%Y-%m-%dT%H:%M:%SZ)
mode=$([[ $FULL -eq 1 ]] && echo full || echo safe)
backup=$BACKUP_DIR
EOF

echo ""
echo "Repair complete."
echo "Backup: $BACKUP_DIR"
echo "Reopen Cursor now."
echo ""
echo "After reopen:"
echo "  1. Start a NEW chat (old corrupted chats can keep spawning bad popups)"
echo "  2. Avoid 'Open Chat as Editor' for now"
echo "  3. If still broken, re-run: $0 --full"
echo "  4. Last resort: reinstall from https://cursor.com/download"
