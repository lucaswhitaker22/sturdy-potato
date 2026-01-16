---
description: >-
  How players unlock content and earn long-term goals via quests, milestones,
  and achievement tracks.
---

# 6 - Progression, Quests, Achievements

## Progression, Quests, Achievements

This page is the “stitching layer”.

It defines how players move from early loop → endgame identity.

System canon still lives in the individual specs.

Related anchors:

* Loop: [0 - Game Loop](../0-game-loop.md)
* Tools + automation: [The Workshop (Progression)](../2-the-mechanics/the-workshop-progression.md)
* Skills + Total Level: [5 - RPG Skilling System](../5-rpg-skilling-system/)
* Loot identity + sets: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md)
* Economy: [The Bazaar (Auction House)](../4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)
* Weekly prestige: [The Global Museum (Social Leaderboard)](../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)
* Currencies: [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md)

***

### 6.1 Design goals

Progression must feel layered.

Each layer must have a clear “next target.”

Goals:

* Make early play obvious and fast.
* Make mid-game choices meaningful.
* Make late-game goals social and rare.
* Tie every quest objective to an existing loop action.
* Avoid “daily chore” design.\n Weekly beats are fine.

Non-goals:

* No mandatory narrative grind to access core play.
* No quests that require premium currency.
* No achievement spam.\n Keep unlocks punchy.

{% hint style="info" %}
Rule of thumb: a quest should feel like a guided version of the real loop.\n It must not add a new mini-game.
{% endhint %}

***

### 6.2 The progression stack (what grows over time)

Progression in _Relic Vault_ is five stacks.

Each stack maps to a deck in the UI.

#### Stack A — Throughput power (Workshop)

This is your “account output.”

It increases Scrap/hour and Crate frequency.

Canonical sink: [The Workshop (Progression)](../2-the-mechanics/the-workshop-progression.md).

#### Stack B — Competence power (Skills)

This is your “success rate and information edge.”

It makes deeper Lab gambling viable.

Canonical gates: [5 - RPG Skilling System](../5-rpg-skilling-system/).

#### Stack C — Collection power (Sets)

Sets are long-horizon goals.

They pay passive bonuses and identity.

Schema anchor: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md).

#### Stack D — Economic power (Bazaar mastery)

This is your ability to convert finds into capital.

It should be knowledge-gated, not luck-gated.

Market anchor: [The Bazaar (Auction House)](../4-the-mmo-and-economy-macro/the-bazaar-auction-house.md).

#### Stack E — Social prestige (HI + Museum)

This is server-facing rank.

It unlocks permits, titles, and elite systems.

Currency anchor: [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md).

***

### 6.3 Progression gates (what gets locked, and why)

Gates prevent players from touching “top-tier RNG” too early.

They also create crisp milestones.

Recommended gate types:

1. **Tool tier gates** (Workshop).\n Used for throughput and automation.
2. **Skill level gates** (single-skill).\n Used for Lab viability and intel.
3. **Total level gates** (multi-skill).\n Used for new zones.
4. **HI gates** (prestige).\n Used for permits and identity unlocks.

Hard rule:

* Gates must be readable in UI.\n Show exact requirements everywhere.

Spec reference for total level gates:

* See “Total Level Gates” in [5 - RPG Skilling System](../5-rpg-skilling-system/).

***

### 6.4 Quests: what they are in this game

Quests are guided objectives with a clean reward.

They teach the loop, then get out of the way.

Quests should be short.

Target length:

* Early quests: `2–5` minutes.
* Mid quests: `10–20` minutes.
* Late quests: `30–90` minutes.\n Mostly “achievement-like.”

#### Quest categories

**1) Onboarding questline (mandatory, short)**

This is the first-session spine.

It should touch every deck once.

Example beats:

* Extract Scrap.\n Buy your first Workshop upgrade.
* Open a Crate.\n Choose Claim vs Sift once.
* Smelt duplicates.\n See Scrap flow.
* List one item.\n Learn deposits and tax.
* Donate one item.\n Receive your first HI.

**2) Zone unlock quests (optional gates)**

These are “permits with a story wrapper.”

They should require basic competence, not luck.

Examples:

* “Survey the Sunken Mall.”\n Perform `20` extracts in that zone.
* “Stabilize the Archive.”\n Complete `5` Lab Stage-2 Sifts.
* “Certified Access.”\n Appraise and certify `1` listing.

**3) Contract quests (repeatable, time-boxed)**

These are weekly or event contracts.

They are the live-ops wrapper for the same actions.

Examples:

* “Turn in `X` Scrap worth of smelts.”
* “Donate `Y` theme-tagged relics.”
* “Win `Z` Bazaar auctions.”

**4) Narrative quests (rare, high-value)**

These are content drops.

They unlock new mechanics or zones.

They should not be required for baseline play.

{% hint style="warning" %}
Never gate the core decks behind narrative.\n Gate upgrades and zones, not the ability to play.
{% endhint %}

***

### 6.5 Quest structure (canonical template)

Every quest should be expressible as:

* **Objective**: a measurable action.\n Example: “Sift to Stage 2.”
* **Context**: one sentence of fiction.
* **Rules**: exact counts and constraints.
* **Reward**: one primary reward + optional bonus.

#### Allowed objective types (preferred)

* Count actions:\n `Extract`, `Sift`, `Smelt`, `List`, `Bid`, `Donate`.
* Reach thresholds:\n “Hold `10,000 Scrap` once.”
* Unlock milestones:\n “Buy Tool Tier 3.”
* Skill checks:\n “Reach Restoration `20`.”

#### Avoid objective types

* RNG targets:\n “Find a Mythic.”\n These feel unfair.
* “Play X days.”\n This is a retention tax.

***

### 6.6 Quest rewards (what they should pay out)

Rewards must support the progression stack.

They must also feel “clean.”

#### Reward channels

* **Scrap**.\n Primary early reward.
* **Blueprints**.\n Permanent unlock tokens for Workshop paths.
* **HI**.\n Used for prestige unlocks.\n Never purchaseable.
* **Cosmetics**.\n Titles, frames, UI skins.
* **Convenience items**.\n Risk mitigation tools, if they exist.

#### Reward rules

* One quest = one headline reward.\n Don’t mix five currencies.
* Rewards must scale with player power.\n Use tier bands.
* Quest rewards must never invalidate the Workshop sink curve.

{% hint style="info" %}
When in doubt, pay Scrap + a cosmetic.\n Keep HI for Museum and major contracts.
{% endhint %}

***

### 6.7 Achievements: taxonomy and tracks

Achievements are permanent “receipts.”

They also provide long-term completion goals.

#### Track 1 — Milestones (one-time)

Examples:

* First Crate opened.
* First Stage-3 Sift success.
* First Shatter.\n Yes, celebrate it.
* First Bazaar sale.
* First Set completed.

#### Track 2 — Mastery (hard, long-term)

Examples:

* Reach skill level `60`.\n Unlocks advanced layer.
* Reach skill level `99`.\n Triggers global announcement.
* Total level `100 / 250 / 380`.

Reference behavior:

* See Mastery signals in [5 - RPG Skilling System](../5-rpg-skilling-system/).

#### Track 3 — Collection (completionism)

Examples:

* Complete `N` sets.
* Complete a full tier.\n Example: “All Uncommon Sets.”
* Complete a themed set line.\n Weekly Museum themes can point here.

#### Track 4 — Risk (Lab identity)

Examples:

* “Clean Run”: Sift from Stage 0 to 4 without a fail.
* “High Roller”: Attempt Stage 5 `10` times.
* “Cold Hands”: Fail Stage 5 and still profit that day.\n Needs definition.

#### Track 5 — Economy (Bazaar identity)

Examples:

* Sell `1M` Scrap total value.
* Win `25` auctions.
* Maintain `10` active listings.

#### Track 6 — Social (Museum identity)

Examples:

* Place top `10%` in a weekly theme.
* Donate `50` items in a week.
* Reach HI tier thresholds.\n If used.

***

### 6.8 Achievement rewards (what achievements grant)

Achievements should mostly grant identity.

They should rarely grant raw power.

Recommended rewards:

* Titles.\n “Junior Curator”, “Stable Hand”, “Lot Runner”.
* Profile frames.\n “Prismatic”, “Obsidian Dust”.
* Vault cosmetics.\n Banner, sticker, seal.
* Very small account perks.\n Only at major mastery points.

If you grant power:

* Keep it tiny.\n `≤ 1%` or pure convenience.
* Make it capped.\n No infinite stacking.

***

### 6.9 UX rules (quests + achievements)

This page defines behavior.\n Layout lives in the UI/UX spec.

UI anchor: [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md).

Rules:

* Quests must be trackable from any deck.
* Progress updates must be instant.\n Server-ledgered.
* Claiming rewards must be one click.
* Always show “next quest” after a claim.
* Achievements should batch notifications.\n No pop-up spam mid-Lab.

Recommended surfaces:

* Small quest tracker chip in the header.
* “Progression” screen with:\n Quests, Achievements, and Tracks.
* Post-action toasts:\n “Stage 2 success (3/5).”

***

### 6.10 Integrity rules (anti-exploit)

Quests and achievements are economy features.

Treat them like currency.

Rules:

* All progress is server-authoritative.
* Objective counters increment from validated events only.
* Rewards are granted once.\n Enforce idempotency keys.
* No “offline quest completion” unless explicitly designed.

{% hint style="danger" %}
Never grant quest rewards client-side.\n Treat it like a cash payout.
{% endhint %}

***

### 6.11 Telemetry (for tuning)

Track these per cohort (D1/D7/D30):

* Quest completion time per quest.
* Drop-off points in onboarding questline.
* Average “next upgrade” time.\n Workshop tier pacing.
* Achievement unlock distribution.\n Which tracks motivate.
* HI earned vs spent per week.\n If contracts mint HI.

Red flags:

* Quests completed but Workshop purchases stagnate.\n Reward curve too generous.
* Players ignore Museum.\n HI rewards too weak or unclear.
* Too many players attempt Stage 5 early.\n Gates too soft.

***

### Links (system specs)

* Quest mechanics + objective language: [Quest System](quest-system.md)
* Onboarding quest content: [Onboarding Quest List](quest-system/onboarding-quest-list.md)
* Unboarding quest content: [Unboarding Quest List](quest-system/unboarding-quest-list.md)
* Achievement taxonomy + reward rules: [Achievement System](achievement-system.md)
