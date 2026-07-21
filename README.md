# NASEN — Mobile Site Audit

One-page phone-first audit of [nasen.org](https://nasen.org/), built from `Templateindex.html` using NASEN brand colors (cyan / teal / orange) and Cervo + Open Sans.

## Contact

NASEN Buyers Club: **(253) 213-3221** · [buyersclub@nasen.org](mailto:buyersclub@nasen.org)

## Files

- `index.html` — Audit page (findings + before/after + contact)
- `Templateindex.html` — Original proposal template
- `assets/nasen-mobile-home.png` — Live capture at 390×844
- `scripts/` — Cursor corrupted-popup / blank UI repair helpers

## Download

Grab **[nasen-mobile-audit.zip](nasen-mobile-audit.zip)** — includes `index.html`, template, and assets.

Unzip, then open `index.html` in a browser (or serve the folder):

```bash
unzip nasen-mobile-audit.zip
cd nasen-mobile-audit
python3 -m http.server 8765
# then visit http://localhost:8765/
```

## Cursor repair

If Cursor shows corrupted / garbled popups or a blank UI, quit Cursor and run:

- **Windows:** double-click `scripts/repair-cursor.cmd`
- **macOS:** double-click `scripts/repair-cursor.command`
- **Linux:** `./scripts/repair-cursor.sh`

Details: [`scripts/REPAIR-CURSOR.md`](scripts/REPAIR-CURSOR.md)
