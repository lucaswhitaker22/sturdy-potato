# The Dig Site (Main Screen)

## \[01] THE FIELD — The Dig Site (Main Screen)

The Dig Site is the player’s primary screen.

It is the **input** side of the loop. It produces Scrap, Crates, and Anomalies.

Use this page as the canonical spec for “extraction.”

Related:

* Full loop context: [0 - Game Loop](../0-game-loop.md)
* Micro/meso rules master doc: [2: The Mechanics](../2-the-mechanics.md)
* AA system spec: [Archive Authorization (AA) System Spec](../archive-authorization-aa-system-spec.md)
* Skill powering this screen: [Excavation](../5-rpg-skilling-system/excavation.md)

***

### Goals

This screen must:

* Feel **fast** and **heavy** (terminal clicks, scanlines, static).
* Be readable at a glance.
* Make “one more extract” irresistible.
* Never leak “exact mint math” or “exact catalog IDs.”

***

### Screen layout (recommended)

#### Primary components

* **Header (“Vitals”)**
  * Scrap balance.
  * Crate tray usage.
  * Archive Authorizations (AA) gauge.\n Capped by Scanner Battery.
  * Scanner Battery / offline buffer (once automation exists).
  * Overload meter (if enabled; see “Anomaly Overload”).
* **Main action block**
  * Large button: **\[EXTRACT]**
  * Survey progress bar (fills each attempt).
  * Cooldown state (disabled button + gauge animation).
* **Zone panel**
  * Current zone name.
  * Static intensity heatmap.
  * Zone modifier summary (Crate bonus, Lab penalty).
* **Feed (global + local blend)**
  * Big wins, big shatters, rare anomalies.
  * The feed is social proof. It drives risk-taking later in the Lab.

#### Secondary components (optional, but useful)

* “Tool readout” (equipped tool tier, extraction speed, passive power).
* Quick nav buttons to \[02] LAB, \[03] VAULT, \[04] BAZAAR, \[05] ARCHIVE.

***

### Core action: Manual extraction (Active Dig)

Manual extraction is the default interaction.

It should stay viable forever, even after automation.

#### Archive Authorizations (AA) (active play limiter)

AA is the Archive’s bureaucratic “clearance” to run high-powered field scans.

Rules:

* Manual **\[EXTRACT]** costs `1` AA per attempt.
* AA regenerates over time.\n Baseline tuning: `+1 AA / 10m`.
* AA is capped by **Scanner Battery Capacity**.\n Baseline start: `100`.\n Long-term cap target: `1,000` (tuning knob).

Out-of-AA behavior:

* Disable **\[EXTRACT]**.
* Show message:\n `DAILY AUTHORIZATION DEPLETED. PLEASE WAIT FOR ARCHIVE RE-CERTIFICATION.`

{% hint style="info" %}
AA is not a currency.\n It is a time-based limiter on active play.\n It exists to support a “few minutes a day” cadence.
{% endhint %}

#### Player action

* Player presses **\[EXTRACT]**.
* A **Survey bar** fills for `0.5s–2.0s` (tool-dependent).
* Early game: after completion, a `3s` cooldown fires (button disabled).

#### Outcome roll (canonical base odds)

Every completed manual extract produces exactly one outcome:

* `80%` — **Surface Scrap**
* `15%` — **Encapsulated Crate**
* `5%` — **Anomaly**

{% hint style="info" %}
Integrity rule: the **5% Anomaly roll is immutable**.\n Skills, tools, events, and buffs must not change it.
{% endhint %}

#### Modifiers and clamps

* “Crate chance” can be modified by:
  * Tool tier and upgrades.
  * Zone Static intensity.
  * Temporary buffs (e.g., Focused Survey).
* Always enforce:
  * `crateChance ≤ 95%` after all modifiers.
  * `anomalyChance = 5%` always.
  * `scrapChance = 100% - anomalyChance - crateChance`.

#### Perfect Survey (timing layer)

Optionally, a timing **Sweet Spot** appears during the Survey bar fill.

* Hitting the Sweet Spot yields a **Perfect Survey**.
* Perfect Survey effect:
  * `+5%` **flat** Crate chance for _that action_.
  * Bonus Excavation XP for _that action_.
* Progression:
  * Higher Excavation increases Sweet Spot size.
  * At Excavation 99 (“The Endless Vein”), a second Sweet Spot can appear.

#### Skill-gated active ability: Focused Survey (Excavation 60+)

Focused Survey is a paid, time-boxed buff window.

* Duration: `60s`.
* Effect: `+10%` flat Crate chance on **manual** extracts.
* Clamp: still `≤ 95%`.
* It never changes the 5% Anomaly roll.

Details live in [Active Skill Abilities (Tactile Commands)](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md).

***

### Passive extraction (Auto-Digger)

Automation is the “keep playing while offline” lever.

It also becomes the primary Scrap engine mid/late game.

#### Unlocking

Automation becomes available once the player upgrades beyond starter tools.

The exact gate is a tuning knob. Keep it **early enough** to feel meaningful.

#### Tick system (canonical)

* Automation runs on a `10s` tick.
* Each tick:
  * awards Scrap based on **Extraction Power**,
  * rolls Crate chance using the player’s passive stats.

#### Offline gains and battery capacity

* Passive extraction continues while offline.
* Offline accumulation is capped by **Scanner Battery Capacity**.\n Think of this as your “offline buffer.”
* Passive extraction does **not** consume AA.

Implementation model (simple and robust):

* Store `lastSeenAt`.
* On login:
  * compute `elapsedSeconds`,
  * clamp to `batterySeconds` (derived from Scanner Battery),
  * simulate `floor(clampedElapsed / 10)` ticks,
  * award results in a single payout burst.

Recommended mapping (keeps systems consistent):

* `batterySeconds = aaMax * aaRegenSeconds`\n Example: `100 AA * 600s = 60,000s ≈ 16.7h`.

{% hint style="warning" %}
Offline gains should never overfill the Crate tray.\n If a crate would drop while full, convert it to Scrap.\n Or queue it to a “stash.”\n Pick one rule.\n Keep it consistent.
{% endhint %}

***

### The crate tray (anti-hoard + pacing)

Crates are meant to push the player into the Lab.

Recommended rule:

* The Field has a **tray** holding up to `5` unopened Crates.
* If the tray is full:
  * manual extraction is disabled,
  * passive extraction follows the chosen overflow rule (see hint above).

This creates a clean rhythm: **Extract → fill tray → refine → return**.

***

### Zones and “Vault Heatmaps” (strategy layer)

Zones are not cosmetic.

Each unlocked zone has a visible **Static Intensity** heatmap.

Suggested tuning (example):

* Static tiers: LOW / MED / HIGH
* While extracting in that zone:
  * Crate bonus: `+0% / +1% / +2%` flat
* For loot found there (applied later in the Lab):
  * Sift Stability penalty: `+0% / -2.5% / -5%` flat

#### Metadata rule (important)

When a Crate drops, store:

* `sourceZoneId`
* `staticTierAtDrop`
* `dropMethod` (manual / passive)
* `perfectSurvey` flag (true/false)

The Lab must read **stored** crate metadata.

It must not recalc zone static at open time.

#### Personal mitigation (recommended gate)

At Excavation `70+`, the player can “Survey” a zone to temporarily reduce Static penalties.

This is a self-only buff. It never changes global zone state.

#### Information edge (late-game)

At Appraisal 99 (“The Oracle”), players can see “trending” item catalog IDs per zone.

This is an intel advantage, not a drop-rate change.

***

### Anomalies (rare outcomes)

Anomalies are the “spice” outcome.

They must be rare, readable, and social.

#### Basic rules

* Trigger rate: always `5%` of extracts.
* Presentation:
  * UI glitch beat.
  * Feed ping.
  * Short, clear modifier description.

#### Anomaly Overload (combo meter)

Anomalies fill an **Overload Meter** (3 segments) in the header.

* At 3 segments, the player can trigger **Overload** manually.
* Overload lasts `60s`.
  * `+50%` extraction speed.
  * Raw Open protection triggers at Stage 0.
  * If the result was Junk, roll `+5%` to upgrade to Common.

World event hook: during “Magnetic Interference,” anomalies fill the meter twice as fast.

***

### Rewards: currencies, XP, and feel

#### Scrap

Scrap is the primary “progression currency.”

It is used for:

* Workshop upgrades and tools.
* Crate prep fees (Appraisal).
* Bazaar bidding (macro layer).

Scaling guidance:

* Keep early Scrap gains small but frequent.
* Make midgame feel like “machines turning.”
* Keep a long tail. Veterans should still care about +1% efficiency.

#### XP

* Manual extraction pays Excavation XP.
* Perfect Survey pays bonus XP.
* Passive extraction can pay reduced XP (optional). Keep it conservative.

#### Sensory payoff (non-negotiable)

Each extract needs:

* A clear mechanical click sound.
* A short progress animation that reads as “work.”
* A final payoff beat:
  * Scrap: small clink.
  * Crate: heavier thunk + tray slot flash.
  * Anomaly: glitch + feed ping.

***

### System integrity notes

Keep these rules aligned across the docs:

* Base manual odds are `80/15/5` (Scrap/Crate/Anomaly).
* The `5%` anomaly outcome never changes.
* Crate chance is moddable, but clamped to `≤ 95%`.
* Crates must store zone static metadata at drop time.

Macro systems may apply explicit, time-boxed modifiers.

They must not rewrite the baseline probabilities.

See:

* World events: ["The Great Static" Events (incl. Static Pulses)](../../expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md)
* Contract-driven goals: [Lore Keeper Requisitions (Archive Expeditions)](../../expansion-plan/macro-loop-expansion/6.-lore-keeper-requisitions-archive-expeditions.md)
