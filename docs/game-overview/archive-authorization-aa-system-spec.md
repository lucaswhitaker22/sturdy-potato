---
description: >-
  Active-play limiter for a “few minutes a day” cadence, with long-term capacity
  progression.
---

# Archive Authorization (AA) System Spec

## Archive Authorization (AA) System Spec

AA is the system that makes _Relic Vault_ playable in short daily sessions.

It limits high-frequency manual play.

It preserves long-term progression via upgrades.

### Goals

* Cap active clicking without adding fatigue.
* Make “go deep” a daily decision.
* Reward consistent check-ins.
* Keep passive progress meaningful.
* Keep everything server-owned and tuneable.

Non-goals:

* Do not change canonical Field odds (`80/15/5`).
* Do not add new currencies.
* Do not create pay-to-win regen.

### Core concept

AA is the Archive’s bureaucratic clearance to run high-powered equipment.

It is stored in the player’s **Scanner Battery**.

### Player-facing rules (canonical)

#### 1) Regen

Baseline tuning (recommended):

* Regen rate: `+1 AA / 10 minutes`.
* Full recharge target: `~16–24 hours`.

Implementation:

* Regen is time-based.
* Compute off of timestamps, not client timers.

#### 2) Capacity (the long-term lever)

AA is capped by **Scanner Battery Capacity**.

Baseline tuning (recommended):

* Start cap: `100` AA.
* Long-term cap target: `1,000` AA (tuning knob).

Hard rule:

* AA cannot overflow the cap.

#### 3) Spend rules

**Manual Field extraction**

* Each manual **\[EXTRACT]** consumes `1` AA.

**Deep Lab pushes (daily gamble)**

Stages `4–5` are the “high-power” operations.

Baseline tuning:

* Stage `4` **\[SIFT]** (Molecular Scan): costs `5` AA.
* Stage `5` **\[SIFT]** (Quantum Reveal): costs `10` AA.

Rule:

* AA is consumed at attempt start.
* Rolls stay server-owned.

#### 4) Out-of-AA behavior

When AA is insufficient:

* Disable the relevant action.
* Show message:

`DAILY AUTHORIZATION DEPLETED. PLEASE WAIT FOR ARCHIVE RE-CERTIFICATION.`

### Integration with passive loops

#### Auto-Diggers

* Passive extraction does **not** consume AA.
* Passive extraction is still capped by the player’s Scanner Battery (offline buffer).

Recommended mapping (keeps systems mentally consistent):

* `offlineBufferSeconds = aaMax * aaRegenSeconds`
  * Example: `100 * 600s = 60,000s ≈ 16.7h`.

#### Why this mapping works

* One stat (Scanner Battery) governs:
  * how long you can stay away, and
  * how many active actions you can store.

It supports “skip a day without waste” for veteran players.

### Progression sources (how players grow this over months)

#### 1) Workshop upgrades (Scrap)

Workshop sells **Scanner Battery** upgrades.

Effects:

* Increases AA cap.
* Increases offline buffer cap.

#### 2) HI-gated permits (late game)

Add an Influence Shop item:

* **Deep-Cycle Battery Permit**
  * Cost: HI (tune later)
  * Effect: `+5%` AA regen rate (multiplicative)

Rules:

* Account-bound.
* Permanent.

#### 3) Prestige ribbons (very long-term)

If **Archive Rebirth** ships:

* Each Ribbon grants `+2%` Scanner Battery Capacity.

This is a multi-year goal.

### Retention hooks

#### Daily Logbook synergy

If a login streak system exists:

* Reward **Emergency AA Cells** at streak milestones.

Baseline tuning:

* Emergency AA Cell: restores `50%` of AA cap instantly.

Guardrails:

* Cells are account-bound.
* Cells are not tradeable.

### UI requirements (diegetic)

#### Where AA must show

* Global header “Vitals” (all decks).
* Field screen (explicit gauge).
* Lab screen (near deep-stage actions).

#### Visual language

* AA reads like “Work Orders” or “Clearance Stamps”.
* Scanner Battery reads like a hardware gauge.

### Authority + data model (minimum)

Server owns:

* AA regen.
* Spend validation.
* AA deductions.

Minimum per-profile state:

* `aa_current`
* `aa_max`
* `aa_updated_at` (timestamp used for regen)
* `aa_regen_rate_mult` (default `1.0`)

### Telemetry (tuning signals)

Track:

* AA spent per day per player band.
* % of sessions ending due to AA depletion.
* Stage 4/5 attempt count per day.
* Conversion: AA cells earned → AA cells used.
* AA cap distribution (upgrade progression).

### Canon anchors

* Field spend + regen surfaces: [The Dig Site (Main Screen)](2-the-mechanics/the-dig-site-main-screen.md)
* Lab deep-sift AA costs: [The Refiner (The Gambling Hub)](2-the-mechanics/the-refiner-the-gambling-hub.md)
* Upgrade sink: [The Workshop (Progression)](2-the-mechanics/the-workshop-progression.md)
* HI purchase lane: [The Global Museum (Social Leaderboard)](4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)
