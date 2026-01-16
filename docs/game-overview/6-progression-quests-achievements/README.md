---
description: >-
  How players unlock content and earn long-term goals via quests, milestones,
  and achievement tracks.
---

# 6 - Progression, Quests, Achievements

## Progression, Quests, Achievements

This page defines the player journey.

It stitches together systems that already have canonical specs.

Related:

* Loop context: [0 - Game Loop](../0-game-loop.md)
* Tools and automation: [The Workshop (Progression)](../2-the-mechanics/the-workshop-progression.md)
* Skill model and gates: [5 - RPG Skilling System](../5-rpg-skilling-system/)
* Currencies and sinks: [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md)
* Weekly competition: [The Global Museum (Social Leaderboard)](../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)
* Player economy: [The Bazaar (Auction House)](../4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)

***

### Goals

This system must:

* Give players a clear next goal, every session.
* Teach the loop without walls of text.
* Create long-run goals without changing canonical RNG.
* Reward mastery with identity, not raw power.

Non-goals:

* No stealth drop-rate buffs from quests or achievements.
* No “mandatory chores” that beat the core loop.

***

### The four progression pillars

Progression comes from four tracks that interlock.

#### 1) Power progression (Scrap → Workshop)

This is the “numbers go up” track.

Core actions:

* Earn Scrap in the Field and by Smelting.
* Spend Scrap on tools, upgrades, and offline capacity.

Canon: [The Workshop (Progression)](../2-the-mechanics/the-workshop-progression.md).

#### 2) Mastery progression (skills 1–99)

This is the “veteran advantage” track.

Core properties:

* Skills are permanent.
* Skills unlock active abilities and builds at 60+.
* Total Level gates late zones and content.

Canon: [5 - RPG Skilling System](../5-rpg-skilling-system/).

#### 3) Collection progression (sets and identity)

This is the “completionist” track.

Core properties:

* Items have identity fields (mint, condition, HV).
* Set completion grants permanent account buffs.
* Set locking removes items from free use.

Canon: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md).

#### 4) Prestige progression (Museum + HI)

This is the “social ladder” track.

Core properties:

* HI is earned, not bought.
* HI buys permits and status.
* Museum submissions lock items for the week.

Canon: [The Global Museum (Social Leaderboard)](../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md).

***

### Gates and pacing (what unlocks what)

Use gates to pace players into the full loop.

Use the lightest gate that achieves the goal.

#### Gate types (ordered by “harshness”)

1. **Soft gate (recommended default)**
   * Show “Recommended power”.
   * Let players fail safely.
2. **Skill gate**
   * Require a minimum skill level for a tool, zone, or action.
3. **Total Level gate**
   * Require balanced progression.
   * Use sparingly.
4. **HI permit gate**
   * Make access a prestige reward, not a grind tax.

#### Canon Total Level gates (baseline)

These already exist in the skill spec.

* Sunken Mall: Total Level `100`
* Corporate Archive: Total Level `250`
* Sovereign Vault: Total Level `380`

Canon: [5 - RPG Skilling System](../5-rpg-skilling-system/).

{% hint style="info" %}
Do not use quests to bypass Total Level gates.

Quests can _introduce_ the gate.

They should not invalidate it.
{% endhint %}

***

### Quest system (“Archive Directives”)

Quests exist to do three things:

* Onboard new players into the 5-deck loop.
* Create short-term goals that pay into long-term tracks.
* Provide narrative framing in a UI-first game.

#### Where quests live

Location: **\[05] ARCHIVE**.

This aligns with the “mission control” vibe in the UI map.

Canon nav model: [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md).

#### Quest types (baseline)

**A) Onboarding chain (one-time)**

This chain teaches the loop in order.

It should finish in `15–30m`.

**B) Daily directives (repeatable)**

These are low-friction goals.

They should take `5–15m`.

They should never require the Bazaar.

**C) Weekly contracts (repeatable)**

These feed the Museum week.

They should encourage set locking and exhibit planning.

**D) Event contracts (time-boxed)**

These attach to world events.

They must be explicit about timing and modifiers.

Canon event model: ["The Great Static" Events (incl. Static Pulses)](../../expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md).

#### Quest anatomy (data shape)

Each quest should define:

* `id` and `type` (onboarding / daily / weekly / event)
* `requirements` (gates and prerequisites)
* `objectives` (server-tracked counters)
* `rewards` (explicit lines)
* `expiry` (optional)
* `antiCheese` rules (optional)

#### Objective templates (use these everywhere)

Keep objectives measurable and server-owned.

Field / Lab:

* Complete `N` manual **\[EXTRACT]** actions.
* Obtain `N` Encapsulated Crates.
* Perform `N` **\[SIFT]** attempts (any stage).
* Successfully **\[CLAIM]** a relic at Stage `X+`.

Vault / Smelting:

* Smelt `N` items of tier `Junk/Common`.
* Complete `N` set entries (not necessarily full sets).
* Lock `N` items into a set (if set-lock exists).

Bazaar:

* Create `N` listings (no requirement to sell).
* Win `N` auctions (cap per week).

Archive:

* Submit `N` theme-matching items to the Museum.
* Earn `N` Museum Score (MS) this week.

#### Reward templates (safe by default)

Rewards should primarily be:

* Scrap (soft currency).
* Cosmetics, titles, badges.
* Convenience unlocks (extra listing slot, extra preset slot).

Avoid:

* Permanent raw power from achievements.\n That belongs in skills, sets, or HI.

Allowed “power” rewards (must be small and explicit):

* One-time Workshop discount coupons.\n Must have a cap.\n Must not stack infinitely.
* One-time “training boosts” (XP only).\n Must be short and capped.

{% hint style="warning" %}
Do not reward direct Stability, Crate chance, or Anomaly chance.\n Those are core RNG surfaces.\n Keep them in their canonical specs.
{% endhint %}

#### Onboarding quest chain (recommended baseline)

This chain teaches the loop in 10 beats.

1. **Boot Sequence**
   * Complete `10` manual extracts.
   * Reward: `250` Scrap.
2. **First Crate**
   * Obtain `1` Encapsulated Crate.
   * Reward: `1` extra tray slot unlock (if used) or `500` Scrap.
3. **Enter the Lab**
   * Open `1` crate (Stage 0).
   * Reward: `100` Scrap + `5` Fine Dust.
4. **First Gamble**
   * Perform `1` sift at Stage 1+.
   * Reward: `10` Fine Dust.
5. **Claim Discipline**
   * Use **\[CLAIM]** at Stage 1+.
   * Reward: `1,000` Scrap.
6. **The Vault Matters**
   * Smelt `3` Junk items.
   * Reward: `750` Scrap.
7. **Set Awareness**
   * Add `1` item to a set tracker.
   * Reward: cosmetic “Archive Label” (UI tag).
8. **The Bazaar Door**
   * Create `1` listing.
   * Reward: `1` listing slot for `24h` (temporary) or `2,000` Scrap.
9. **Museum Week**
   * Submit `1` theme-matching item.
   * Reward: `25` HI (starter grant).
10. **Your First Title**

* Finish the chain.
* Reward: title “Field Agent”.

Notes:

* Reward HI once.\n Teach that it is scarce and non-tradable.
* Keep the chain un-failable.\n No “sell an item” requirements.

***

### Achievements (permanent account records)

Achievements are long-run markers.

They are not a quest substitute.

#### Categories (recommended)

* **Skill**: level milestones, 99 mastery.
* **Risk**: Stage 3/4/5 claims, shatter streaks survived.
* **Economy**: first sale, total tax paid, highest sale.
* **Collection**: first full set, `10/25/50` sets completed.
* **Prestige**: Museum top `10%`, top `1%`, endowment.
* **Legacy**: first Unique find, first Prismatic, low-mint finds.

#### Rewards (recommended)

Achievements should pay identity rewards:

* Titles in the global feed.
* UI frames and nameplate accents.
* Profile stats and “Archive dossier” pages.

Optional minor rewards:

* Small Scrap grants.\n Keep them one-time.
* Cosmetic tokens.\n Spend in an “Archive Store” if shipped.

#### Broadcast rules (keep the feed clean)

Broadcast only high-signal achievements:

* Any level `99`.
* Any Unique reveal.
* Any Prismatic reveal.
* Museum Top `1%` on week close.

Everything else should be local-only.

Canon feed usage tone: [The Dig Site (Main Screen)](../2-the-mechanics/the-dig-site-main-screen.md).

***

### System integrity notes (non-negotiable)

Quests and achievements must not rewrite core system math.

Hard rules:

* The Field’s `5%` Anomaly roll never changes.\n Canon: [The Dig Site (Main Screen)](../2-the-mechanics/the-dig-site-main-screen.md).
* The Lab stage table is canonical.\n Canon: [The Refiner (The Gambling Hub)](../2-the-mechanics/the-refiner-the-gambling-hub.md).
* HI cannot be purchased or traded.\n Canon: [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md).
* Museum submissions lock items for the week.\n Canon: [The Global Museum (Social Leaderboard)](../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md).

***

### Telemetry (for tuning)

Track these to tune pacing without guesswork.

Quests:

* Onboarding completion rate.\n Time-to-completion.\n Drop-off step.
* Daily directive engagement.\n Reward claim rate.
* Weekly contract completion distribution.

Progression:

* Scrap earned vs spent by cohort (D1/D7/D30).
* Tool tier distribution.\n Battery cap pressure.
* Total Level distribution vs zone access.

Achievements:

* First-time milestones per day.\n Level 60 and 99 rates.
* Broadcast volume per hour.\n Feed spam risk.

## Relic Vault: Part 6 — Progression, Quests, Achievements

This system answers one question: “What should I do next?”

It also turns mastery into visible status.

Related anchors:

* Loop context: [0 - Game Loop](../0-game-loop.md)
* Permanent power: [The Workshop (Progression)](../2-the-mechanics/the-workshop-progression.md)
* Skill gates: [5 - RPG Skilling System](../5-rpg-skilling-system/)
* Prestige currency: [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md)
* Weekly loop: [The Global Museum (Social Leaderboard)](../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)

***

### 6.1 Design goals

Progression must feel layered.

Each layer must have a clear “next target.”

Goals:

* Make early play obvious and fast.
* Make mid-game choices meaningful.
* Make late-game goals social and rare.
* Tie every quest to an existing loop action.
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
