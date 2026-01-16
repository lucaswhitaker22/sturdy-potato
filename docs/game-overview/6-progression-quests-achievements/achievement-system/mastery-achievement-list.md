# Mastery Achievement List

## Mastery Achievement List (long-grind receipts)

Mastery achievements are the OSRS-style “you put in the hours” signals.

They should be:

* deterministic,
* counter- or threshold-based,
* mostly identity rewards,
* rare enough to stay meaningful.

System anchors:

* taxonomy + reward/broadcast rules: [Achievement System](./)
* skill model + total level gates: [5 - RPG Skilling System](../../5-rpg-skilling-system/)
* canonical Field action names: [The Dig Site (Main Screen)](../../2-the-mechanics/the-dig-site-main-screen.md)
* canonical Lab stages + fail rules: [The Refiner (The Gambling Hub)](../../2-the-mechanics/the-refiner-the-gambling-hub.md)

{% hint style="info" %}
Mastery achievements can include hard counters.

They should still avoid RNG outcomes like “find a Unique.”
{% endhint %}

***

### Global rules (hard requirements)

* Category is always `mastery`.
* Progress is server-owned.
* Counters increment from validated events only.
* Rewards are identity-first.
* Broadcast rules:
  * level `99` mastery achievements **should** broadcast globally,
  * everything else is local toast + Dossier log.

Recommended reward types:

* titles (most common)
* profile frames (tiered)
* permanent dossier badges

Avoid:

* permanent raw power,
* odds changes,
* Stability changes,
* Museum score multipliers.

***

### Track A — Skill level mastery (1–99)

These are “hit a level” thresholds.

They should exist per-skill.

#### Level 60 (advanced layer unlock)

Level `60` is the first real identity choice.

It unlocks:

* an active ability, and
* a branch pick.

See: [5 - RPG Skilling System](../../5-rpg-skilling-system/).

**mastery\_skill\_060\_excavation — Excavation 60**

**Tier:** silver\
**Context:** You don’t dig. You survey.

**Unlock condition**

* Reach Excavation level `60`.

**Reward**

* Title: `Surveyor`

**Broadcast**

* local only

***

**mastery\_skill\_060\_restoration — Restoration 60**

**Tier:** silver\
**Context:** You learned how to lose without breaking.

**Unlock condition**

* Reach Restoration level `60`.

**Reward**

* Title: `Stable Hand`

**Broadcast**

* local only

***

**mastery\_skill\_060\_appraisal — Appraisal 60**

**Tier:** silver\
**Context:** You can smell a deal through static.

**Unlock condition**

* Reach Appraisal level `60`.

**Reward**

* Title: `Valuator`

**Broadcast**

* local only

**Notes**

* Feature-gate if Bazaar/Appraisal XP are not shipped.

***

**mastery\_skill\_060\_smelting — Smelting 60**

**Tier:** silver\
**Context:** You stopped sorting. You started processing.

**Unlock condition**

* Reach Smelting level `60`.

**Reward**

* Title: `Foreman`

**Broadcast**

* local only

***

#### Level 99 (mastery moment)

Level `99` is the global flex.

It should always broadcast.

The game already treats this as a “Master’s Badge” moment.

See: [5 - RPG Skilling System](../../5-rpg-skilling-system/).

**mastery\_skill\_099\_excavation — Excavation 99**

**Tier:** gold\
**Context:** The ground runs out before you do.

**Unlock condition**

* Reach Excavation level `99`.

**Reward**

* Profile frame: `ENDLESS VEIN`
* Title: `Endless Vein`

**Broadcast**

* global feed (high signal)

***

**mastery\_skill\_099\_restoration — Restoration 99**

**Tier:** gold\
**Context:** Nothing breaks unless you allow it.

**Unlock condition**

* Reach Restoration level `99`.

**Reward**

* Profile frame: `MASTER PRESERVER`
* Title: `Master Preserver`

**Broadcast**

* global feed (high signal)

***

**mastery\_skill\_099\_appraisal — Appraisal 99**

**Tier:** gold\
**Context:** You see value before it exists.

**Unlock condition**

* Reach Appraisal level `99`.

**Reward**

* Profile frame: `THE ORACLE`
* Title: `Auctioneer`

**Broadcast**

* global feed (high signal)

**Notes**

* Feature-gate if Bazaar/Appraisal XP are not shipped.

***

**mastery\_skill\_099\_smelting — Smelting 99**

**Tier:** gold\
**Context:** You turned garbage into doctrine.

**Unlock condition**

* Reach Smelting level `99`.

**Reward**

* Profile frame: `PURE YIELD`
* Title: `Pure Yield`

**Broadcast**

* global feed (high signal)

***

### Track B — Total Level mastery (account power bands)

Total Level is the “balanced account” metric.

It also gates zones, so these achievements double as “you unlocked content” receipts.

Canon gates:

* Total `100`: Sunken Mall
* Total `250`: Corporate Archive
* Total `380`: Sovereign Vault

See: [5 - RPG Skilling System](../../5-rpg-skilling-system/).

**mastery\_total\_100 — Total Level 100**

**Tier:** silver\
**Context:** You’ve cleared the tutorial tier.

**Unlock condition**

* Reach Total Level `100`.

**Reward**

* Title: `Field Specialist`

**Broadcast**

* local only

***

**mastery\_total\_250 — Total Level 250**

**Tier:** gold\
**Context:** You built a real account.

**Unlock condition**

* Reach Total Level `250`.

**Reward**

* Profile badge: `CORPORATE ACCESS`
* Title: `Senior Operator`

**Broadcast**

* local only (optional global later)

***

**mastery\_total\_380 — Total Level 380**

**Tier:** gold\
**Context:** You’re near-max. The Archive can’t ignore you.

**Unlock condition**

* Reach Total Level `380`.

**Reward**

* Profile frame: `SOVEREIGN CLEARANCE`
* Title: `Sovereign Clearance`

**Broadcast**

* global feed (optional, high signal)

***

**mastery\_total\_396 — Total Level 396 (max)**

**Tier:** gold\
**Context:** You finished the grind.

**Unlock condition**

* Reach Total Level `396` (99×4).

**Reward**

* Profile frame: `FOUNDER’S SEAL`
* Title: `Founder`

**Broadcast**

* global feed (high signal)

***

### Track C — Action volume mastery (long counters)

These achievements measure “played the loop” volume.

Use counters that are:

* easy to track,
* hard to fake,
* meaningful to identity.

#### Field volume

**mastery\_field\_001k\_extracts — 1,000 manual extracts**

**Tier:** silver\
**Context:** The field knows your rhythm.

**Unlock condition**

* Complete `1,000` manual **\[EXTRACT]** actions.

**Reward**

* Dossier badge: `FIELD HOURS III`

**Broadcast**

* local only

***

**mastery\_field\_010k\_extracts — 10,000 manual extracts**

**Tier:** gold\
**Context:** You’re not clicking. You’re working.

**Unlock condition**

* Complete `10,000` manual **\[EXTRACT]** actions.

**Reward**

* Title: `Grounded`
* Profile badge: `FIELD HOURS IV`

**Broadcast**

* local only

***

#### Lab volume

**mastery\_lab\_001k\_sifts — 1,000 sifts attempted**

**Tier:** gold\
**Context:** You have a relationship with risk.

**Unlock condition**

* Attempt **\[SIFT]** `1,000` times (any stage).

**Reward**

* Title: `Lab Rat (Veteran)`

**Broadcast**

* local only

***

#### Vault volume

**mastery\_vault\_010k\_smelt — 10,000 items smelted**

**Tier:** gold\
**Context:** You erased entire piles.

**Unlock condition**

* Smelt `10,000` items (single + bulk combined).

**Reward**

* Title: `Industrial`
* Profile badge: `SMELT VOLUME`

**Broadcast**

* local only

***

### Implementation notes (event mapping)

Keep this boring and reliable.

Recommended counter events:

* `extract_completed` → Field volume counters
* `sift_attempted` → Lab volume counters
* `smelt_completed` / `bulk_smelt_completed` → Smelt counters
* `skill_level_up` → skill thresholds (60/99)
* `total_level_changed` → total level thresholds

Hard rules:

* progress is incremental and server-owned
* reward grants are idempotent
* broadcasts are only fired once per achievement unlock
