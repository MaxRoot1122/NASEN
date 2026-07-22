# Nasen
# NASEN × Flux Labs — Mobile Site Audit & Proposal

Phone-first audit of [nasen.org](https://nasen.org/) prepared by [Flux Labs](https://fluxlab.agency/) — findings mapped to custom website rebuild, SEO/performance cleanup, and Flux Ops automation.

Uses the live NASEN colorway (cyan `#4ac3e4`, teal `#06597A`, orange `#f36b21`, lime `#cac950`), paper texture, chevron pattern, and Cervo + Open Sans.

## Contact

- **Flux Labs:** [(772) 867-4562](tel:+17728674562) · [contact@fluxlab.agency](mailto:contact@fluxlab.agency) · [fluxlab.agency](https://fluxlab.agency/)
- **NASEN Buyers Club:** [(253) 213-3221](tel:+12532133221) · [buyersclub@nasen.org](mailto:buyersclub@nasen.org)

## Files

- `index.html` — Audit + Flux Labs service proposal (findings → service lanes)
- `Templateindex.html` — Original proposal template
- `assets/nasen-mobile-home.png` — Live capture at 390×844
- `scripts/` — Cursor corrupted-popup / blank UI repair helpers

## Download

Grab **[nasen-mobile-audit.zip](nasen-mobile-audit.zip)** — includes `index.html`, template, and assets.

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
