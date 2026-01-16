# Sample Collection Tiers

## Collections: sample tiers (and how they plug into every system)

Collections turn “random loot” into **directed long-term goals**.

They also create a clean **item sink**: once you commit a set, those items stop circulating.

This page is the working reference for set tiers, rewards, and integration points across the full loop:

* Field (extraction)
* Lab (sifting + failure economy)
* Vault (locking, smelting)
* Bazaar (escrow, fees)
* Archive (Museum themes, prestige)

Core schema rules still live in [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md).

### What a “set” is (definition)

A set is a static definition:

* `set_id`
* `name`
* `required_item_catalog_ids[]`
* `reward` (one or more explicit account modifiers)
* optional metadata:
  * theme tags (for Museum weeks / Expeditions)
  * tier (T0–T5)

The set system must **not** change RNG tables.

It can only apply explicit modifiers that are:

* visible in UI
* additive or multiplicative (clearly labeled)
* clamped where canon requires clamps

### Completion + locking rules (Vault behavior)

{% stepper %}
{% step %}
#### 1) Acquire the items

Items enter the Vault by being **claimed** from the Lab loop.

See [2: The Mechanics](../2-the-mechanics.md).
{% endstep %}

{% step %}
#### 2) The set check runs automatically

When a new item is added to your Vault:

* run a set completion check
* update the Collections UI (silhouettes → discovered)
* if the set is complete, mark it complete and grant rewards
{% endstep %}

{% step %}
#### 3) “Set-lock” the items

On completion, the required items become **set-locked**.

Default rule: set-locked items are removed from the economy.

They cannot be:

* smelted
* dissolved (prismatic)
* listed (escrow)
* leased
* endowed

They **can** still be used for **Museum submissions** (recommended), since that’s not trade.

Museum locking is a separate temporary lock.

See [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md).
{% endstep %}
{% endstepper %}

{% hint style="info" %}
Phase alignment:

* **Phase 2** only needs auto-completion + auto-locking + one modifier type (`[EXTRACT]` cooldown).
  * See “Collections feature” in [Phase 2 requirements](../../implementation-plan/phase-2-the-amateur-archaeologist-progression/phase-2-requirements.md).
* Manual “choose what to lock” UX can ship later.
  * The system rules above still apply.
{% endhint %}

### Lock state compatibility (so players don’t exploit it)

Collections add a new lock state (`SET_LOCKED`) that must coexist with the other canonical states:

* **Escrow** (Bazaar listing): locked, cannot be smelted/leased/endowed/Museum.
  * See [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md).
* **Museum lock** (weekly submission): locked until week ends.
  * See [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md).
* **Leased**: temporary, untradeable, cannot be smelted/dissolved/endowed/Museum.
  * Leased items can enable **temporary** set buffs only.
  * See [Artifact Leasing (The Rental Economy)](../../expansion-plan/macro-loop-expansion/3.-artifact-leasing-the-rental-economy.md).
* **Endowed**: burned forever.
  * See [Museum Endowments (Permanent Prestige)](../../expansion-plan/macro-loop-expansion/4.-museum-endowments-permanent-prestige.md).

Hard rule: an item can’t be in two “exclusive locks” at once.

Example: you can’t list an item in escrow if it’s set-locked.

### What sets are allowed to modify (integration map)

#### Field-facing modifiers (THE FIELD)

Allowed:

* `[EXTRACT]` cooldown (Phase 2 canon via “Caffeine Rush”)
* Scrap gain per manual extract (does not alter the `80/15/5` outcome split)
* flat Crate chance modifiers **only if** they follow the same additive + clamp rules as Excavation (clamp `≤ 95%`)
  * See [Excavation](../5-rpg-skilling-system/excavation.md).

Never allowed:

* changing the base extraction roll split (Scrap/Crate/Anomaly = `80/15/5`)
* changing the 5% Anomaly roll

#### Lab-facing modifiers (THE LAB)

Allowed:

* flat Sift Stability bonus (must remain explicit and visible)
  * See [Restoration](../5-rpg-skilling-system/restoration.md).
* failure-economy QoL that doesn’t rewrite success odds (example: Fine Dust costs for tethering)

Never allowed:

* changing stage rarity tables
* changing mint assignment or condition rolls

#### Vault-facing modifiers (THE VAULT)

Allowed:

* capacity / sorting / QoL (tabs, filters) as late-game rewards
* smelting throughput bonuses (if you keep them clamped + explicit)
  * See [Smelting](../5-rpg-skilling-system/smelting.md).

#### Bazaar-facing modifiers (THE BAZAAR)

Allowed:

* listing fee reductions (like “High Delivery Gala”)
* deposit reductions (listing spam prevention stays intact)

Never allowed:

* Archive Tax changes (reserved for Appraisal mastery)
  * See [Appraisal](../5-rpg-skilling-system/appraisal.md).

#### Archive-facing modifiers (ARCHIVE / Museum)

Recommended: keep collection rewards mostly **progression/QoL**, not raw Museum score multipliers.

Museum scoring already has set multipliers when you submit full themed sets.

See [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md).

### Tiering framework (T0 → T5)

Tier is mostly a **reward strength + system it touches**.

* **T0 (Tutorial)**: teaches “sets exist” and gives obvious felt gains.
* **T1 (Beginner)**: Field throughput (Scrap/cooldowns).
* **T2 (Progression)**: Vault QoL + offline/automation edges.
* **T3 (Specialist)**: Lab stability + failure economy edges.
* **T4 (Economy)**: Bazaar efficiency (fees/deposits).
* **T5 (Prestige)**: cosmetics/titles + “flex” sinks (endowment-adjacent).
  * Avoid raw power spikes.

### Sample sets by tier (examples)

These are examples.

Any numeric values marked “tunable” are not canon.

#### T0 — Tutorial / onboarding (Phase 2-friendly)

**Set: “The Morning Ritual” (Core Progression)**

* Required items: Ceramic Mug, Rusty Toaster, Spoon
* Reward name: **Caffeine Rush**
* Reward: permanently reduces `[EXTRACT]` cooldown by `0.5s` (canon, required in Phase 2)
  * See [Phase 2 requirements](../../implementation-plan/phase-2-the-amateur-archaeologist-progression/phase-2-requirements.md).

#### T1 — Beginner Field sets (Scrap + tempo)

**Set: “The 20th Century Kitchen” (Beginner Tier)**

* Required items: Rusty Toaster, Ceramic Mug, Silicone Spatula, Manual Can Opener
* Reward: `+10%` Scrap gain from **manual** digging actions (canon example from the loot schema)

**Set: “Pocket Junk Drawer” (example)**

* Required items: Rubber Band, Safety Pin, Ballpoint Pen, Soda Tab
* Reward (tunable): `+5%` Scrap gain from **passive** extraction ticks

#### T2 — Progression sets (automation + Vault QoL)

**Set: “Battery Pack Theory” (example)**

* Required items: AA Battery, Flashlight, Remote Control, USB Flash Drive (2GB)
* Reward (tunable): `+1h` Battery Capacity for offline gains
  * Pairs with the offline cap system in [2: The Mechanics](../2-the-mechanics.md).

**Set: “The Office” (example string used in requirements)**

* Reward (tunable): `+5%` Scrap Yield (global)
  * Keep it explicit and not RNG-based.
  * Mentioned as a message example in [Phase 2 requirements](../../implementation-plan/phase-2-the-amateur-archaeologist-progression/phase-2-requirements.md).

#### T3 — Specialist Lab sets (stability + failure economy)

**Set: “The Digital Dark Age” (Mid-Game Pursuit)**

* Required items: CRT Monitor, Mechanical Keyboard, Floppy Disk (3.5"), Wired Mouse
* Reward: `+5%` Sift Stability (flat) (canon example from the loot schema)

**Set: “Clean Room Protocol” (example)**

* Required items: Eyeglass Frame, Safety Pin, Rubber Band, Lightbulb
* Reward (tunable): `-10%` Fine Dust cost for Active Stabilization tethering
  * Pairs with the triage layer in [2: The Mechanics](../2-the-mechanics.md).

#### T4 — Economy sets (Bazaar efficiency)

**Set: “The High Delivery Gala” (Late-Game Luxury)**

* Required items: Diamond Tennis Bracelet, Silk Necktie, Gold-Plated Lighter, Designer Perfume Bottle
* Reward: `-15%` Bazaar listing fees (canon example from the loot schema)

**Set: “Broker’s Clipboard” (example)**

* Required items: Calculated Tablet, Wrist Chronometer, Ballpoint Pen, Eyeglass Frame
* Reward (tunable): `-20%` Bazaar listing deposit (Scrap)
  * Keeps deposits, just reduces friction.

#### T5 — Prestige sets (cosmetic + social proof)

T5 sets should avoid raw power multipliers.\n Use them for:

* cosmetic frames
* titles
* feed callouts
* Museum “display” cosmetics (not score)

Example pattern (no numbers required):

* “Founder’s Showcase” — a prismatic-themed Vault frame unlocked on completion.

### Design guardrails (so sets don’t break balance)

* Set rewards must be **weaker than** skill mastery perks.
  * Skills are permanent progression; sets are content goals.
  * See [5 - RPG Skilling System](../5-rpg-skilling-system/).
* If a set touches chance:
  * make it flat/additive
  * show the breakdown
  * clamp it (use the same clamp rules as the owning system)
* Don’t allow a set to reduce Archive Tax.
  * That’s Appraisal mastery territory.
* Don’t overlap sets too aggressively.
  * Overlap creates “which copy counts?” UX and drives weird hoarding.

### Minimal data + UI surfaces (implementation checklist)

Even in Phase 2, Collections need a few hard surfaces:

* Vault tab: `[COLLECTIONS]`
* per-set view:
  * required items list + silhouettes for missing
  * “complete” state (gold glow)
  * reward text (exact)
* profile persistence:
  * `completed_set_ids[]`
  * derived account modifiers on login
