---
description: >-
  The Lab-focused skill. Controls Stability, failure mitigation, and high-end
  gambling viability.
---

# Restoration

## Restoration

Restoration is the “gambler” skill.

It governs how safely you can push crates through the Lab.

It increases **Sift Stability**.

It never changes stage tables or rarity odds.

Canon anchors:

* Lab stages, base stability, and fail types: [2: The Mechanics](../2-the-mechanics/)
* Triage layer: [Active Stabilization (Lab Triage)](../../expansion-plan/micro-loop-expansion/2.-active-stabilization-lab-triage.md)
* 60+ reaction: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)

### What Restoration affects (and what it never touches)

Restoration **does** affect:

* Lab Sift success chance (flat Stability bonus per level).
* How efficiently you can use Active Stabilization (Fine Dust costs).
* How often you can exit disaster (Emergency Glue).
* Late-game HV edge as an explicit, always-on bonus at level 99 (canon).

Restoration **never** affects:

* The Lab stage rarity tables.
* Mint assignment logic.
* Condition roll logic.
* Extraction odds in the Field.

### XP sources

You gain Restoration XP when you complete a **Sift attempt**.

Rules:

* Success: `100%` XP.
* Failure (Standard Fail / Shatter): `25%` “Pity XP”.

This matches the system rules in [5 - RPG Skilling System](./).

### Passive payoff: Stability scaling (the core perk)

Every Restoration level:

* adds `+0.1%` flat Stability.

#### Exact formula (recommended)

Let:

* `L` = Restoration level
* `p_stage_base` = stage base Stability from canon

Then:

* `p_success_pre_clamp = p_stage_base + (L * 0.1%) + bonuses_flat`

Examples (Restoration only, no other bonuses):

* Level 10: `+1.0%` stability
* Level 50: `+5.0%`
* Level 99: `+9.9%` (plus the level 99 mastery perk below)

#### Clamping (required)

Stability must stay readable and not hit 100% on high stages by accident.

Recommended clamp:

* `p_success_final = clamp(p_success_pre_clamp, 1%, 100%)`

Stage 0 remains `100%` by definition.

{% hint style="info" %}
Canon base stage stabilities are defined in [2: The Mechanics](../2-the-mechanics/).
{% endhint %}

### Key milestones (player-facing)

#### Level 1–59: safer pushes

* Your stability bonus steadily increases success odds on every stage.
* This makes Stage 3–5 gambling progressively more viable.

#### Level 60+: advanced skilling starts

At Restoration level `60`, you unlock two systems:

1. **Reaction ability:** **Emergency Glue**.
2. **Branch pick:** **Stable Hand** or **Quantum Gambler**.

These follow the shared 60+ rules:

* [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)

**60+ reaction: Emergency Glue**

Emergency Glue is the rare “save” button.

Canonical rules (do not drift):

* Trigger: **Standard Fail** only, during the “System Error” glitch beat.
* Never triggers on Critical Fail / overheat.
* Never triggers on Stage 0.
* Cost: consumes `1` Cursed Fragment.
* Effect: converts the fail into a forced **\[CLAIM]** at the **current stage**.
* Arbitration: if Shatter Salvage also exists, the first reaction pressed wins.

Full spec: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md).

**60+ branch pick: Stable Hand vs Quantum Gambler**

Branches add **explicit flat Stability** in different stage bands.

They must be visible in UI.

* **Stable Hand**: Stage 1–3 `+3%` flat Stability.
* **Quantum Gambler**: Stage 4–5 `+2%` flat Stability.

Full spec + respec rules: [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md).

#### Level 80+: cross-skill masteries (synergy layer)

Restoration participates in multiple `80/80` masteries.

Notable ones:

* Restoration + Appraisal — **Certified Restorer** (`+5%` HV once per item when restored+certified by you)
* Excavation + Restoration — **Field Conservator** (first Tether refund chance)
* Restoration + Smelting — **Salvage Scientist** (salvage window or fail payout edge)

Full list: [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md).

#### Level 99: Mastery — “Master Preserver”

Level 99 is the identity moment for Restorers.

Canon mastery perk (do not drift):

* `+10%` Base Stability (applied to all sifting tiers)
* Stability needle is `10%` slower (feel only, UX rule)
* Claimed items gain `+1%` HV (always-on line item)

Source: [5 - RPG Skilling System](./).

### System interactions

#### Active Stabilization (Lab Triage)

Active Stabilization adds tactical control over **failure severity**.

Restoration interacts by reducing Fine Dust costs (canon: Restoration reduces Fine Dust cost to tether).

Spec: [Active Stabilization (Lab Triage)](../../expansion-plan/micro-loop-expansion/2.-active-stabilization-lab-triage.md).

#### Shatter Salvage + Emergency Glue

Both can appear in the same 1-second failure beat.

Hard rule:

* One failure beat = one reaction choice.

If both are available:

* show both buttons
* first pressed wins
* other disables

Canon references:

* Salvage: [2: The Mechanics](../2-the-mechanics/)
* Glue: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)

### Worked examples

#### Example A — pure Restoration scaling

Stage 3 base stability is `50%`.

If Restoration level is `40`:

* Bonus = `+4.0%`
* Final (before other modifiers) = `54%`

#### Example B — Restoration + branch bonus

Same Stage 3, Restoration level `60`:

* Restoration bonus = `+6.0%`
* Stable Hand branch adds `+3%` (Stage 1–3)
* Final = `50 + 6 + 3 = 59%` (before other modifiers)

### UI/UX requirements

Minimum UI surfaces for Restoration:

* Skill level + % to next level in the Vault skill dashboard.
* In the Lab, show Stability as a breakdown:
  * Base stage stability
  * Restoration level bonus
  * Branch bonus (if any)
  * Zone Static penalty (if any)
  * Clamp result
* Level-up banner: `LEVEL <X> RESTORATION REACHED`.
* Failure beat:
  * if eligible, show **\[EMERGENCY GLUE]** only during the 1-second window
  * show cost (`1` Cursed Fragment) in the button label or tooltip

UX beats reference: [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md).

### Implementation notes (state + authority)

This skill touches high-value RNG outcomes.

All math must be server-owned.

Minimum persistent state:

* `restoration_xp`
* `restoration_level` (derived from XP is fine)
* `restoration_branch` (none until 60, then `stable_hand` or `quantum_gambler`)

Minimum ability state:

* Emergency Glue cooldown timestamps (`emergency_glue_cooldown_until`)

Required Lab run metadata (server-owned):

* current `stage`
* last roll result (Success / Standard Fail / Critical Fail)
* whether the 1s failure beat is active

Integrity rules:

* Emergency Glue is server-authoritative.
* The server validates:
  * correct trigger (Standard Fail only)
  * player owns `1` Cursed Fragment
  * cooldown not active

### Integrity constraints (non-negotiable)

* Restoration never changes stage rarity tables.
* Restoration never changes the Success/Fail roll model.
  * It only adds a visible flat Stability bonus.
* Emergency Glue never turns a fail into a success.
  * It turns a fail into a safe exit.

### Telemetry

Track:

* Stability deltas by stage and Restoration level band.
* Shatter rate by stage over time.
* Emergency Glue usage:
  * eligible beats vs uses
  * stage where it fired
  * “value saved” distribution
* Fine Dust economy:
  * dust earned from fails vs dust spent on tethers

### Links

* Canon Lab rules + fail states: [2: The Mechanics](../2-the-mechanics/)
* Core skilling model and mastery perks: [5 - RPG Skilling System](./)
* Active abilities (Emergency Glue): [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* Branch picks: [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)
* Masteries: [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md)
* Lab triage layer: [Active Stabilization (Lab Triage)](../../expansion-plan/micro-loop-expansion/2.-active-stabilization-lab-triage.md)
