# The Global Museum (Social Leaderboard)

## The Global Museum (Social Leaderboard)

The Global Museum is the weekly competitive layer.

It lives in **\[05] ARCHIVE**.

It forces a real choice: **sell now** or **lock for prestige**.

Canon anchors:

* Macro overview: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md)
* Loot identity + HV breakdown rules: [The "Mint & Condition" System](../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)
* Sets and set-lock rules: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md)
* Permanent sink lane: [Museum Endowments (Permanent Prestige)](../../expansion-plan/macro-loop-expansion/4.-museum-endowments-permanent-prestige.md)
* Social tier expansion: [Influence-Gated Social Tiers (and Syndicate Excavations)](../../expansion-plan/macro-loop-expansion/2.-influence-gated-social-tiers-and-syndicate-excavations.md)

### Design goals

* Make collecting and curation matter as an endgame.
* Create a non-tradable reward currency (HI) with real prestige value.
* Drive demand for specific sets and themes without changing loot odds.
* Create social proof moments that feel global.

Non-goals:

* Do not modify canonical drop tables.
* Do not create hidden scoring multipliers.
* Do not allow last-second “submit then sell” cheese.

### Weekly cycle

Each week is a “Museum Season”.

It has:

* a theme
* a submission window (the whole week)
* a fixed end timestamp
* finalized rewards on close

#### Theme selection

Themes are server-owned.

Theme examples:

* Pre-Collapse Cleaning Supplies
* Ancient Entertainment Tech
* The Age of Plastic

Theme announcement:

* Broadcast once at week start.
* Pin it on the Archive screen header.

### Participation: submissions and locks

#### Submission rules

* A player can submit up to `10` items.
* Items must be owned by the player.
* Items in escrow cannot be submitted.
* Leased items cannot be submitted.
* Endowed items are burned and cannot be submitted.

#### Museum lock (hard requirement)

Submitted items become `MUSEUM_LOCKED` until the week ends.

While locked, the item cannot be:

* sold or listed in the Bazaar
* smelted or dissolved
* leased
* endowed

Anti-cheese rule (recommended):

* If an item is submitted at any point during the week, it stays locked for the week.
* This holds even if the player later replaces it in their exhibit.

{% hint style="info" %}
This keeps the “profit vs prestige” decision real.
{% endhint %}

### Theme matching (what counts)

The theme defines a set of allowed tags.

Each item has one or more tags.

Only theme-matching items contribute score.

UI requirement:

* Show `MATCH` or `OFF-THEME` on each submission slot.

### Museum Score (MS)

Museum Score is a server-calculated total.

It must be reproducible.

It must be explainable.

#### Base scoring unit: item Total HV

Use the item’s **Total HV** as defined by the canonical breakdown lines.

That includes:

* rarity base HV
* condition multiplier
* low-mint multiplier (if `#001–#010`)
* prismatic multiplier (if applicable)
* explicit skill-based HV bonuses (if shipped)

Source of truth:

* [The "Mint & Condition" System](../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)

#### Museum-only multipliers

After summing Total HV across matching items, apply Museum-only multipliers.

Recommended formula:

$$
MS = \left(\sum HV_{total, item}\right) \times M_{set} \times M_{event}
$$

Where:

* $$M_{set}$$ is the set multiplier (if applicable).
* $$M_{event}$$ is a world-event multiplier (if active).

#### Set multiplier (weekly exhibit bonus)

If the player submits a full themed set, apply a multiplier.

Recommended baseline:

* $$M_{set} = 1.5$$ for a complete set match.

Hard rules:

* Set bonus must be explicit on the score breakdown.
* Set bonus must never apply to off-theme items.

### Leaderboards and rewards

The leaderboard is global.

It is finalized at week end.

#### Reward tiers (baseline)

Use percentile tiers.

Baseline rewards (from the macro spec):

* Top `1%` — **Grand Curator**
  * Unique UI badge
  * `500` Historical Influence
  * `1` Master Relic Key
* Top `10%` — **Senior Researcher**
  * `200` Historical Influence
  * `3` Encapsulated Crates
* Participation
  * `50` Historical Influence

{% hint style="warning" %}
If items like “Master Relic Key” are not shipped yet, replace with HI only. Keep the tier names and badge concept.
{% endhint %}

#### Historical Influence (HI)

HI is the primary Museum reward.

It is non-tradable.

It gates “The Unbuyables”.

See: [Currency Systems](currency-systems.md).

### Influence Shop (what HI buys)

HI spend should feel permanent and identity-driven.

Baseline catalog:

* Zone permits (new dig sites).
* Elite training unlocks (push skills `90–99`, if used).
* Username titles for the global feed.
* Permanent Vault expansions.
* Status tiers (social ranks).
* Deep-cycle battery permits.\n Small passive AA regen rate bonus.

Expansion lane:

* Team-pooled HI for temporary access.
* Spec: [Influence-Gated Social Tiers (and Syndicate Excavations)](../../expansion-plan/macro-loop-expansion/2.-influence-gated-social-tiers-and-syndicate-excavations.md)

### World Events integration (“The Great Static”)

World Events can apply a visible score multiplier.

They must not change loot odds.

Examples:

* `+10%` MS for a specific theme category.
* “Double Museum Week” (rare).

Spec: ["The Great Static" Events (incl. Static Pulses)](../../expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md)

### UI/UX requirements

Location: **\[05] ARCHIVE**.

Minimum UI:

* Theme name + description.
* Countdown timer to week end.
* `10` submission slots with lock indicators.
* A score preview panel with breakdown lines:
  * sum HV
  * set multiplier
  * event multiplier (if active)
* Global leaderboard (rank + score).
* “Your percentile” panel.
* Reward tier preview.

Feedback beats:

* Week start broadcast line.
* Week end finalize broadcast line.
* “Top 1% locked” callout on close.

### Authority and anti-abuse constraints (non-negotiable)

* All scoring is server-owned.
* Theme matching is server-owned.
* Items submitted at any point remain locked for the week (recommended).
* Do not allow borrowed/leased items to score.
* No client-trusted score previews.

### Telemetry (for tuning)

Track:

* Participation rate per week.
* Median number of submitted items.
* Item rarity distribution in submissions.
* Score distribution curve (detect runaway meta).
* HI minted per week and spent per week.
* “Submit then replace” attempts (anti-cheese pressure).
* Market impact: price spikes on theme tags.

### Links

* Macro overview: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md)
* Currency and HI: [Currency Systems](currency-systems.md)
* Endowments: [Museum Endowments (Permanent Prestige)](../../expansion-plan/macro-loop-expansion/4.-museum-endowments-permanent-prestige.md)
* Influence tiers: [Influence-Gated Social Tiers (and Syndicate Excavations)](../../expansion-plan/macro-loop-expansion/2.-influence-gated-social-tiers-and-syndicate-excavations.md)
