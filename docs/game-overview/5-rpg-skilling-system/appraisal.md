---
description: >-
  The merchant/intel skill. Powers crate previews, certification, market edges,
  and late-game oracle intel.
---

# Appraisal

## Appraisal

Appraisal is the “merchant + intel” skill.

It turns uncertainty into **bounded information**.

It also gates **trust mechanics** (certification) in the Bazaar.

Appraisal must not rewrite RNG.

It reveals and prices what already exists.

Canon anchors:

* Core loop + what Appraisal is allowed to surface: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md)
* Pre-open crate intel system: [Pre-Sift Appraisal (Crate Prep)](../../expansion-plan/micro-loop-expansion/4.-pre-sift-appraisal-crate-prep.md)
* Bazaar + certification + Appraisal 99 tax lane: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro/)
* 60+ active ability: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* 60+ branches: [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)
* 80/80 masteries: [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md)

### What Appraisal affects (and what it never touches)

Appraisal **does** affect:

* The ability to **preview** a crate before gambling deeper.
* The ability to **certify** items and surface hidden sub-stats.
* Bazaar efficiency edges (fees, daily vouchers, etc. depending on macro systems).
* Late-game zone intel (Heatmap trends, theme warnings).

Appraisal **never** affects:

* Lab Success/Fail odds.
* Lab stage rarity tables.
* Mint assignment.
* Condition roll.
* Field extraction odds.

### XP sources

Appraisal XP comes from **market participation**, not digging.

Canonical sources (Phase 4+ direction):

* Creating a Bazaar listing.
* Placing a bid.
* Winning an auction.
* Certifying an item.

If the Bazaar is not shipped yet, Appraisal XP can be deferred.

### Core kit

Appraisal has three “pillars”:

1. **Pre-Sift Appraisal** (crate preview)
2. **Certification** (trust + disclosure)
3. **Oracle intel** (late-game information advantage)

### Level milestones (player-facing)

#### Level 1–59: basic intel + early market competence

* You can participate in Bazaar flows.
* Appraisal is mostly “information surfaces” and minor fee edges.

Guardrail:

* Low/mid Appraisal must not reveal exact item catalog IDs from crates.

#### Level 60+: advanced skilling starts

At Appraisal level `60`, you unlock:

1. **Active ability:** **Hype Train** (visibility spike).
2. **Branch pick:** **Certified Valuator** or **Economic Insider**.
3. **Pre-Sift Appraisal upgrade:** reveal **one hidden sub-stat key** (not magnitude).

These follow the shared 60+ rules:

* [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)

**60+ active ability: Hype Train**

Hype Train is a paid visibility spike.

Hard rules:

* Visibility only.
* No price changes.
* No fee changes.
* No bid-rule changes.

Spec: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md).

**60+ branch pick: Certified Valuator vs Economic Insider**

Branches are build choices.

They must be explicit and visible.

* **Certified Valuator**
  * certification fee discount (`-25%` Scrap, tunable)
  * `+2%` HV on certification (once per item)
* **Economic Insider**
  * early warning for theme rollovers and Static shifts (`5m` early, recommended)

Spec + respec rules: [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md).

#### Level 80+: cross-skill masteries (synergy layer)

Appraisal participates in multiple `80/80` masteries:

* Excavation + Appraisal — **Chain of Custody** (cheaper cert for self-excavated items)
* Restoration + Appraisal — **Certified Restorer** (`+5%` HV once per item when restored+certified by you)
* Appraisal + Smelting — **Industrial Broker** (Appraisal XP on bulk auto-smelt, capped)

Full list: [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md).

#### Level 90–99: elite training gate (if used)

If the game uses the HI-gated training model:

* Appraisal is capped at `90` by default.
* An Influence Shop unlock lifts the cap to `99`.

Canon requirement spec: [Phase 4 requirements](../../implementation-plan/phase-4-the-high-curator-meta-game/phase-4-requirements.md).

#### Level 99: Mastery — “The Oracle” + “Master Trader”

Appraisal mastery is two things:

* **The Oracle**: premium intel surfaces.
* **Master Trader**: tax/fee edge.

Canon rules:

* Oracle can see item Condition pre-open.
* Oracle can see zone “trending” catalog IDs (Heatmap trend sight).
* Appraisal 99 reduces Archive Tax to `2.5%` on the seller.

See:

* [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro/)
* [Vault Heatmaps](../../expansion-plan/micro-loop-expansion/6.-vault-heatmaps-zone-strategy.md)

### Pillar 1 — Pre-Sift Appraisal (crate preview)

Pre-Sift Appraisal lives in **\[02] THE LAB**.

It is a paid action that reveals **ranges** and **bands**, not truth.

It does not change any underlying RNG.

Full spec: [Pre-Sift Appraisal (Crate Prep)](../../expansion-plan/micro-loop-expansion/4.-pre-sift-appraisal-crate-prep.md).

#### Key outputs (what you can reveal)

At low/mid levels, appraisal reveals:

* Condition range labels
* Mint probability band (`Low/Medium/High`)

At Appraisal `60+`, add:

* one hidden sub-stat **key** preview (not magnitude)

#### Success chance and cost (canonical tuning)

Use the default tuning from the Pre-Sift Appraisal spec:

* `p_success = clamp(30% + (Appraisal_Level * 0.7%), 30%, 90%)`
* Pre-sift cost baseline: `250` Scrap (stage-based scaling exists for post-open variants)

### Pillar 2 — Certification (trust + disclosure)

Certification is a Bazaar action.

It adds a permanent `Certified` badge.

It surfaces hidden sub-stats in a trusted way.

Key integrity rules:

* Certification is server-authoritative.
* It must be stored on the item:
  * `is_certified`
  * `certified_by_player_id`
* Scope must be enforced (self-owned or explicit request flow).

Canon requirement spec: [Phase 4 requirements](../../implementation-plan/phase-4-the-high-curator-meta-game/phase-4-requirements.md).

#### HV bonuses (stacking guardrails)

HV must stay readable.

Any “once per item” bonus must be enforced server-side.

Relevant Appraisal-linked bonuses:

* Branch: **Certified Valuator** `+2%` HV on certification (once per item)
* Mastery synergy: **Certified Restorer** `+5%` HV when restored by you + certified by you (once per item)

Stacking rules reference: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md).

### Pillar 3 — Oracle intel (late-game)

Oracle is not “better rolls”.

Oracle is **better information**.

#### Zone Trend Sight (pairs with Vault Heatmaps)

At Appraisal 99:

* show top `N` trending item catalog IDs per zone

Hard rule:

* Only Oracle sees exact catalog IDs.

Spec: [Vault Heatmaps](../../expansion-plan/micro-loop-expansion/6.-vault-heatmaps-zone-strategy.md).

#### Pre-open condition reveal

At Appraisal 99:

* show condition automatically on crate cards
* keep deeper intel (mint band, hidden-stat preview) behind explicit action + fee

This preserves “mastery premium”.

### Worked examples

#### Example A — appraisal success chance

If Appraisal is level `40`:

* `p_success = 30% + (40 * 0.7%) = 58%`

#### Example B — certification HV bonuses (once-per-item)

If you have Certified Valuator and certify an item:

* apply `+2%` HV once

If the same item is also restored by you and you have Certified Restorer mastery:

* apply an additional `+5%` HV once

Both must show as separate lines in the HV breakdown.

### UI/UX requirements

Minimum UI surfaces for Appraisal:

* Vault skill dashboard shows:
  * level
  * branch
  * masteries
* Lab crate cards show:
  * **\[APPRAISE]** button
  * cost + success chance
  * results panel (if success)
* Bazaar surfaces show:
  * `Certified` badge
  * `PROMOTED` badge during Hype Train
  * active Archive tax rate (2.5% if Appraisal 99)

UX beats reference: [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md).

### Implementation notes (state + authority)

Appraisal touches economy trust.

Assume server authority everywhere.

Minimum persistent state:

* `appraisal_xp`
* `appraisal_level`
* `appraisal_branch` (none until 60, then `certified_valuator` or `economic_insider`)
* `elite_training_unlocked` (if 90–99 is gated)

Minimum per-crate state (for Pre-Sift Appraisal):

* `crate_id`
* `appraised_by_player_id`
* `appraisal_result` (structured JSON)
* `appraised_at`

Minimum per-item state (for certification):

* `is_certified`
* `certified_by_player_id`
* `certified_at`
* `hidden_stats` (generated once)

Ability state:

* Hype Train cooldown and promoted listing target

### Integrity constraints (non-negotiable)

* Appraisal never changes RNG.
  * It only reveals bounded info.
* No free exact catalog IDs at low/mid levels.
* All certification writes are server-owned and audited.

### Telemetry

Track:

* Pre-Sift Appraisal usage rate and Scrap spent/day.
* Appraisal success rate by level band.
* Certification volume and conversion impact (sale time delta).
* Hype Train usage and abuse signals.
* Oracle usage:
  * Trend Sight panel open rate
  * zone-switch behavior after reading trends

### Links

* Loot identity + HV breakdown rules: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md)
* Bazaar + Appraisal macro effects: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro/)
* Pre-open crate intel: [Pre-Sift Appraisal (Crate Prep)](../../expansion-plan/micro-loop-expansion/4.-pre-sift-appraisal-crate-prep.md)
* Active ability (Hype Train): [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
* Branch picks: [Skill Sub-Specializations](../../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)
* Masteries: [Cross-Skill Masteries](../../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md)
* Zone intel pairing: [Vault Heatmaps](../../expansion-plan/micro-loop-expansion/6.-vault-heatmaps-zone-strategy.md)
