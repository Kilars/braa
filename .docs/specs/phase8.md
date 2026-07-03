## Phase 8 — Kennel (browse-and-adopt roster)

**Goal:** a dedicated **kennel screen** where the player browses every dog, inspects its breed /
stats / unique trait, and **adopts one with coins** to choose who they train. It turns the Phase-3
economy + roster spine into a real place, styled as a clean, clinical steel kennel
(«Stålkennelen», direction 2b).

> **Builds on Phase 3** (breeds, coins, owned-roster, switch-active-dog) and the **Phase 6 design
> system**. The kennel is a *browse-and-adopt roster, **not** a second game* — active timing stays
> the only skill engine (Non-Goals): no auto-training, no idle income, no timers here. Runtime:
> Godot-native `Control` HUD, no DOM (ADR-0001), portrait phone only (X-1), Norwegian copy. Every
> story is gated like the rest of the spec — **TDD for logic, Visual Review for the look (X-6)**.
> Source of truth for the look: the `Kennel_Style__Godot_Handoff` hand-off (option 2b) + the
> `Bra Design System` (Phase 6). This spec freezes intent + values; it is **not pixel gospel**.

### Player stories (role: player, unless noted)

- **K-0 — Scope of the kennel.**
  *As the product owner, I want the kennel to be a browse-and-adopt roster, not a second game, so
  that active timing stays the only skill engine (Non-Goals).*
  Acceptance:
  - The kennel **lists** dogs, shows their info, and lets you **adopt** one with coins. Nothing
    more — no auto-training, no idle income, no timers running here.
  - Adopting changes *which* dog you train; it never replaces the training loop.

- **K-1 — Browse the roster.**
  *As a player, I want to see all the dogs waiting in the kennel at a glance, so that I can decide
  who I want next.*
  Acceptance:
  - All 8 dogs render as barred white cells in a 2-column scrolling grid.
  - Each cell reads at a glance: dog render, name, breed, price, and status tag — no tap required
    to tell them apart.
  - The already-owned dog is visibly distinct (green «Din hund» tag, «Din» price) and never
    purchasable.

- **K-2 — Inspect a dog.**
  *As a player, I want to tap a dog and see its breed, stats and unique trait, so that I can judge
  whether it's worth adopting.*
  Acceptance:
  - Tapping a cell opens the detail modal with: blurb, 4 stat bars (Læreevne · Energi · Mot ·
    Fokus), raseegenskaper chips, and the one Unikt trekk.
  - Tapping outside the card or the ✕ closes it; the grid scroll position is preserved.
  - Opening/closing is smooth and reduced-motion is respected (X-5).

- **K-3 — See what I can afford.**
  *As a player, I want my coin balance and each dog's price always visible, so that I know what's
  within reach before I commit.*
  Acceptance:
  - The coin chip in the header shows the live balance at all times.
  - Every buyable cell shows its price; the adopt button in the modal reads «Adopter · N mynt».
  - When coins < price, the adopt button is visibly disabled (dim, non-tappable) — no error state,
    it just can't be pressed.

- **K-4 — Adopt a dog.**
  *As a player, I want to spend coins to adopt a dog I can afford, so that I can train someone new.*
  Acceptance:
  - Pressing an enabled adopt button deducts the price, marks the dog owned, and gives clear
    positive feedback (coin count-down + a small celebratory beat).
  - An owned dog's cell/button flips to the owned treatment; the button now reads «Tren med [navn]».
  - Adoption is **test-first** (X-6): balance math, the affordability gate, and the owned-state
    transition are covered before the UI is wired.
  - You can't double-spend: an in-flight adopt can't fire twice.

- **K-5 — Switch which dog I train.**
  *As a player, I want to send an owned dog to the training scene, so that the kennel actually
  feeds into the core loop.*
  Acceptance:
  - «Tren med [navn]» on an owned dog sets it as the active dog and returns to the training scene
    with that dog loaded.
  - The training scene's model/stats reflect the chosen dog (ties into the breeds work, Phase 3).
  - The active dog persists across a reload (see K-7).

- **K-6 — Find the hidden dog.**
  *As a player, I want a surprise easter-egg dog in the kennel, so that browsing feels rewarding.*
  Acceptance:
  - Trulte (Malchi) appears with a «★ Påskeegg» coral tag and a «Gratis» price.
  - Her modal shows the coral ribbon and the «Adopter gratis ♥» button; adopting her costs nothing.
  - She's discoverable by browsing — no external hint required — and reads as special, not broken.

- **K-7 — It's remembered & offline.**
  *As a player, I want my coins, owned dogs and active dog saved locally with no network, so that
  my kennel is the same when I come back — even on a plane (X-7).*
  Acceptance:
  - Balance, the owned set, and the active dog persist to Godot `user://` (IndexedDB-backed on web);
    no backend, no account.
  - After first load the kennel works fully offline; nothing here blocks on a request.

- **K-8 — Breeds bring their own tricks.**
  *As a player, I want each breed to have its own set of trainable tricks, so that **which** dog I
  adopt changes **what I can train**, not just how it looks.*
  Acceptance:
  - Each breed exposes a **distinct trick list** — a shared core (Sitt / Ligg / Legg deg) plus
    breed-specific tricks — so no two breeds train identically. (Extends **P3-2**, "Breeds bring
    different tricks".)
  - The kennel detail modal (K-2) shows **which tricks a breed can learn** before you adopt, so the
    trick list is part of the adoption decision.
  - In the training scene a dog can only train its own breed's available tricks; the trick menu
    reflects the active breed's list.
  - Availability is **content/asset-gated**: a breed only offers a trick its rig actually has a
    clean clip for (grep the manifest, never the running game — behaviour ≠ inventory). A trick a
    breed can't perform is simply not offered, never faked.

### Visual spec (condensed — look-and-feel, not pixel gospel)

- **The idea.** A bright, sterile, modern boarding kennel: 8 dogs behind thin steel bars in clean
  white cells, 2-column grid, cool light, no cosiness — reads as *professional* and a little «synd
  på». Same Pokémon-GO stylized-realism as training (X-4), but the kennel skin is deliberately
  **cool + clinical** (white / steel-grey, matte, thin metal). Warmth lives only in the dogs, the
  gold coin, and the one Unikt-trekk card.
- **Screen anatomy (top→bottom).** (1) fixed **header** — title «Kennelen» + subtitle «Profesjonell
  fasilitet · 8 plasser», coin chip right; (2) scrolling **kennel grid** — 2 columns of barred
  white cells; (3) **detail modal** overlay on tap — centered card over a dimmed, blurred backdrop.
  Ship target 390 × 844 portrait; treat every px as proportional.
- **Palette (approved).** Panel `#f4f6f8 → #e5eaee`, cell `#ffffff`, hairline `#dde3e8`, steel bar
  `#788794` @ 32–40%, modal surface `#fbfbf7`; ink `#2b3742` / muted `#9aa6b0`; brand blue `#4a90e2`
  / `#2f6fbf`; coin gold `#f5b841` / `#d99a2b`; easter coral `#ff7a85`. Rarity accent (drives price
  colour): owned `#57b85c`, common `#b7c1cb`, rare `#4a90e2`, epic gold gradient, secret coral
  gradient. Fonts: display **Baloo 2** (names/numerals/titles/buttons), UI/body **Nunito**.
- **The kennel cell.** White `StyleBoxFlat` card, radius 16, soft neutral shadow + 1.5px inset
  hairline. Top **portrait band** (~112px) = per-dog tinted bg with the dog render bottom-anchored,
  behind thin **steel bars** (~2px on ~29px pitch, `#788794` @ ~40%, + a 2px inset steel frame).
  **Status tag** top-left (normal «N dager her» / owned «Din hund» green / easter «★ Påskeegg»
  coral); **price chip** bottom-right (gold buyable / green «Din» / coral «Gratis»). **Footer**:
  name (Baloo 2 700) + breed (Nunito 700 muted). Pressed: gentle scale-down; whole cell is the hit
  target.
- **Detail modal + stat panel.** Centered card over `rgba(20,28,38,.5)` + ~3px blur; radius 24,
  surface `#fbfbf7`. Header image (~150px, same tint + bars). Then: blurb (one warm line) · 4 stat
  rows with 5 pips each (filled `#4a90e2`, empty `#dfe5ea`) · Raseegenskaper chips · the warm-cream
  **Unikt trekk** card · full-width **adopt button** (blue «Adopter · N mynt» / green «Tren med …» /
  coral «Adopter gratis ♥»; dim when unaffordable). Easter dog gets a coral ribbon above the stats.
- **Motion (respect X-5).** Cells pop in (small scale-up + fade, lightly staggered); modal backdrop
  fades (~0.2s), card scales from 0.96 with slight overshoot (~0.32s); coin count-down + pulse on a
  completed purchase.
- **Godot notes.** Scene root `Control` filling the portrait safe area; header `HBoxContainer`; grid
  `ScrollContainer › GridContainer(columns=2)`. Cell = one reusable `Button`/`PanelContainer` scene
  instanced per dog, fed a dog `Resource` (name/breed/stats/rarity/price/tint/trick-list). Steel
  bars = one reused shader (repeating stripes + inset frame, tint alpha in a uniform). Portrait =
  baked `Texture2D` per breed in-grid for perf (X-7), live `SubViewport` allowed in the modal.
  Modal = `CanvasLayer`/`Popup` + dim backdrop + `Tween`ed card. State (coins / owned set / active
  dog) rides the existing Phase-3 save (`TrickStore`/`BreedRoster` on `user://`, X-7) — do **not**
  add a parallel store. Fonts set in the theme, not per-node.

### The 8 dogs

Stats are [Læreevne, Energi, Mot, Fokus], 1–5. Per-dog portrait tint drives the cell band bg.

| Dog | Breed | Rarity | Price | Stats | Unikt trekk |
|-----|-------|--------|-------|-------|-------------|
| Bella | Labrador retriever | Din (owned) | — | 4·3·4·3 | Godbit-radar |
| Nova | Border collie | Episk | 900 | 5·5·4·5 | Øyet |
| Balder | Schäferhund | Sjelden | 650 | 4·4·5·4 | Vaktpost |
| Sol | Golden retriever | Sjelden | 500 | 4·3·4·3 | Alles venn |
| Pontus | Gravhund | Vanlig | 350 | 2·3·4·2 | Gravemaskin |
| Lykke | Spisshund | Vanlig | 300 | 3·4·3·2 | Alarmen |
| Sniff | Beagle | Vanlig | 320 | 3·4·3·2 | Nesa styrer |
| Trulte ★ | Malchi | Hemmelig | Gratis | 3·2·1·2 | Skjelver som et aspeløv |

Tints: Bella real-blue, Nova `#4c525b`, Balder `#a97f4f`, Sol `#e2bd76`, Pontus `#875636`, Lykke
`#e0a45f`, Sniff `#c1955e`, Trulte `#e6dccb`.

> **Asset note (not a spec waiver):** breed rig/clip coverage is a **build** concern, busted against
> the licensed manifest, never asserted owner-gated from the running game (behaviour ≠ inventory).
> A breed whose model/clips genuinely aren't available narrows to a flag; every buildable slice
> (recolor breeds à la the chocolate Lab, shared-core tricks) ships first.

### Acceptance (Visual Review, per X-6)

On 390 × 844 portrait: the kennel reads as a clean, cool, professional facility — white cells, thin
steel bars, no warm surfaces except the coin, the dogs, and the Unikt-trekk card. All 8 dogs legible
at a glance; tapping any opens a smooth, closable modal with the full stat panel; coin balance and
prices always visible; the affordability gate + adopt/switch flows behave per K-3–K-5 and are covered
test-first; owned/easter states render distinctly; each breed's trick list is visible before adopt
(K-8); the whole screen works offline after first load (X-7). The `polish` pass has been run and
independent review confirms it on the running build.
