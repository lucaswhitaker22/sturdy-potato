---
description: Testable requirements for Phase 2 (Progression).
---

# Phase 2 requirements

This is the build contract for Phase 2.

It turns the Phase 2 plan into concrete requirements.

### Canon and coverage rules

This page is the Phase 2 source of truth.

It must fully “cover” the functionality described in:

* [Game Overview](../../)
* [0 - Game Loop](../../game-overview/0-game-loop.md)
* [2: The Mechanics](../../game-overview/2-the-mechanics.md)
* [3 - The Loot & Collection Schema](../../game-overview/3-the-loot-and-collection-schema.md)
* [5 - RPG Skilling System](../../game-overview/5-rpg-skilling-system/)
* [6 - UI/UX Wireframe & Flow](../../game-overview/6-ui-ux-wireframe-and-flow.md)

Coverage means:

* If it ships in Phase 2, it must be a requirement here.
* If it does **not** ship in Phase 2, it must be named in **Out of scope**.

### Scope

Phase 2 extends the Phase 1 loop with progression and persistence:

* XP, levels, and skill bonuses (Excavation + Restoration).
* Workshop tool tiers that unlock passive extraction.
* Collections (sets) with permanent buffs.
* Supabase-backed persistence, autosave, and offline gains.
* UI updates to surface levels, tools, sets, and events.

Phase 2 assumes Phase 1 is already working:

* Manual Extract in the Field.
* Crates and the Lab loop (`[CLAIM]` vs `[SIFT]`), including shatter outcomes.
* Vault item storage.
* A crate tray exists (capacity is Phase 1 canon; Mechanics implies 5 slots).

#### Out of scope

Anything in the Game overview docs that isn’t listed as a Phase 2 requirement is out.

Explicit non-goals for Phase 2:

* **Macro / MMO decks**
  * Bazaar: trading, listing deposits, taxes, certifications, tickers.
  * Archive: museum themes, leaderboard rewards, Historical Influence, quests.
  * Global Feed: cross-player announcements and realtime social feed.
* **Loot identity / economy meta**
  * Mint number, condition modifiers, Historical Value (HV).
  * Prismatic (“shiny”) variants and dissolving into Vault Credits.
  * Vault Credits and any premium-currency flows.
* **Skills beyond Phase 2**
  * Appraisal XP, Appraisal perks, and any market-fee reductions.
  * Smelting XP, Smelting perks, and item-to-scrap conversion tuning.
  * Total Level gates, zone unlocks, and blueprint drops at high levels.
  * Advanced skilling (all defined as 60+ systems):
    * Active abilities (Focused Survey, Emergency Glue, Hype Train, Overclock Furnace).
    * Skill sub-specializations (branch picks + respec).
    * Cross-skill masteries (80/80) and total mastery (all skills 90+).
    * Archive “Research Notes” (Senior Researcher) intel panel.
* **Lab and Field extensions**
  * Anomaly system beyond Phase 1’s log-only anomaly outcome (mini-events, global modifiers, etc).
  * Extra shatter/failure states (Fine Dust payouts, cooldowns, cursed fragments).
  * Any new refine stages, odds, rarities, or rarity UI color canon.
* **Collections depth beyond Phase 2**
  * Buff types beyond `[EXTRACT]` cooldown (e.g., Scrap gain, Stability, Bazaar fees).
  * Manual “set-lock” UX (Phase 2 only needs auto-locking on completion).
* **Workshop depth beyond Phase 2**
  * Tool leveling, exponential upgrade curves, Overclocking / prestige.
  * Tool stats beyond Phase 2 needs (manual dig speed, crate-find-rate-per-tool, “Extraction Power” formulas).
  * Tool tiers beyond the minimum list in R7.
* **New content**
  * New dig sites, zones, time-boxed world events, and event modifiers.
* **UI/UX polish beyond Phase 2**
  * Full 5-deck command bar and navigation spec (beyond adding Workshop + Collections).
  * Button color language, micro-animations, audio “juice,” and glitch effects.
  * Desktop vs mobile layout rules.
  * Full skill dashboard UI (circular progress bars, milestone lists).

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

The level curve must follow the OSRS-style curve in [5 - RPG Skilling System](../../game-overview/5-rpg-skilling-system/).

The total XP required for a given level $$L$$ is:

$$
XP(L) = \sum_{n=1}^{L-1} \lfloor n + 300 \cdot 2^{n/7} \rfloor
$$

Canon checkpoints:

* Level 99 requires \~`13,034,431` XP total.

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
Canon: base crate drop rate is `15%` per Extract outcome roll (from Mechanics).
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
* Pneumatic Pick — cost 2,500, level req 5, passive 5
* Ground Radar — cost 15,000, level req 15, passive 25
* Industrial Drill — cost 80,000, level req 30, passive 100

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

Open question: how does passive extraction interact with the Phase 1 “tray full” rule? Recommended: if tray is full, crates don’t drop, but Scrap still accrues.

Passive extraction must run on a 10-second tick (Mechanics-aligned).

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
* Set items become “locked” (cannot be removed from the set later).
* The set UI changes to a “Gold glow” state.
* The player receives the set buff permanently.
* A toast notification is shown.

Minimum set to implement:

* “The Morning Ritual”: Ceramic Mug + Rusty Toaster + Spoon
* Reward: “Caffeine Rush” — reduces `[EXTRACT]` cooldown by `0.5s` permanently.

#### R12 — Buff system

Phase 2 must implement a buff/modifier system that can modify:

* `[EXTRACT]` cooldown (required for Phase 2)

Phase 2 does not need any other modifier types.

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

Offline gains must be capped by a “Battery Capacity” limit.

The cap value must be a single config constant (hours or seconds).

The UI must show the current cap, or the remaining offline headroom.

### Security / integrity requirements

#### R19 — RNG authority (anti-cheat baseline)

Any RNG that affects player progression must be computed server-side.

Minimum scope for Phase 2:

* Passive extraction crate rolls.
* Passive extraction Scrap awards (if any variability exists).

Phase 1 already owns the Lab sifting RNG.

If Phase 1 does not have server-authoritative RNG yet, Phase 2 must not introduce new client-side RNG.

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

### Canon notes (resolved conflicts)

Phase 2 uses Mechanics as the numeric source of truth for:

* Tool costs and passive power.
* Passive extraction tick rate (10 seconds).
* Offline cap concept (“Battery Capacity”).
