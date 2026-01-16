# Unboarding Quest List

## Unboarding Directives (Quest List)

Unboarding Directives are the “exit ramp” after onboarding.

They turn a player from guided to self-directed.

They introduce long-run systems without forcing luck.

Related system rules: [Quest System](../quest-system.md).

### What “unboarding” means here

This is not an account deletion flow.

This is the moment the Archive stops holding your hand.

### Global rules

* These are one-time directives.
* They can be completed over multiple sessions.
* Never require RNG outcomes.
  * No “trigger an Anomaly”.
  * No “get a Prismatic”.
  * No “shatter and salvage”.
* If a directive depends on an unshipped deck, hide it.
  * Bazaar module needs **\[04] THE BAZAAR**.
  * Museum/Contracts module needs **\[05] ARCHIVE**.

{% hint style="info" %}
RNG-flavored moments (first Anomaly, first Shatter, first Prismatic) belong in Achievements.

See: [Achievement System](../achievement-system.md).
{% endhint %}

***

### Core graduation chain (always available)

These assume Field/Lab/Vault are live.

#### archive\_unboard\_01 — Tooling Up

**Context:** Throughput is permission.

**Requirements**

* prereq: onboarding complete

**Objectives**

* `workshop_purchase`: `1`

**Rewards**

* `1,000` Scrap

**Notes**

* Count any paid Workshop action (tool purchase or upgrade).

***

#### archive\_unboard\_02 — Crate Pipeline

**Context:** The tray is a conveyor belt. Treat it like one.

**Requirements**

* prereq: `archive_unboard_01`

**Objectives**

* `crate_obtained`: `10`

**Rewards**

* Cosmetic UI stamp: `FILED`

***

#### archive\_unboard\_03 — Lab Routine

**Context:** Evidence is processed, not wished for.

**Requirements**

* prereq: `archive_unboard_02`

**Objectives**

* `crate_opened`: `5`

**Rewards**

* `15` Fine Dust

***

#### archive\_unboard\_04 — Risk Practice

**Context:** Learn the needle before you blame the needle.

**Requirements**

* prereq: `archive_unboard_03`

**Objectives**

* `sift_stage_at_least`: Stage `1+` (attempt `10`)

**Rewards**

* `1,500` Scrap

**Notes**

* This counts attempts, not successes.

***

#### archive\_unboard\_05 — Claim Policy

**Context:** Profit is a decision, not a drop.

**Requirements**

* prereq: `archive_unboard_04`

**Objectives**

* `claim_stage_at_least`: Stage `1+` (complete `3`)

**Rewards**

* Cosmetic UI stamp: `APPROVED`

***

#### archive\_unboard\_06 — Clean Inventory

**Context:** Carrying trash is still carrying.

**Requirements**

* prereq: `archive_unboard_05`

**Objectives**

* `smelt_items`: `20`

**Rewards**

* `2,500` Scrap

***

#### archive\_unboard\_07 — Collection Habit

**Context:** Sets are the only honest long-term plan.

**Requirements**

* prereq: `archive_unboard_06`

**Objectives**

* `set_entries_added`: `10`

**Rewards**

* Cosmetic UI stamp: `CATALOGED`

***

#### archive\_unboard\_08 — First Completion

**Context:** Locking is commitment.

**Requirements**

* prereq: `archive_unboard_07`

**Objectives**

* `set_completed`: `1`

**Rewards**

* Title: `Collector (Probationary)`

***

#### archive\_unboard\_09 — Crate Intel

**Context:** Pay for information. Don’t hallucinate it.

**Requirements**

* prereq: `archive_unboard_08`
* feature gate: Pre-Sift Appraisal shipped

**Objectives**

* `appraisal_attempted`: `3`

**Rewards**

* `1,000` Scrap

**Notes**

* Count attempts, not appraisal success.

***

#### archive\_unboard\_10 — Graduation

**Context:** Guidance revoked. Authority granted.

**Requirements**

* prereq: `archive_unboard_09`

**Objectives**

* none (auto-complete when core unboarding directives are claimed)

**Rewards**

* Cosmetic frame: `Archive Clearance: Bronze`

**Unlocks**

* Daily directives pool (if shipped)
* Weekly contracts pool (if shipped)

***

### Bazaar module (only when \[04] THE BAZAAR exists)

#### archive\_unboard\_bz\_01 — Market Entry

**Context:** The Archive doesn’t care what you own. It cares what you can move.

**Requirements**

* prereq: `archive_unboard_10`
* feature gate: Bazaar unlocked

**Objectives**

* `listings_created`: `5`

**Rewards**

* Cosmetic UI stamp: `LISTED`

***

#### archive\_unboard\_bz\_02 — Price Discovery

**Context:** Bidding is how you learn what things really cost.

**Requirements**

* prereq: `archive_unboard_bz_01`

**Objectives**

* `bids_placed`: `10`

**Rewards**

* Title: `Lot Runner`

***

### Archive module (Museum + Contracts)

#### archive\_unboard\_ar\_01 — Museum Cadence

**Context:** If you don’t show up, you don’t exist.

**Requirements**

* prereq: `archive_unboard_10`
* feature gate: Museum unlocked

**Objectives**

* `museum_submissions`: `3` (theme-matching)

**Rewards**

* `50` HI

***

#### archive\_unboard\_ar\_02 — First Case File

**Context:** The Lore Keepers need evidence.

**Requirements**

* prereq: `archive_unboard_ar_01`
* feature gate: Expeditions shipped

**Objectives**

* `expedition_accepted`: `1`

**Rewards**

* Cosmetic UI stamp: `FILE OPENED`

***

#### archive\_unboard\_ar\_03 — Case Closed

**Context:** Submitted relics never come back.

**Requirements**

* prereq: `archive_unboard_ar_02`

**Objectives**

* `expedition_completed`: `1`

**Rewards**

* Title: `Junior Clerk`

***

### Advanced modules (optional, feature-gated)

These are “first touch” directives for late-game systems.

They are not required to graduate.

#### archive\_unboard\_adv\_01 — Certified Paperwork

**Context:** Trust is a currency.

**Requirements**

* Bazaar unlocked
* feature gate: Certification shipped

**Objectives**

* `certification_completed`: `1`

**Rewards**

* Cosmetic UI stamp: `CERTIFIED`

***

#### archive\_unboard\_adv\_02 — The Black Lane

**Context:** No tax. No safety.

**Requirements**

* prereq: `archive_unboard_bz_02`
* feature gate: Counter-Bazaar shipped

**Objectives**

* `counter_listings_created`: `1`

**Rewards**

* Title: `Broker Adjacent`

***

#### archive\_unboard\_adv\_03 — Lease Agreement

**Context:** Borrowed relics still count as leverage.

**Requirements**

* Bazaar unlocked
* feature gate: Artifact Leasing shipped

**Objectives**

* `lease_completed`: `1`

**Rewards**

* Cosmetic frame: `Lease Seal`

***

#### archive\_unboard\_adv\_04 — Endowment (Optional Sink)

**Context:** The Archive loves a permanent loss.

**Requirements**

* feature gate: Museum Endowments shipped

**Objectives**

* `endowment_created`: `1`

**Rewards**

* Title: `Patron`

{% hint style="warning" %}
Endowments are permanent burns.

Never force this as part of the core unboarding chain.
{% endhint %}

***

#### archive\_unboard\_adv\_05 — Choose a Branch

**Context:** Specialization is the point of no return.

**Requirements**

* feature gate: Skill Sub-Specializations shipped
* any skill reaches level `60+`

**Objectives**

* `specialization_chosen`: `1`

**Rewards**

* Title: `Specialist`

***

#### archive\_unboard\_adv\_06 — Use Your Press Moment

**Context:** Power is wasted if it’s never pressed.

**Requirements**

* prereq: `archive_unboard_adv_05`
* feature gate: Active Skill Abilities shipped

**Objectives**

* `active_ability_used`: `1`

**Rewards**

* Cosmetic frame: `Command Key`
