# OSRS-Inspired Skilling Integration

## OSRS-Inspired Skilling Integration

“OSRS-inspired” is not nostalgia. It’s a set of constraints.

It makes progression feel permanent, legible, and social.

It also keeps the economy fair by making power predictable.

Canon anchors:

* XP curve + Total Level gates: [5 - RPG Skilling System](../5-rpg-skilling-system/)
* Macro economy surfaces: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md)
* UI level-up beats: [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md)

***

### What “OSRS-inspired” means in Relic Vault

#### 1) Action-based XP (not time-based)

XP comes from validated actions:

* **Excavation**: manual extracts + auto ticks
* **Restoration**: sift attempts (success + pity XP on fail)
* **Appraisal**: market participation (listing/bid/win/certify)
* **Smelting**: smelt actions and bulk smelts

Spec: [5 - RPG Skilling System](../5-rpg-skilling-system/).

#### 2) Long-tail level curve (99 matters)

The curve must:

* feel fast early,
* feel grindy mid,
* feel prestigious late.

Relic Vault uses the canonical OSRS curve model.

Spec: [5 - RPG Skilling System](../5-rpg-skilling-system/).

#### 3) Milestones are shared language (keep thresholds consistent)

Use these thresholds everywhere:

* Level `60+`: “advanced skilling starts” (ability + branch pick)
* `80/80`: pair masteries (synergy perks)
* All skills `90+`: total mastery (**Senior Researcher**)
* Level `99`: mastery moment + global broadcast

#### 4) Visible identity beats (social proof)

OSRS works because levels are public receipts.

Relic Vault must mirror that:

* Level-up banner text (big and loud).
* Level `99` broadcast in the global feed.
* Permanent mastery badges visible in Bazaar and Museum rows.

UI anchor: [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md).

***

### How skilling integrates with the macro loop

Skills must create **specialization**, not solo dominance.

#### Appraisal (merchant / trust)

Appraisal is the economy gate.

It unlocks:

* Certification (trust + disclosure).
* Fee/tax edges at mastery.
* Visibility spikes (Hype Train).

Appraisal must never change loot RNG.

Spec: [Appraisal](../5-rpg-skilling-system/appraisal.md).

#### Restoration (high-stakes viability)

Restoration is what makes Stage 3–5 play realistic over time.

It improves:

* Stability (flat, visible bonus per level).
* Failure mitigation (Emergency Glue on Standard Fail only).
* Mastery identity + explicit HV edge.

Spec: [Restoration](../5-rpg-skilling-system/restoration.md).

#### Excavation (supply / throughput)

Excavation is the supplier role.

It improves:

* crate chance scaling (flat + clamped),
* timing skill (Seismic Surge),
* zone planning (Heatmap Survey mitigation).

Spec: [Excavation](../5-rpg-skilling-system/excavation.md).

#### Smelting (cleanup / inflation control)

Smelting is a throughput loop.

It provides:

* deterministic Scrap conversion,
* bulk processing,
* endgame junk yield dominance.

Spec: [Smelting](../5-rpg-skilling-system/smelting.md).

***

### Total Level and content gates (OSRS-style “account power”)

Total Level is the sum of the four skills.

It gates zones and permits to prevent “one-skill rushing”.

Canon baselines:

* Sunken Mall: Total Level `100`
* Corporate Archive: Total Level `250`
* Sovereign Vault: Total Level `380`

Spec: [5 - RPG Skilling System](../5-rpg-skilling-system/).

HI can also gate access via permits.

Spec: [Currency Systems](currency-systems.md).

***

### Integrity rules (non-negotiable)

Skilling is where “soft cheating” usually creeps in.

Keep these hard constraints:

* Skills must not rewrite canonical odds.
  * Field anomaly outcome stays `5%`. Always.
  * Lab stage tables stay fixed.
* Skills can only touch the surfaces they own:
  * Excavation: flat Crate chance bonuses (clamped).
  * Restoration: flat Stability bonuses (clamped).
  * Appraisal: information and trust surfaces only.
  * Smelting: deterministic yield multipliers (clamped).
* Anything economy-relevant is server-owned:
  * RNG
  * currency writes
  * XP grants
  * level-ups

Canon anchors:

* Field invariants: [The Dig Site (Main Screen)](../2-the-mechanics/the-dig-site-main-screen.md)
* Lab invariants: [The Refiner (The Gambling Hub)](../2-the-mechanics/the-refiner-the-gambling-hub.md)

***

### Implementation notes (so it’s buildable)

Minimum requirements to feel OSRS-like:

* Store XP as the source of truth.
* Derive level from XP server-side.
* Emit “level up” events when crossing thresholds.
* Store Total Level as derived (or computed on demand).
* Broadcast level `99` events through the global feed.

Phase guidance:

* Phase 1–2: XP can be local-only (fast iteration).
* Phase 3+: server-authoritative XP and level is required.

See: [Technical Framework (Vue + Supabase)](../../implementation-plan/technical-framework-vue-+-supabase.md).
