# Collection progression (sets and identity)

## Collection progression (sets and identity)

Collection progression turns “random drops” into long-horizon goals.

It also turns items into identity objects, not stat sticks.

Canon anchors:

* Item identity fields: [3 - The Loot & Collection Schema](../../3-the-loot-and-collection-schema.md)
* Mint, condition, HV lines: [The "Mint & Condition" System](../../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)
* Museum scoring + set bonus: [The Global Museum (Social Leaderboard)](../../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)

### What “collection progression” means here

You progress by completing **Sets**.

Each set completion grants a **permanent account buff**.

You also progress by upgrading your “taste.”

That means chasing low-mints, condition, and Prismatics.

### Set tracking (how players see it)

The Vault must show a set list.

Each set shows:

* Set name and short fiction hook.
* Required items as silhouettes.
* Filled slots with the owned item’s identity.
  * Name + mint.\n Condition stamp.\n Prismatic badge.\n Certified badge.
* Completion reward preview.

UI anchor: [6 - UI/UX Wireframe & Flow](../../6-ui-ux-wireframe-and-flow.md)

### Completion rules (what counts toward a set)

#### Slot definition

Each set slot references an `item_catalog_id`.

Any owned variant of that catalog item can fill the slot.

Identity changes value, not eligibility:

* Mint number
* Condition
* Prismatic state
* Hidden sub-stats (Appraisal)

#### One item, one slot (recommended)

An item can only be committed to one set slot at a time.

This avoids “one god item completes everything.”

If you want overlap later, do it explicitly.

### Set-lock (the key mechanic)

Set-lock is what makes completion meaningful.

Locking a relic into a set removes it from the free economy.

It is a permanent choice by default.

#### Lock behavior (recommended baseline)

When an item is set-locked:

* It cannot be listed or bid-traded.\n (No Bazaar escrow.)
* It cannot be smelted.\n (No Scrap conversion.)
* It cannot be dissolved.\n (No Prismatic → Credits.)
* It cannot be leased.\n (No rentals cheese.)
* It cannot be endowed.\n (Endowment is a separate permanent sink.)
* It **can** be submitted to the weekly Museum.\n Museum lock is a separate temporary lock.\n This is recommended because it’s not trade.

Canon: [Sample Collection Tiers](../../3-the-loot-and-collection-schema/sample-collection-tiers.md)

#### Why set-lock exists

It creates real decisions:

* Profit now (sell or smelt).
* Or identity forever (lock into a set).

It also creates scarcity pressure on the market.

### Rewards (what sets should grant)

Sets should reward **convenience, throughput, or playstyle flavor**.

They should not rewrite RNG surfaces.

Avoid:

* direct Anomaly chance changes,
* hidden stability buffs,
* “drop-rate buffs” phrased as flavor.

Safe reward types:

* Manual speed and feel improvements.\n Example: extract cooldown reduction.
* Automation efficiency.\n Example: battery cap or tick output.
* Lab support in explicit, capped ways.\n Example: flat stability bonus, small.
* Bazaar economics perks.\n Example: listing fee reduction (explicit).

Baseline example set rewards already referenced in the loot schema:

* “The Morning Ritual” → **Caffeine Rush** (`-0.5s` `[EXTRACT]` cooldown)
* “The 20th Century Kitchen” → `+10%` manual Scrap gain
* “The Digital Dark Age” → `+5%` Sift Stability (flat)
* “The High Delivery Gala” → `-15%` Bazaar listing fees

Source: [3 - The Loot & Collection Schema](../../3-the-loot-and-collection-schema.md)

### Set tiers (pacing and scope)

Use tiers so early sets finish quickly.

Later sets should take weeks.

Tiering model and examples live here:

* [Sample Collection Tiers](../../3-the-loot-and-collection-schema/sample-collection-tiers.md)

### Museum integration (weekly prestige layer)

Sets have two relationships with the Museum:

1. **Economic pressure**\n Museum themes drive demand for specific set items.
2. **Score multiplier**\n Submitting a full themed set can grant a weekly multiplier.\n Canon: [The Global Museum (Social Leaderboard)](../../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)

Important separation:

* Set-lock is permanent.\n It grants account buffs.
* Museum lock is weekly.\n It grants HI and rank.

### Telemetry (for tuning)

Track:

* Set start rate by tier.\n (Do players even engage?)
* Set completion time distribution.
* How many items are permanently set-locked.
* Market impact on set items.\n Price spikes after theme changes.
* Reward impact.\n Before/after throughput on set completion.
