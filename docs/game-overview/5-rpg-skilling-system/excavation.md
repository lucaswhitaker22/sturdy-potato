# Excavation

## Excavation

Excavation is the “gatherer” skill.

It governs how often you pull **Crates** out of the Field.

It never changes the base extraction outcome odds.\n Core odds stay canonical in [2: The Mechanics](../2-the-mechanics/).

### What Excavation affects (and what it never touches)

Excavation **does** affect:

* Crate drop chance (passive bonus, additive).
* Manual extraction skill expression (Seismic Surge sweet spot size).
* Zone risk planning (Survey mitigation for Vault Heatmaps).
* Late-game identity targeting (specialization bias at 60).

Excavation **never** affects:

* The base extraction roll split (Scrap / Crate / Anomaly = `80/15/5`).
* The 5% Anomaly roll.
* Scrap payout per extraction.
* Lab stage tables or Stability math.

### XP sources

You gain Excavation XP when:

* A manual **\[EXTRACT]** finishes.
* An Auto-Digger tick resolves (online or offline award).

XP is granted on **completion**, not button press.\n This matches the skilling rules in [5 - RPG Skilling System](./).

### Passive payoff: Crate chance scaling (the core perk)

Every `5` Excavation levels:

* Crate drop chance gets `+0.5%` flat (additive).

This bonus applies to:

* manual **\[EXTRACT]** outcomes
* passive extraction rolls (Auto-Digger ticks)

{% hint style="info" %}
Canon base Crate chance is `15%` per Extract outcome roll.\n See [2: The Mechanics](../2-the-mechanics/).
{% endhint %}

#### Exact formula (recommended)

Let `L` be your Excavation level.

* `excavation_crate_bonus = floor(L / 5) * 0.5%`

Examples:

* Level 1–4: `+0.0%`
* Level 5–9: `+0.5%`
* Level 10–14: `+1.0%`
* Level 50–54: `+5.0%`
* Level 99: `+9.5%`

### Stacking rules (keep math sane)

All Excavation-adjacent Crate bonuses stack **flat/additive**, then clamp:

* `p_crate_final = min(p_crate_base + bonuses_flat, 95%)`

This must stack cleanly with:

* [Seismic Surge](../../expansion-plan/micro-loop-expansion/1.-the-seismic-surge-active-extraction.md) (Hit/Perfect bonuses per action)
* [Vault Heatmaps](../../expansion-plan/micro-loop-expansion/6.-vault-heatmaps-zone-strategy.md) (zone static bonus)
* **Focused Survey** (Excavation 60+) from [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* time-boxed world events (explicit modifiers only)

#### Worked example (sanity check)

Assume:

* Base Crate chance: `15%`
* Tool bonus (example): `+10%`
* Excavation level 50: `+5.0%`
* Zone Static HIGH: `+2%`
* Perfect Survey (Seismic Surge): `+5%` (this action only)
* Focused Survey active: `+10%` (manual only)

Total before clamp: `15 + 10 + 5 + 2 + 5 + 10 = 47%`

Final: `47%` (no clamp needed).

### Key milestones (player-facing)

These are the unlock beats players should feel.

#### Level 1–59: throughput + timing skill

* Your passive perk ramps Crate rate via the `+0.5%` / 5 levels rule.
* Seismic Surge becomes easier as Excavation rises.\n Spec: [Seismic Surge](../../expansion-plan/micro-loop-expansion/1.-the-seismic-surge-active-extraction.md).
* Tool gating uses Excavation as the primary “field power” requirement.\n See the tool tier table in [2: The Mechanics](../2-the-mechanics/).

#### Level 60+: advanced skilling starts

At level `60`, Excavation unlocks two systems:

1. **Active ability:** **Focused Survey** (paid power window).
2. **Branch pick:** **Urban Scavenger** or **Tech Hunter** (identity bias).

These must follow the shared 60+ pattern defined in:

* [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)

**60+ active ability: Focused Survey**

Focused Survey is a paid, time-boxed buff for **manual** digging.

Canon rules (do not drift):

* Duration: `60s`
* Effect: `+10%` flat Crate chance on manual **\[EXTRACT]** only
* Clamp: `≤ 95%`
* Does not touch Anomaly odds
* Has a Scrap drain + cooldown

Full spec: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md).

**60+ branch pick: Urban Scavenger vs Tech Hunter**

Branches bias **item identity** after rarity is decided.\n They must not change rarity odds.

* **Urban Scavenger**: bias toward `Household` and `Branded`
* **Tech Hunter**: bias toward `Complex Tech` and `Cultural Touchstones`

Full spec + respec rules: [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md).

#### Level 70+: Survey (Vault Heatmaps mitigation)

Survey is the Excavation planning tool for Static-heavy zones.

It reduces the **Lab Stability penalty** applied to crates you find during the buff.\n It does not change the Field’s crate bonus.

Recommended rules live in the canon heatmap spec:

* [Vault Heatmaps](../../expansion-plan/micro-loop-expansion/6.-vault-heatmaps-zone-strategy.md)

#### Level 80+: cross-skill masteries (synergy layer)

Excavation contributes to multiple pair masteries at `80/80`.

Notable ones:

* Excavation + Smelting — **Efficiency Engine** (Auto-Digger output edge)
* Excavation + Restoration — **Field Conservator** (Lab tether dust refund edge)
* Excavation + Appraisal — **Chain of Custody** (certification cost edge)

Full list: [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md).

#### Level 99: Mastery — “The Endless Vein”

Level 99 is the identity moment for Excavators.

Canon mastery perk (do not drift):

* **15% chance** for “Double Loot” drops on every find.

Expected integrations:

* Seismic Surge mastery hook: second Sweet Spot and extra strike.\n Spec: [Seismic Surge](../../expansion-plan/micro-loop-expansion/1.-the-seismic-surge-active-extraction.md).
* Blueprint hunting as a late-game supplier role.\n See [Skills Expansion](../../expansion-plan/skills-expansion.md) and [Skill-Gated "Ancient Blueprints"](../../expansion-plan/skills-expansion/4.-skill-gated-ancient-blueprints.md).

{% hint style="info" %}
Blueprint drops are an expansion hook.\n They should stay consistent with the post-MVP direction in [Expansion Plan](../../expansion-plan/).
{% endhint %}

### UI/UX requirements (so the skill feels real)

Minimum UI surfaces for Excavation:

* Skill level + % to next level on the Vault skill dashboard.\n See [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md).
* A tooltip breakdown for Crate chance:
  * Base (`15%`)
  * Tool bonus
  * Excavation passive bonus
  * Zone Static bonus (if any)
  * Per-action bonuses (Seismic Surge grade, Focused Survey)
  * Clamp indicator (`≤ 95%`)
* Level-up banner: `LEVEL <X> EXCAVATION REACHED`.

### Implementation notes (state + authority)

This skill touches economy-facing odds, so it must be server-owned.

Minimum persistent state:

* `excavation_xp`
* `excavation_level` (derived from XP is fine)
* `excavation_branch` (none until 60, then `urban_scavenger` or `tech_hunter`)

Minimum timed state:

* Focused Survey:
  * `focused_survey_active_until`
  * `focused_survey_cooldown_until`
* Zone Survey:
  * `survey_active_zone_id`
  * `survey_active_until`
  * `survey_cooldown_until`

Crate metadata that Excavation interacts with indirectly:

* `source_zone_id`
* `source_static_tier`

Authority rules:

* The client never computes “final crate chance” for outcomes.\n It can display it, but the server is source of truth.
* The client only sends intent:\n `EXTRACT`, `activate Focused Survey`, `Survey zone <id>`.

### Integrity constraints (non-negotiable)

* Extraction always resolves **exactly one** outcome (Scrap / Crate / Anomaly).
* No system is allowed to modify the base 5% Anomaly outcome.\n World events can add explicit overlays, but must not rewrite the base roll.\n See [2: The Mechanics](../2-the-mechanics/).
* Any bonus to Crate chance must be:
  * visible in UI,
  * flat/additive, and
  * clamped at `95%`.

### Telemetry (so tuning is real)

Track:

* Crates/hour by Excavation level band (manual vs passive).
* Effective crate chance breakdown usage (do players read tooltips?).
* Focused Survey activations and Scrap spent per day.
* Survey usage rate and resulting shatter rate delta for hot-zone crates.
* Blueprint acquisition rates at 99 (if shipped).

### Links

* Canon extraction rules and clamps: [2: The Mechanics](../2-the-mechanics/)
* Core skilling model and mastery perks: [5 - RPG Skilling System](./)
* Active Excavation ability (60+): [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* Excavation branches (60+): [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)
* Pair masteries (80/80): [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md)
* Manual extraction timing layer: [Seismic Surge](../../expansion-plan/micro-loop-expansion/1.-the-seismic-surge-active-extraction.md)
* Zone strategy + Survey mitigation: [Vault Heatmaps](../../expansion-plan/micro-loop-expansion/6.-vault-heatmaps-zone-strategy.md)
* Post-MVP hooks: [Expansion Plan](../../expansion-plan/)
