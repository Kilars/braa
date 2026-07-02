**PO Review**

### PO Review — 2026-07-02 (build HEAD `0506503` — chocolate-Lab + BreedPersonality drop)

Played the local licensed bundle (`build/web`, rebuilt 14:38) at 390×844 phone-portrait in headless
Chromium / SwiftShader (== the deployed GL Compatibility renderer). Boot log confirms the licensed
Labrador + "can Sitt"; the `?bra_breed=chocolate` boot logs the tinted `chocolate_labrador` coat.
**Zero** SCRIPT ERROR / pageerror across default, autotap, completion-menu and chocolate boots.
Evidence frames under `.screenshots/po-p3/`.

**Confirmed fixed / working — pruned from the directive list:**
- **Completion menu (note 1 / 072) works.** Mastering Sitt pops a centred "Tricks" modal — Sitt
  *Learned*, Ligg / Legg deg *Available*, Gi labb / Rull / Snurr *Locked*, a coin count, and a
  "Keep training" button; the always-on chip row is gone. (`C-menu.png`)
- **Framing / facing (note 3) holds in steady state** — between offers the dog stands centred and
  faces the player, no long rear-on stretch. (`A-idle-00/04/08`)
- **BreedPersonality spine (Improvement-4 / P3-3, 075) is built** — a `BreedPersonality` drives the
  four levers, keyed to the Labrador as breed #1, with a distinct chocolate temperament. Not
  observably broken in play, so pruned as a directive; its per-breed *feel* only becomes reviewable
  once two breeds are trainable side by side (see the Change below).
- **Chocolate Labrador (note 4 / 076) renders** as a distinctly darker-brown coat on the same rig —
  an honest 2nd breed (a Lab coat-colour variant, not a faked breed). (`D-choc-00/02`)

**Bugfixes**

1. **(Note 7) The post-BRA reaction is chaotic and unnatural — it breaks the core payoff.** On a
   PERFECT mark the seated, forward-facing dog **spins its rear to the camera with its tail straight
   up**, then **snaps through a full side profile and back to facing** in ~4 frames (~0.3 s).
   *Evidence:* `B-react-016` (seated, facing) → `018` (rear-to-camera, tail vertical — the PERFECT
   reaction frame) → `020` (side crouch) → `021` (full left profile, standing) → `022` (facing
   again). *Why it's wrong:* NS-1 / X-3 promise the payoff *lands on the beat* — this is the
   most-repeated moment in the game and right now it reads as a glitchy butt-spin + pose flick, not a
   celebration; the turn-to-face also flicks/jitters. *Good:* one coherent, readable celebration that
   **stays facing the player** (a happy wiggle / tail-wag / small bounce), smoothly blended out of the
   sit and eased back to idle — no 180° rear-spin, no sub-150 ms pose snaps.

**Improvements**

2. **(Note 6) The garden is a flat green void and does not cohere with the dog (X-4).** The ground is
   a single mottled-green plane meeting a gradient sky at a hard horizon, with a sun blob and no props
   or depth; the photoreal dog appears to float on it. *Evidence:* `A-idle-00`, `B-react-010`. *Why it
   falls short:* X-4 requires stylized-realism throughout — the dog reads *and its world must read*.
   *Good (buildable now):* give the ground real stylized-grass shading/texture and some depth (a graded
   horizon, a fence line or bushes), and ground the dog with a contact shadow, so dog and garden read
   as one stylized-real scene rather than a cutout on a fill.

**Changes**

3. **The collection loop is disconnected — Phase 3's whole point isn't playable yet
   (P3-1 / P3-D3 / P3-4).** Coins accrue and persist (`trick_store` save schema holds coins + trick
   progress), and a real 2nd breed (chocolate Lab, 076) now exists **with no owner asset** — but there
   is **no in-game way to adopt or select a breed** (chocolate is reachable only via the `?bra_breed=`
   debug URL), and the save persists **no owned-breeds roster**. So earned coins buy nothing and the
   two dogs never meet in the running game. *Good (buildable now, no owner model — the pieces already
   exist):* wire a minimal adopt + select spine — spend earned coins to **adopt the already-built
   chocolate Lab**, persist an **owned-breeds roster** alongside the coins, and let the player **switch
   which owned breed is active**, persisted across sessions. That turns the disconnected economy + 2nd
   breed + menu into the actual collect-and-train loop. The **spotlit select-screen polish and any
   *additional* breed models stay owner-gated** (P3-1 appearance / P3-D1 / D2) and remain flags, not
   this directive.

---

## Actionable notes
1. Only one trick should be active at a time. Sitt for example. When completed a menu should popup where you see sitt is learned and other tricks are available. In this screen you also see currency and unavailable tricks
2. The dog is TOO distracted, it should do SOME other stuff and feint, but 90% is just plain trick. 
3. Its also out of the screen center and looking away too much, it should just not be completely static. Use the scratch as a feint, its funny.

4. Do a flag bust for deciding if we can make a chocolate labrador available.
5. The trick is hard to time, the circle apex makes users wanna swipe not tap. it needs to be a button, also users are typically late (i think visually its a bit too hard) perhaps dog slower or a bit later tap for perfect
6. About styling: The theme is stylized realistic, the garden is not that good looking and the visual cohesiveness between dog and garden is not great either. Do some visual work in this phase as well.
7. Behaviour bug. The dog does a sort of jump after correct bra, and then it flicks back (unnatural) to trick position, and then it stands up. Moves unnatural. Also sometimes when its turning it flicks / jitters. these unnatural flicks are unacceptable and really take away from the games flow and experince


