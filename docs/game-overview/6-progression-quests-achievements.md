# 6 - Progression, Quests, Achievements

## Progression, Quests, Achievements

This page defines the player journey.

It stitches together systems that already have canonical specs.

Related:

* Loop context: [0 - Game Loop](0-game-loop.md)
* Tools and automation: [The Workshop (Progression)](2-the-mechanics/the-workshop-progression.md)
* Skill model and gates: [5 - RPG Skilling System](5-rpg-skilling-system/)
* Currencies and sinks: [Currency Systems](4-the-mmo-and-economy-macro/currency-systems.md)
* Weekly competition: [The Global Museum (Social Leaderboard)](4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)
* Player economy: [The Bazaar (Auction House)](4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)

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

Canon: [The Workshop (Progression)](2-the-mechanics/the-workshop-progression.md).

#### 2) Mastery progression (skills 1–99)

This is the “veteran advantage” track.

Core properties:

* Skills are permanent.
* Skills unlock active abilities and builds at 60+.
* Total Level gates late zones and content.

Canon: [5 - RPG Skilling System](5-rpg-skilling-system/).

#### 3) Collection progression (sets and identity)

This is the “completionist” track.

Core properties:

* Items have identity fields (mint, condition, HV).
* Set completion grants permanent account buffs.
* Set locking removes items from free use.

Canon: [3 - The Loot & Collection Schema](3-the-loot-and-collection-schema.md).

#### 4) Prestige progression (Museum + HI)

This is the “social ladder” track.

Core properties:

* HI is earned, not bought.
* HI buys permits and status.
* Museum submissions lock items for the week.

Canon: [The Global Museum (Social Leaderboard)](4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md).

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

Canon: [5 - RPG Skilling System](5-rpg-skilling-system/).

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

Canon nav model: [6 - UI/UX Wireframe & Flow](6-ui-ux-wireframe-and-flow.md).

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

Canon event model: ["The Great Static" Events (incl. Static Pulses)](../expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md).

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

Canon feed usage tone: [The Dig Site (Main Screen)](2-the-mechanics/the-dig-site-main-screen.md).

***

### System integrity notes (non-negotiable)

Quests and achievements must not rewrite core system math.

Hard rules:

* The Field’s `5%` Anomaly roll never changes.\n Canon: [The Dig Site (Main Screen)](2-the-mechanics/the-dig-site-main-screen.md).
* The Lab stage table is canonical.\n Canon: [The Refiner (The Gambling Hub)](2-the-mechanics/the-refiner-the-gambling-hub.md).
* HI cannot be purchased or traded.\n Canon: [Currency Systems](4-the-mmo-and-economy-macro/currency-systems.md).
* Museum submissions lock items for the week.\n Canon: [The Global Museum (Social Leaderboard)](4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md).

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
