# NASEN Mobile Audit — Organized Brief

**Prepared by:** Flux Labs Agency LLC ([fluxlab.agency](https://fluxlab.agency/))  
**Prospect:** North American Syringe Exchange Network ([nasen.org](https://nasen.org/))  
**Checked:** July 2026 · phone-first (390×844 live capture)  
**Interactive page:** [`index.html`](index.html)

---

## Snapshot

People look up syringe services on phones. On mobile, nasen.org currently fights that mission.

| Signal | Live finding |
| --- | --- |
| **555px** | `#map` forced with `!h-[555px]` — blank hole when tiles lag |
| **0** | City / state hidden on phone (`.cityCol` / `.stateCol` ≤549px) |
| **587** | Directory rows dumped with no pagination |

Brand assets are strong (cyan `#4ac3e4`, teal `#06597A`, orange `#f36b21`, lime `#cac950`, Cervo, paper texture). The layout is what needs rebuilding.

---

## Findings → Flux Labs work

### 1 · Hero that fits the phone — Critical
- **Today:** `whitespace-nowrap` on “A DAVE PURCHASE PROJECT INITIATIVE”; stacked cyan title boxes.
- **Upgraded:** One headline; subtitle wraps; brand cyan stays.
- **We build:** Custom mobile UI — preserve NASEN brand, rewrite the first screen.

### 2 · Map without the dead space — Critical
- **Today:** Map locked at 555px; heavy filter grid; list shows names without place.
- **Upgraded:** ~280px lazy-loaded map; “Find programs near me”; city/state visible.
- **We build:** Performance + Maps engineering — phone-first map UX, secured API key.

### 3 · Directory with city & state — High
- **Today:** CSS hides `.cityCol` / `.stateCol` on small screens.
- **Upgraded:** Mobile cards with name + place + type; desktop keeps sortable table.
- **We build:** Directory UX redesign.

### 4 · Speed, counts & clean stack — High
- **Today:** 587 rows at once; legend counts disagree with filters; “Mail-based Serices”; duplicate Bootstrap; Maps key in page source.
- **Upgraded:** Paginated list; one data source for legend + filters; one CSS system.
- **We build:** Technical SEO + performance cleanup.

### 5 · Access, trust & follow-through — Med
- **Today:** Extra tabindex, missing alt, `/about` → 404, exposed Maps key.
- **Upgraded:** Natural keyboard order, real menu, alt text, working routes, restricted key.
- **We build:** Accessibility pass + optional Flux Ops inquiry routing.

---

## What Flux Labs can deliver

| Lane | Offer for NASEN |
| --- | --- |
| **Websites** | Phone-first custom rebuild — keep brand, fix hero / filters / map / directory |
| **SEO** | Findability & technical cleanup — routes, headings, alt, data honesty |
| **Flux Ops** | Missed-call / inquiry automation so Buyers Club & directory leads don’t go cold |
| **Strategy** | Founder-led diagnose → fix → optimize (21-day delivery where scope fits) |

### Recommended first sprint
1. Unwrap hero + collapse stacked titles  
2. Kill `!h-[555px]`, lazy-load Maps, lock the key  
3. Show city/state on every mobile row  
4. Paginate 587 rows, sync counts, dedupe CSS, a11y pass  
5. Optional: Flux Ops routing for Buyers Club / directory

---

## Contact

**Flux Labs**  
- Jonathan Augusto · Founder & CEO  
- [(772) 867-4562](tel:+17728674562)  
- [contact@fluxlab.agency](mailto:contact@fluxlab.agency)  
- [fluxlab.agency](https://fluxlab.agency/)

**NASEN Buyers Club** (coordination)  
- [(253) 213-3221](tel:+12532133221) · [buyersclub@nasen.org](mailto:buyersclub@nasen.org)

---

## Files in this repo

| File | Role |
| --- | --- |
| `AUDIT.md` | This organized brief |
| `index.html` | Interactive proposal (before/after phone mocks) |
| `nasen-mobile-audit.zip` | Downloadable package |
| `assets/nasen-mobile-home.png` | Live phone capture |
| `Templateindex.html` | Original proposal template |
| `scripts/` | Cursor repair helpers |
