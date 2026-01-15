---
description: Testable requirements for Phase 2 (Progression).
---

# Phase 2 requirements

This is the build contract for Phase 2.

It turns the Phase 2 plan into concrete requirements.

### Scope

Phase 2 extends the Phase 1 loop with progression and persistence:

* XP, levels, and skill bonuses (Excavation + Restoration).
* Workshop tool tiers that unlock passive extraction.
* Collections (sets) with permanent buffs.
* Supabase-backed persistence, autosave, and offline gains.
* UI updates to surface levels, tools, sets, and events.

Phase 2 assumes Phase 1 is already working:

* Manual Extract in the Field.
* Crates, Lab sifting, shatter outcomes.
* Vault item storage.

#### Out of scope

* Bazaar, trading, museum, and other MMO features.
* Appraisal and Smelting skills.
* Mint number, condition, HV, prismatic variants.
* New dig sites, zones, or world events.

### Data requirements

#### Player profile (Supabase)

The game must persist these fields in `profiles`:

* `scrap` (integer, >= 0)
* `excavation_xp` (integer, >= 0)
* `restoration_xp` (integer, >= 0)
* `active_tool_id` (string, nullable)
* `last_save_at` (timestamp)
* `last_logout` (timestamp)

The game must persist collections progress:

* `completed_set_ids` (list of set IDs) or a join table.

The game must persist owned tools:

* `owned_tool_ids` (list of tool IDs) or a join table.

#### Inventory (Supabase)

The game must store all found items in `inventory`.

Minimum fields:

* `id` (primary key)
* `player_id`
* `item_catalog_id`
* `created_at`

#### Catalog data (static)

Phase 2 must have static definitions for:

* Tool tiers (cost, level requirements, passive power).
* Collection sets (set ID, required item IDs, reward buff).

### Leveling rules

#### R1 — XP tracking

The game must track XP for:

* Excavation
* Restoration

XP must be persisted in Supabase.

XP must never decrease.

#### R2 — Level curve

The level curve must follow:

* Level 1 requires `100` XP.
* Each next level requires \~`10%` more XP than the prior level.

The UI must show current level for both skills.

{% hint style="info" %}
Open question: do we store cumulative XP to date, or XP into current level? Phase 1 requirements used simple integers. Phase 2 should pick one.
{% endhint %}

### Functional requirements

#### R3 — Excavation XP sources

The player gains Excavation XP when:

* A manual `[EXTRACT]` finishes.
* An auto-dig tick occurs.

Excavation XP must not be granted on button press.

It must be granted on completion.

#### R4 — Excavation level payoff (crate drop rate)

Every 5 Excavation levels must increase crate drop rate by `+0.5%`.

This bonus must be:

* Additive.
* Applied to both manual Extract and passive extraction rolls.

The UI must show the bonus (at least in a tooltip).

{% hint style="info" %}
Open question: what is the base crate drop rate in Phase 2? Current docs disagree (Phase 1 vs Mechanics). Pick a single canon value.
{% endhint %}

#### R5 — Restoration XP sources

The player gains Restoration XP when completing a Sift attempt.

Rules:

* Sift success grants 100% of the awarded XP.
* Failure / shatter grants 25% “Pity XP”.

#### R6 — Restoration level payoff (stability)

Every Restoration level must add `+0.1%` flat bonus to the Stability gauge.

This bonus must:

* Apply to all Lab sifting stages.
* Be visible in the UI (base vs bonus, or final %).

{% hint style="info" %}
Open question: how do we cap success chance? (e.g. 95% max) Uncapped bonuses will eventually break risk.
{% endhint %}

#### R7 — Workshop screen and tool tiers

The game must add a Workshop screen/tab.

The Workshop must list tool tiers with:

* Tool name
* Scrap cost
* Level requirement
* Passive power (Scrap/sec)
* `BUY` action

Minimum tool list:

* Rusty Shovel — cost 0, level req 1, passive 0 (manual only)
* Pneumatic Pick — cost 1,500, level req 5, passive 2
* Ground Radar — cost 10,000, level req 15, passive 10
* Industrial Drill — cost 50,000, level req 30, passive 50

#### R8 — Tool purchase gating

A tool’s `BUY` button must be disabled unless:

* Player has enough Scrap.
* Player meets the level requirement.

If the player buys a tool:

* Scrap is decremented immediately.
* The tool is added to owned tools.
* The tool becomes the `active_tool_id`.

#### R9 — Passive extraction loop (online)

When `active_tool_id` has passive power > 0:

* The Field screen must show a secondary passive progress bar.
* The bar must fill automatically.
* On completion, the player gains Scrap based on the tool’s passive power.

Passive extraction must also roll for crates.

If a crate drops:

* It is added to the crate tray.
* The player sees a notification.

{% hint style="info" %}
Open question: how does passive extraction interact with the Phase 1 “tray full” rule? Recommended: if tray is full, crates don’t drop, but Scrap still accrues.
{% endhint %}

#### R10 — Collections feature

The Vault must add a new `[COLLECTIONS]` tab.

Collections must display:

* Set name
* Required items
* Completion status

Missing items must show as silhouettes.

#### R11 — Set completion check

When an item is added to the Vault inventory, the game must run a set check.

If the item completes a set:

* The set becomes completed.
* The set UI changes to a “Gold glow” state.
* The player receives the set buff permanently.
* A toast notification is shown.

Minimum set to implement:

* “The Morning Ritual”: Ceramic Mug + Rusty Toaster + Spoon
* Reward: “Caffeine Rush” — reduces `[EXTRACT]` cooldown by `0.5s` permanently.

#### R12 — Buff system

Phase 2 must implement a buff/modifier system that can modify:

* `[EXTRACT]` cooldown (required for Phase 2)

The buff system must be:

* Deterministic (no RNG).
* Persisted (completed sets re-apply on login).

### Persistence requirements

#### R13 — Autosave

The game must push state updates to Supabase:

* Every 30 seconds, and
* On major events:
  * Skill level up
  * Rare find (if rarity exists in Phase 1)
  * Tool purchase
  * Set completion

#### R14 — Reload and session continuity

A browser refresh must restore:

* Scrap
* XP and levels
* Owned and active tool
* Inventory
* Completed sets and active buffs

#### R15 — Offline gains

On login, the game must:

1. Read `last_logout`.
2. Compute time elapsed since `last_logout`.
3. Award Scrap earned by passive tools during that time.

Offline gains must not require the user to keep the tab open.

{% hint style="info" %}
Open question: do we cap offline gains? If yes, what cap? The Mechanics doc references “Battery Capacity,” but Phase 2 does not.
{% endhint %}

### UI/UX requirements

#### R16 — Header level bubbles

The header must display skill levels next to the player name:

* `Excav: <level> | Resto: <level>`

#### R17 — Toast system

The game must show bottom-screen toast notifications for:

* Skill level up
* Set completion

Minimum messages:

* `Excavation Level Up! (Level 13)`
* `Set Complete: 'The Office' (+5% Scrap Yield)`

{% hint style="info" %}
“The Office” is an example string from the Phase 2 plan. It does not need to ship as a real set in Phase 2.
{% endhint %}

#### R18 — Workshop list UI

The Workshop must show tools in a simple vertical list.

Each tool row must:

* Show cost and level requirement.
* Grey out `BUY` when locked.

### Success criteria

Phase 2 is done when:

1. A player can reach Level 10 in Excavation and Restoration.
2. The player can purchase the Pneumatic Pick.
3. Scrap increases without clicking after purchase.
4. Completing a 3-item set applies a visible buff.
5. Refreshing the browser restores state.

### Known conflicts (needs a canon decision)

These docs currently disagree on key numbers:

* Extract RNG (Phase 1 requirements vs Mechanics).
* Refining stage count and odds (Phase 1 requirements vs Mechanics).
* Tool tier costs and outputs (Mechanics vs Phase 2 plan).

Before implementation, pick a single source-of-truth for Phase 2.
