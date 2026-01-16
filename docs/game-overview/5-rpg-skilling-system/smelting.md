---
description: >-
  The refinement/throughput skill. Converts items into Scrap, powers bulk
  processing, and defines endgame yield scaling.
---

# Smelting

## Smelting

Smelting is the “refiner” skill.

It turns unwanted items into **Scrap**.

It’s the game’s main “cleanup” loop.

It must stay deterministic and server-owned.

Smelting is not a loot buff.

It’s an economy + efficiency tool.

Canon anchors:

* Core economy surfaces: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro/)
* Smelt ability framework: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* Smelting branches: [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)
* Smelting masteries: [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md)
* Canon lab fail outputs (Fine Dust / Cursed Fragments): [2: The Mechanics](../2-the-mechanics.md)

### What Smelting affects (and what it never touches)

Smelting **does** affect:

* Scrap output from smelt actions (multipliers, clamped).
* Smelting XP gain.
* Bulk processing speed/UX (Bulk Auto-Smelt).
* Late-game yield dominance (Pure Yield at 99).

Smelting **never** affects:

* Field extraction odds.
* Lab success odds or stage tables.
* Mint/Condition rolls.
* Any RNG that decides which relic you found.

### XP sources

Smelting XP is gained when you smelt items into Scrap.

* Single smelt actions award XP.
* Bulk Auto-Smelt awards XP based on the batch.

XP is granted on completion, not on click.

### Core action: Smelt (item → Scrap)

Smelting consumes an owned item and returns Scrap.

#### Deterministic yield rule (hard requirement)

Smelt yield must be computed server-side.

The result must be explainable.

Minimum explain line:

* `Smelted 42 Junk items into 1,260 Scrap.`

(Exact yields are tuning, but the action must be deterministic.)

#### Recommended yield model (tuning-friendly)

Define a base yield per tier:

* `scrap_base_by_tier[junk/common/uncommon/...]`

Then:

* `scrap_awarded = floor(scrap_base * yield_multiplier_final)`

Where `yield_multiplier_final` comes from:

* Smelting branch (e.g., Scrap Tycoon)
* Smelting mastery (Pure Yield)
* temporary ability (Overclock Furnace)
* event modifiers (if any)

### Level milestones (player-facing)

#### Level 1–59: steady economy throughput

* Smelting is a Scrap sink reversal.
* It turns dead inventory into progression currency.

#### Level 60+: advanced skilling starts

At Smelting level `60`, you unlock:

1. **Active ability:** **Overclock Furnace**.
2. **Branch pick:** **Fragment Alchemist** or **Scrap Tycoon**.
3. **Bulk Auto-Smelt** (batch processing UI).

These follow the shared 60+ rules:

* [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)

**60+ active ability: Overclock Furnace**

Overclock Furnace is a short burst of throughput.

Canon rules (do not drift):

* Buff window: `60s`
  * Smelting XP `×2.0`
  * Smelt Scrap output `×2.0`
* Guardrail: cap final smelt yield multiplier at `×3.0`.
* Tradeoff: apply a `10m` debuff after buff ends.
  * Increases the chance of **Critical Fail** on Lab failures.
  * Must not modify the Success/Fail roll.

Full spec: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md).

**60+ branch pick: Fragment Alchemist vs Scrap Tycoon**

Branches are build choices.

They must be explicit and visible.

* **Fragment Alchemist**
  * If Shatter Salvage exists:
    * salvage window `+0.25s`
    * Stage `3+` Standard Fail Fine Dust payout `+10%` (multiplicative)
  * Optional (only with canon update): base fragment-chance changes
* **Scrap Tycoon**
  * Junk-tier smelt output `×1.25` (multiplicative)
  * Must stack cleanly with Smelting 99 (Pure Yield)

Spec + respec rules: [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md).

#### Level 80+: cross-skill masteries (synergy layer)

Smelting participates in multiple `80/80` masteries:

* Excavation + Smelting — **Efficiency Engine** (Auto-Digger Scrap + Fine Dust trickle while online)
* Restoration + Smelting — **Salvage Scientist** (salvage window or fail payout edge)
* Appraisal + Smelting — **Industrial Broker** (Appraisal XP on bulk auto-smelt, capped)

Full list: [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md).

#### Level 90–99: elite training gate (if used)

If the game uses the HI-gated training model:

* Smelting is capped at `90` by default.
* An Influence Shop unlock lifts the cap to `99`.

Canon requirement spec: [Phase 4 requirements](../../implementation-plan/phase-4-the-high-curator-meta-game/phase-4-requirements.md).

#### Level 99: Mastery — “Pure Yield”

Level 99 is the identity moment for Smelters.

Canon mastery perk (do not drift):

* Junk-tier scrap output is doubled (`×2.0`).

It must stack cleanly with:

* Scrap Tycoon (`×1.25`)
* Overclock Furnace (`×2.0`)

Recommended clamp rule:

* `junk_multiplier_final = min(junk_multiplier_base * branch_mult * mastery_mult * overclock_mult, 3.0)`

(Keep it readable. Prevent runaway stacking.)

### Materials and “failure economy” hooks

Smelting sits next to the Lab failure economy.

Important distinction:

* Fine Dust and Cursed Fragments are produced by Lab failure rules.
* Smelting can consume outputs or improve recovery via branches/masteries.

Canon shatter notes:

* Standard Fail pays Fine Dust.
* Stage `3+` shatters have a `1%` chance to roll a Cursed Fragment.

Source: [2: The Mechanics](../2-the-mechanics.md).

If you ever let Smelting modify fragment chance:

* update the canon chance explicitly
* keep it visible
* clamp it

### Worked examples

#### Example A — junk smelt multipliers

Assume base junk yield for an item is `10` Scrap (example tuning).

If the player has:

* Scrap Tycoon (`×1.25`)
* Pure Yield (`×2.0`)

Then:

* `10 * 1.25 * 2.0 = 25` Scrap per junk item (before any clamp).

If Overclock Furnace is also active (`×2.0`):

* `10 * 1.25 * 2.0 * 2.0 = 50`

With the `×3.0` cap:

* `10 * 3.0 = 30`

The cap prevents extreme burst farming.

#### Example B — batch explain string

If a player bulk-smelts 42 junk items:

* `Smelted 42 Junk items into <total> Scrap.`

The UI must show the total and the multiplier sources.

### UI/UX requirements

Minimum UI surfaces for Smelting:

* Vault smelting surface shows:
  * item selection
  * projected output
  * “breakdown” tooltip lines (base + multipliers)
* Bulk Auto-Smelt:
  * select tier(s)
  * show eligible count
  * show projected Scrap
  * confirm step
* Overclock Furnace:
  * clear `60s` buff timer
  * clear `10m` debuff warning shown in Lab (`SYSTEMS HOT: OVERHEAT RISK UP`)

UX beats reference: [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md).

### Implementation notes (state + authority)

Smelting touches currency output.

All output must be server-owned.

Minimum persistent state:

* `smelting_xp`
* `smelting_level`
* `smelting_branch` (none until 60, then `fragment_alchemist` or `scrap_tycoon`)
* `elite_training_unlocked` (if 90–99 is gated)

Ability state:

* `overclock_active_until`
* `overclock_cooldown_until`
* `overclock_debuff_until`

Server actions:

* `smelt_item(item_id)`
  * validates ownership and lock states (escrow, museum lock, leased)
  * calculates deterministic scrap
  * awards scrap + XP
  * destroys item
* `bulk_smelt(filters)`
  * same validation
  * batched deterministic output

### Integrity constraints (non-negotiable)

* Smelting outputs are never client-calculated.
* Smelting must respect item lock states:
  * escrow (Bazaar listing)
  * museum lock
  * leased
  * endowed
* Multipliers must be visible and clamped.

### Telemetry

Track:

* Smelts/day and bulk-smelt batch sizes.
* Scrap generated/day via smelting (by tier).
* Overclock Furnace usage and resulting Lab overheat deltas.
* Branch pick distribution and respec rate.
* Economic impact:
  * net Scrap inflation contribution from smelting

### Links

* Smelting active ability: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* Smelting branches: [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)
* Smelting-related masteries: [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md)
* Canon Lab fail materials: [2: The Mechanics](../2-the-mechanics.md)
* Lock state rules: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md)
