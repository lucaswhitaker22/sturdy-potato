# Risk Achievement List

## Risk Achievement List (Lab identity)

Risk achievements celebrate pushing crates deeper in the Lab.

They reward:

* discipline (knowing when to claim),
* courage (attempting high stages),
* consistency (repeatable high-risk behavior).

They should not reward pure luck.

System anchors:

* taxonomy + reward/broadcast rules: [Achievement System](./)
* Lab stages, stability, shatter rules: [The Refiner (The Gambling Hub)](../../2-the-mechanics/the-refiner-the-gambling-hub.md)
* micro/meso canon (must not drift): [2: The Mechanics](../../2-the-mechanics.md)

{% hint style="warning" %}
Risk achievements must never modify Stability, stage odds, or payout math.

They are receipts, not buffs.
{% endhint %}

***

### Global rules (hard requirements)

* Category is always `risk`.
* Prefer **attempt-based** counters over “success-only” counters.
* If an achievement requires a success chain (e.g., Clean Run), it must be:
  * rare,
  * purely cosmetic rewards,
  * never required for progression.
* Feature gates apply:
  * Salvage achievements only exist if **Shatter Salvage** ships.
  * Glue achievements only exist if **Emergency Glue** ships.
* Broadcast defaults:
  * local toast + Dossier log for most,
  * global feed only for truly high-signal risk receipts (optional).

Recommended reward types:

* titles
* profile badges
* frames (for the hardest ones)

***

### Track A — First deep pushes (one-time)

### risk\_001 — Stage Diver

**Tier:** silver\
**Context:** You went deep enough to feel it.

**Unlock condition**

* Successfully **\[CLAIM]** at Stage `3+` for the first time.

**Reward**

* Profile badge: `STAGE DIVER`

**Broadcast**

* local only

***

### risk\_002 — Mythic Nerves

**Tier:** gold\
**Context:** You stared at Stage 4 and clicked anyway.

**Unlock condition**

* Attempt Stage `4` **\[SIFT]** at least once.

**Reward**

* Title: `Nerves of Glass`

**Broadcast**

* local only

***

### risk\_003 — Quantum Touch

**Tier:** gold\
**Context:** You touched the ceiling.

**Unlock condition**

* Attempt Stage `5` **\[SIFT]** at least once.

**Reward**

* Profile badge: `QUANTUM TOUCH`

**Broadcast**

* local only (optional global later)

***

### Track B — Stage volume (repeatable counters)

These counters should be the core of the Risk track.

They prove a player is willing to gamble, even when it hurts.

#### Stage 3 attempt ladder

### risk\_010 — Deep Attempts I

**Tier:** silver\
**Context:** The Lab knows your name.

**Unlock condition**

* Attempt Stage `3+` **\[SIFT]** `25` times.

**Reward**

* Dossier badge: `DEEP ATTEMPTS I`

**Broadcast**

* local only

***

### risk\_011 — Deep Attempts II

**Tier:** gold\
**Context:** You live at the edge.

**Unlock condition**

* Attempt Stage `3+` **\[SIFT]** `250` times.

**Reward**

* Title: `Edgewalker`

**Broadcast**

* local only

***

#### Stage 5 attempt ladder

### risk\_020 — High Roller I

**Tier:** gold\
**Context:** You keep touching the ceiling.

**Unlock condition**

* Attempt Stage `5` **\[SIFT]** `10` times.

**Reward**

* Profile badge: `HIGH ROLLER I`

**Broadcast**

* local only

***

### risk\_021 — High Roller II

**Tier:** gold\
**Context:** You’re statistically unwell.

**Unlock condition**

* Attempt Stage `5` **\[SIFT]** `100` times.

**Reward**

* Profile frame: `HIGH ROLLER`
* Title: `High Roller`

**Broadcast**

* global feed (optional, high signal)

{% hint style="info" %}
This is an _attempt_ counter, not a success counter.

It rewards behavior, not luck.
{% endhint %}

***

### Track C — Discipline (claim habits)

These reward “smart risk”, not just reckless pushing.

### risk\_030 — Exit Strategy

**Tier:** silver\
**Context:** You learned when to stop.

**Unlock condition**

* Use **\[CLAIM]** at Stage `2+` `25` times.

**Reward**

* Title: `Exit Planner`

**Broadcast**

* local only

***

### risk\_031 — Professional Closer

**Tier:** gold\
**Context:** You brought it back. Repeatedly.

**Unlock condition**

* Use **\[CLAIM]** at Stage `3+` `50` times.

**Reward**

* Profile badge: `PROFESSIONAL CLOSER`

**Broadcast**

* local only

***

### Track D — Failure handling (shatter identity)

Failure is part of the Lab’s contract.

These achievements make failure “owned”, not hidden.

### risk\_040 — Glass Collector

**Tier:** silver\
**Context:** You kept going after the break.

**Unlock condition**

* Shatter at Stage `3+` `10` times.

**Reward**

* Dossier badge: `GLASS COLLECTOR`

**Broadcast**

* local only

***

### risk\_041 — Overheat Incident

**Tier:** gold\
**Context:** The Lab locked you out.

**Unlock condition**

* Trigger `1` Critical Fail (overheat).

**Reward**

* Title: `System Hot`

**Broadcast**

* local only

***

#### Shatter Salvage (feature-gated)

### risk\_050 — Salvage Operator

**Tier:** silver\
**Context:** You didn’t freeze.

**Unlock condition**

* Succeed **\[SALVAGE]** `10` times (Standard Fail reaction window).

**Reward**

* Profile badge: `SALVAGE OPERATOR`

**Broadcast**

* local only

**Notes**

* Hide if Shatter Salvage is not shipped.

***

#### Emergency Glue (feature-gated)

### risk\_060 — Field Repair

**Tier:** gold\
**Context:** You refused to lose it.

**Unlock condition**

* Use **Emergency Glue** `1` time.

**Reward**

* Title: `Field Mechanic`

**Broadcast**

* local only

**Notes**

* Hide if Emergency Glue is not shipped.
* Emergency Glue triggers on Standard Fail only.
* Canon: [The Refiner (The Gambling Hub)](../../2-the-mechanics/the-refiner-the-gambling-hub.md)

***

### risk\_061 — Patchwork Veteran

**Tier:** gold\
**Context:** You keep a fragment for a reason.

**Unlock condition**

* Use **Emergency Glue** `25` times.

**Reward**

* Profile frame: `PATCHWORK`

**Broadcast**

* local only (optional global later)

**Notes**

* Hide if Emergency Glue is not shipped.

***

### Track E — “Clean Run” (rare success chain)

These are intentionally rare and purely identity rewards.

They can be luck-influenced, but they measure a clean high-risk streak.

### risk\_090 — Clean Run (Stage 0 → Stage 4)

**Tier:** gold\
**Context:** No breaks. No excuses.

**Unlock condition**

* From a fresh crate, reach and **\[CLAIM]** at Stage `4` without any shatter on the way.

**Reward**

* Title: `Clean Runner`

**Broadcast**

* local only

***

### risk\_091 — Clean Run (Stage 0 → Stage 5)

**Tier:** gold\
**Context:** The perfect gamble.

**Unlock condition**

* From a fresh crate, reach and **\[CLAIM]** at Stage `5` without any shatter on the way.

**Reward**

* Profile frame: `ZERO-FRACTURE`
* Title: `Zero-Fracture`

**Broadcast**

* global feed (optional, very high signal)

{% hint style="warning" %}
This must remain cosmetic-only.

It’s a prestige receipt, not a progression layer.
{% endhint %}

***

### Implementation notes (event mapping)

Recommended server events for progress:

* `sift_attempted(stage)` → attempt counters
* `crate_claimed(stage)` → claim counters + “Stage Diver”
* `crate_shattered(stage, fail_type)` → shatter counters + overheat
* `salvage_success(stage)` → salvage counters (if shipped)
* `emergency_glue_used(stage)` → glue counters (if shipped)
* `clean_run_completed(max_stage)` → Clean Run unlocks (compute server-side)

Hard rules:

* counters are server-owned and idempotent
* never trust client timing for Salvage/Glue windows
* never award progress from “UI opened” events
