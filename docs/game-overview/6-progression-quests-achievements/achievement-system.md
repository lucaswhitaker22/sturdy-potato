# Achievement System

## Achievement System (Permanent Records)

Achievements are **permanent receipts**.

They turn long-term play into visible status.

They should feel like the Archive stamping your dossier.

Related anchors:

* Progression framing: [6 - Progression, Quests, Achievements](./)
* Quests (short-term goals): [Quest System](quest-system.md)
* Global feed + what’s worth broadcasting: [Phase 3: The "Connected World" (The MMO Layer)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/4rU38xhwZ4ktq4Txw2Ib)

***

### Design goals

Achievements must:

* Reward mastery with **identity**, not raw power.
* Create long-horizon goals that don’t rely on luck.
* Provide clean “moment” triggers for the global feed.
* Stay consistent with canonical system math.

Achievements must not:

* Change drop odds, stability, mint odds, or scoring.
* Spam popups during Lab risk moments.
* Grant infinite stacking bonuses.

{% hint style="info" %}
Quests tell you what to do next.

Achievements recognize what you’ve already proven.
{% endhint %}

***

### Where achievements live (UI)

Primary location: **\[05] ARCHIVE**.

Recommended surfaces:

* **Dossier** page with categories and completion %.
* **Badge wall** (featured achievements, pinned by player).
* **Notification batching** (post-action toasts, no modal spam).

UI behavior should match:

* [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md)

***

### Achievement types (taxonomy)

Use these categories everywhere.

#### 1) Milestones (one-time, early)

These teach and celebrate.

Examples:

* First manual extract.
* First crate obtained.
* First sift attempt.
* First shatter.
* First Bazaar listing created.
* First Museum submission.

#### 2) Mastery (levels and long grinds)

These are the “OSRS moments”.

Examples:

* Reach level `60` in a skill.
* Reach level `99` in a skill.
* Reach Total Level `100 / 250 / 380`.

Skill model anchor: [5 - RPG Skilling System](../5-rpg-skilling-system/).

#### 3) Risk (Lab identity)

These celebrate pushing the needle.

Examples:

* Claim at Stage `3+` for the first time.
* Attempt Stage `5` `10` times.
* “Clean Run”: Sift from Stage 0 → Stage 4 without a fail.

Lab rules anchor: [The Refiner (The Gambling Hub)](../2-the-mechanics/the-refiner-the-gambling-hub.md).

#### 4) Collection (completionism)

These tie to sets and identity.

Examples:

* Complete your first full set.
* Complete `10 / 25 / 50` sets.
* Complete a full tier line (e.g., “All Uncommon Sets”, if shipped).

Set rules anchor: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md).

#### 5) Economy (Bazaar identity)

These create market persona.

Examples:

* First successful sale.
* Total Scrap earned from sales milestones.
* Highest single sale milestone.

Bazaar rules anchor: [The Bazaar (Auction House)](../4-the-mmo-and-economy-macro/the-bazaar-auction-house.md).

#### 6) Prestige (Museum + HI)

These reflect server-facing rank.

Examples:

* Place Top `10%` in a Museum week.
* Place Top `1%` in a Museum week.
* Complete an Endowment (if shipped).

Museum rules anchor: [The Global Museum (Social Leaderboard)](../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md).

#### 7) Legacy (rare receipts)

These are high-signal, low-frequency.

Examples:

* First Unique reveal.
* First Prismatic reveal.
* First low-mint find (e.g., mint `<= 10`).

Loot identity anchor: [The "Mint & Condition" System](../3-the-loot-and-collection-schema/the-mint-and-condition-system.md).

***

### Rewards (what achievements grant)

Achievements should pay identity rewards.

Recommended reward types:

* Titles.
* Profile frames.
* Vault UI skins (cosmetic only).
* Stamps and badges shown in leaderboards.

Optional minor rewards (use sparingly):

* One-time Scrap grants.
* Cosmetic tokens (if an Archive Store exists).

{% hint style="warning" %}
Avoid permanent raw power from achievements.

Power belongs in:

* skills,
* sets,
* HI shop unlocks.
{% endhint %}

Currency constraints:

* HI is non-tradable and not purchasable.\
  See: [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md).

***

### Global broadcast rules (keep the feed clean)

Broadcast only high-signal achievements.

Recommended broadcast triggers:

* Any skill level `99`.
* Any Unique reveal.
* Any Prismatic reveal.
* Museum week close:
  * Top `1%` placements.
* Bazaar sales:
  * Unique sale.
  * Prismatic sale.
  * Mythic+ sale above a threshold (tune later).

Everything else should be:

* a local toast, and
* a log entry in the Dossier.

Feed vibe anchor: [Phase 3: The "Connected World" (The MMO Layer)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/4rU38xhwZ4ktq4Txw2Ib).

***

### Progress tracking (how multi-step achievements work)

Most achievements are either:

* **one-shot** (unlock instantly), or
* **counter-based** (e.g., `10/25/50`).

Rules:

* Progress updates must be server-authoritative.
* Progress updates should be incremental, not recalculated from scratch.
* “One-time” unlocks must be immutable.

Recommended UX:

* Show `x/y` progress for counters.
* Show exact unlock condition text.
* Show reward preview.

***

### Minimal data model (conceptual)

Store achievements as a stable catalog plus per-player progress.

#### Catalog record

* `achievement_id`
* `title`
* `description`
* `category`
* `tier` (bronze/silver/gold or 1/2/3)
* `criteria` (structured)
* `rewards` (structured)
* `broadcast_on_unlock` (boolean)

#### Player progress record

* `player_id`
* `achievement_id`
* `progress` (number, default 0)
* `unlocked_at` (timestamp, nullable)
* `claimed_at` (timestamp, nullable)

Claim rule:

* Cosmetic-only rewards can auto-grant.
* Currency rewards should use a claim step for clear UX.

***

### Integrity rules (non-negotiable)

* Achievements never modify canonical odds.
* Achievements never modify Museum scoring.
* All unlocks and rewards are server-owned.
* Reward grants must be idempotent.
* No client-trusted counters for economy-impacting achievements.

Canonical systems to keep aligned:

* Field odds and immutable anomaly chance: [The Dig Site (Main Screen)](../2-the-mechanics/the-dig-site-main-screen.md)
* Lab stage table and stability rules: [The Refiner (The Gambling Hub)](../2-the-mechanics/the-refiner-the-gambling-hub.md)
* Museum lock + scoring expectations: [The Global Museum (Social Leaderboard)](../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)

***

### Example achievement list (baseline set)

Use these as canonical seeds.

#### Early

* “First Contact”: do `1` manual extract.
* “Containment Breach”: obtain `1` crate.
* “First Gamble”: attempt `1` sift.
* “Glass Break”: shatter `1` crate.

#### Mid

* “Stage Diver”: claim at Stage `3+` once.
* “Certified”: certify `1` item (if shipped).
* “Collector”: complete `1` set.

#### Late

* “High Roller”: attempt Stage `5` `10` times.
* “Curator”: place Top `10%` in a Museum week.
* “Grand Curator”: place Top `1%` in a Museum week.
* “Master”: reach level `99` in any skill.

***

### Telemetry (for tuning)

Track:

* Unlock rate by category and player age (D1/D7/D30).
* Time-to-60 and time-to-99 per skill.
* Feed broadcast volume per hour (spam risk).
* Achievement completion funnel for multi-step counters.
* Correlation between achievement pursuit and:
  * museum participation,
  * sift depth,
  * market activity.
