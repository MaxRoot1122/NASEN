#!/bin/bash
# Double-click this in Finder (macOS) to repair Cursor.
cd "$(dirname "$0")/.."
chmod +x scripts/repair-cursor.sh
./scripts/repair-cursor.sh
echo ""
read -r -p "Press Enter to close…"
