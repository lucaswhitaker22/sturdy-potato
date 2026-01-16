# Collection Achievement List

## Collection Achievement List (sets + completionism)

Collection achievements reward commitment to **sets** and **ownership identity**.

They should feel like “my vault has shape now.”

System anchors:

* taxonomy + reward rules: [Achievement System](./)
* canonical set-lock + tiering rules: [Sample Collection Tiers](../../3-the-loot-and-collection-schema/sample-collection-tiers.md)
* set schema + HV stacking guardrails: [3 - The Loot & Collection Schema](../../3-the-loot-and-collection-schema.md)
* mint/condition identity layers: [The "Mint & Condition" System](../../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)
* prismatic chase layer (feature-gated): [The "Shiny" Mechanic](../../3-the-loot-and-collection-schema/the-shiny-mechanic.md)

{% hint style="info" %}
Collection achievements should mostly be **deterministic**:

* “complete X sets”
* “complete a Tier-3 set”
* “complete a set line”

Rare identity finds (low mint, prismatic) can exist, but keep them cosmetic-only.
{% endhint %}

***

### Global rules (hard requirements)

* Category is always `collection`.
* Progress is server-owned.
* Set completion is the canonical trigger.
  * The client never “declares” a set complete.
* Achievements never change:
  * drop odds,
  * mint odds,
  * Museum scoring math,
  * set completion rules.
* Feature gates apply:
  * Prismatic achievements only exist if Prismatics ship.
  * Museum-adjacent achievements only exist if the Museum ships.

Reward guidance:

* Titles and frames are best.
* Avoid currency payouts. If you must, keep it tiny and one-time.

Broadcast guidance:

* Local toasts for most.
* Optional global feed only for extremely high-signal “collector flex” moments.

***

### Track A — Set completion ladders (core)

These are the backbone achievements.

They motivate long-term play without relying on luck.

### coll\_001 — First Set Complete

**Tier:** silver\
**Context:** A small collection is still a collection.

**Unlock condition**

* Complete `1` full set (any tier).

**Reward**

* Profile frame: `CABINET (BRONZE)`

**Broadcast**

* local only

***

### coll\_010 — Collector I

**Tier:** silver\
**Context:** You stopped chasing drops and started chasing patterns.

**Unlock condition**

* Complete `5` sets total.

**Reward**

* Title: `Collector`

**Broadcast**

* local only

***

### coll\_011 — Collector II

**Tier:** gold\
**Context:** Your vault is becoming a museum.

**Unlock condition**

* Complete `25` sets total.

**Reward**

* Profile badge: `COLLECTOR II`

**Broadcast**

* local only

***

### coll\_012 — Collector III

**Tier:** gold\
**Context:** You are the meta.

**Unlock condition**

* Complete `50` sets total.

**Reward**

* Profile frame: `CABINET (GOLD)`
* Title: `Curator`

**Broadcast**

* global feed (optional, high signal)

***

### Track B — Tier-based set mastery (T0 → T5)

These teach players that set tiers “touch different systems.”

Tier canon: [Sample Collection Tiers](../../3-the-loot-and-collection-schema/sample-collection-tiers.md).

### coll\_020 — Tutorial Set (T0)

**Tier:** silver\
**Context:** You learned how set-lock changes the economy.

**Unlock condition**

* Complete `1` T0 set.

**Reward**

* Dossier stamp: `SET-LOCKED`

**Broadcast**

* local only

***

### coll\_021 — Field Set (T1)

**Tier:** silver\
**Context:** Throughput is a collection reward.

**Unlock condition**

* Complete `1` T1 set.

**Reward**

* Title: `Field Collector`

**Broadcast**

* local only

***

### coll\_022 — Progression Set (T2)

**Tier:** silver\
**Context:** Your machines got smarter because your vault did.

**Unlock condition**

* Complete `1` T2 set.

**Reward**

* Profile badge: `PROGRESSION SET`

**Broadcast**

* local only

***

### coll\_023 — Lab Set (T3)

**Tier:** gold\
**Context:** You collected power where it hurts.

**Unlock condition**

* Complete `1` T3 set.

**Reward**

* Title: `Lab Archivist`

**Broadcast**

* local only

***

### coll\_024 — Economy Set (T4)

**Tier:** gold\
**Context:** You collected leverage.

**Unlock condition**

* Complete `1` T4 set.

**Reward**

* Profile badge: `MARKET SET`
* Title: `Broker`

**Broadcast**

* local only

***

### coll\_025 — Prestige Set (T5)

**Tier:** gold\
**Context:** You collected a flex.

**Unlock condition**

* Complete `1` T5 set.

**Reward**

* Profile frame: `SHOWCASE`

**Broadcast**

* global feed (optional, high signal)

***

### Track C — “Set lines” (completionist goals)

These depend on how you ship the catalog.

If you don’t have explicit “lines”, hide these.

Examples of “lines”:

* “All T0 tutorial sets”
* “All Kitchen sets”
* “All Digital Dark Age sets”

### coll\_030 — Line Complete I

**Tier:** gold\
**Context:** You finished a shelf, not a set.

**Unlock condition**

* Complete `1` defined set line (server-defined grouping).

**Reward**

* Title: `Shelf Finisher`

**Broadcast**

* local only

**Notes**

* Requires `set_line_id` grouping support in the catalog.

***

### coll\_031 — Line Complete II

**Tier:** gold\
**Context:** Your vault has sections now.

**Unlock condition**

* Complete `5` set lines.

**Reward**

* Profile frame: `ARCHIVE SHELVES`

**Broadcast**

* global feed (optional)

**Notes**

* Hide until set lines are real.

***

### Track D — Identity finds (optional “flex”, cosmetic-only)

These are luck-influenced.

Keep them cosmetic-only and never required.

#### Low mint (feature is Phase 3+)

Low mint canon: `#001–#010` is a `1.5×` HV multiplier.\
See: [The "Mint & Condition" System](../../3-the-loot-and-collection-schema/the-mint-and-condition-system.md).

### coll\_040 — Low Mint Holder

**Tier:** gold\
**Context:** You found history early.

**Unlock condition**

* Own any item with mint `<= 10`.

**Reward**

* Profile badge: `LOW MINT`

**Broadcast**

* local only (optional global later)

***

### coll\_041 — Mint #001 (Any Catalog)

**Tier:** gold\
**Context:** First of its kind.

**Unlock condition**

* Own any item with mint `#001`.

**Reward**

* Profile frame: `FIRST PRESSING`
* Title: `First Pressing`

**Broadcast**

* global feed (high signal)

{% hint style="warning" %}
This is a pure brag receipt.

It must stay cosmetic-only.
{% endhint %}

***

#### Prismatic (feature-gated, Phase 5+)

Prismatic canon: `1%` roll on successful SIFT, `3×` HV.\
See: [The "Shiny" Mechanic](../../3-the-loot-and-collection-schema/the-shiny-mechanic.md).

### coll\_050 — Prismatic Keeper

**Tier:** gold\
**Context:** Static touched it.

**Unlock condition**

* Own `1` Prismatic item (not dissolved).

**Reward**

* Profile badge: `PRISMATIC`

**Broadcast**

* local only (Prismatic find itself already broadcasts globally)

**Notes**

* Hide if Prismatics are not shipped.

***

### coll\_051 — Prismatic Set (optional)

**Tier:** gold\
**Context:** You didn’t just find one. You curated it.

**Unlock condition**

* Complete a set where all required items are Prismatic (if shipped).

**Reward**

* Profile frame: `PRISMATIC CABINET`
* Title: `Prismatic Curator`

**Broadcast**

* global feed (optional, very high signal)

**Notes**

* This is extreme.
* Hide unless you explicitly support “variant-qualified sets.”

***

### Track E — Museum-adjacent collection moments (feature-gated)

These are still “collection flavored,” but they touch the weekly prestige layer.

Only include them if the Museum ships.

Museum canon: [The Global Museum (Social Leaderboard)](../../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md).

### coll\_060 — Full Set Exhibit

**Tier:** gold\
**Context:** You submitted a complete story, not a pile.

**Unlock condition**

* Submit a full themed set to the Museum in a single week (server-defined).

**Reward**

* Title: `Exhibitor`

**Broadcast**

* local only

**Notes**

* This should align with the Museum’s set multiplier concept (`M_set`).

***

### Implementation notes (event mapping)

Recommended server events:

* `set_completed(set_id, set_tier)` → Tracks A + B
* `completed_set_count_changed(total)` → ladder checks (5/25/50)
* `set_line_completed(set_line_id)` → Track C (if shipped)
* `item_minted(mint_number)` → low mint checks (<=10, ==1)
* `prismatic_obtained(item_id)` → Track D prismatic (if shipped)
* `museum_full_set_submitted(week_id, set_id)` → Track E (if shipped)

Hard rules:

* all achievements are idempotent on unlock
* “own item” checks must respect lock states, but ownership is still ownership
* do not award or revoke achievements on trade after unlock (one-time receipts)
