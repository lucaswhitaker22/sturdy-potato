# Milestones Achievement List

## Milestones Achievement List (canonical one-time “firsts”)

Milestones are **one-time receipts**.

They mark the first time a player touches a core system.

They should teach the loop by celebrating it.

System anchors:

* taxonomy + reward rules: [Achievement System](./)
* loop context: [0 - Game Loop](../../0-game-loop.md)
* Field action names: [The Dig Site (Main Screen)](../../2-the-mechanics/the-dig-site-main-screen.md)
* Lab action names + stages: [The Refiner (The Gambling Hub)](../../2-the-mechanics/the-refiner-the-gambling-hub.md)
* Bazaar integrity (escrow, holds): [The Bazaar (Auction House)](../../4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)
* Museum locks + HI: [The Global Museum (Social Leaderboard)](../../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)

Related lists:

* early-seed subset: [Early Achievement List](/broken/spaces/W0NXJBdtLzebirumENnw/pages/PN1oZHKfDGkO6iMVTiWp)

{% hint style="info" %}
Milestones should be **deterministic**.

Avoid RNG unlocks like “trigger an anomaly” or “roll a Unique.”

Put RNG “wow moments” in **Legacy** achievements instead.
{% endhint %}

***

### Global rules (hard requirements)

* Milestones are **one-shot**. No counters.
* The unlock event must be **server-authoritative**.
* Milestones never change canonical odds, Stability, or scoring.
* Feature gates apply:
  * Bazaar milestones only exist if **\[04] THE BAZAAR** ships.
  * Museum milestones only exist if **\[05] ARCHIVE** ships.

#### Reward guidance (safe defaults)

Prefer identity rewards:

* titles
* profile badges
* dossier stamps
* frames / UI stickers

If you grant currency:

* keep it one-time and small (`≤ 1,000 Scrap`)
* never grant HI casually

#### Broadcast defaults

* Milestones are **local toast only**.
* Global feed is reserved for:
  * skill `99`,
  * Unique / Prismatic reveals,
  * Top `1%` Museum finishes.

***

### Field milestones (Deck \[01])

### ms\_field\_001 — First Contact

**Category:** milestone\
**Context:** The Archive noticed your first motion.

**Unlock condition**

* Complete `1` manual **\[EXTRACT]** action.

**Reward**

* Dossier stamp: `FIRST CONTACT`

***

### ms\_field\_002 — Perfect Survey

**Category:** milestone\
**Context:** Clean data. Clean signal.

**Unlock condition**

* Hit `1` Perfect Survey timing window (if shipped).

**Reward**

* Dossier stamp: `CLEAN SIGNAL`

**Notes**

* Hide if the timing layer is not shipped.

***

### ms\_field\_003 — Evidence Acquired

**Category:** milestone\
**Context:** Dust is noise. Crates are proof.

**Unlock condition**

* Obtain `1` Encapsulated Crate (any source).

**Reward**

* Title: `Runner`

***

### ms\_field\_004 — Tray Jam

**Category:** milestone\
**Context:** You found the pacing wall.

**Unlock condition**

* Fill the Field crate tray to max capacity (recommended: `5/5`).

**Reward**

* Dossier stamp: `FULL LOAD`

**Notes**

* Fire once. This is a tutorial moment.

***

### Lab milestones (Deck \[02])

### ms\_lab\_001 — The Refiner is Online

**Category:** milestone\
**Context:** The Lab doesn’t care if you’re ready.

**Unlock condition**

* Start refining `1` crate (enter Lab flow for a crate).

**Reward**

* UI badge: `LAB ACCESS`

***

### ms\_lab\_002 — Safe Hands

**Category:** milestone\
**Context:** Discipline beats bravado.

**Unlock condition**

* Use **\[CLAIM]** `1` time (any stage, including Stage 0).

**Reward**

* Dossier stamp: `DISCIPLINE`

***

### ms\_lab\_003 — First Gamble

**Category:** milestone\
**Context:** Now the Archive has something to grade.

**Unlock condition**

* Use **\[SIFT]** `1` time (any Stage `1+` attempt).

**Reward**

* Dossier stamp: `RISK LOGGED`

***

### ms\_lab\_004 — Unbroken Seal

**Category:** milestone\
**Context:** One layer deeper. Still intact.

**Unlock condition**

* Successfully complete a Stage `1` attempt (i.e., do not shatter on the Stage-1 roll).

**Reward**

* Title: `Brushhand`

***

### ms\_lab\_005 — Stage Diver

**Category:** milestone\
**Context:** You went deep enough to feel it.

**Unlock condition**

* Successfully **\[CLAIM]** at Stage `3+` for the first time.

**Reward**

* Profile badge: `STAGE DIVER`

**Notes**

* This is deterministic. It’s about player choice, not luck.

***

### ms\_lab\_006 — Glass Break

**Category:** milestone\
**Context:** Failure is part of the record.

**Unlock condition**

* Shatter `1` crate at Stage `1+`.

**Reward**

* Dossier stamp: `SYSTEM ERROR`

***

### ms\_lab\_007 — Reaction Time

**Category:** milestone\
**Context:** You didn’t freeze.

**Unlock condition**

* On a Standard Fail, succeed the **\[SALVAGE]** reaction window (if shipped).

**Reward**

* Profile badge: `SALVAGER`

**Notes**

* Hide if Shatter Salvage is not shipped.

***

### ms\_lab\_008 — Paid Intel

**Category:** milestone\
**Context:** You bought certainty. Or the illusion of it.

**Unlock condition**

* Use **\[APPRAISE]** (Pre-Sift Appraisal) `1` time (if shipped).

**Reward**

* Dossier stamp: `PAID INTEL`

**Notes**

* Hide if Appraisal is not shipped in the same phase as the Lab.

***

### Vault milestones (Deck \[03])

### ms\_vault\_001 — Scrap Converter

**Category:** milestone\
**Context:** Waste becomes progress.

**Unlock condition**

* Smelt `1` item.

**Reward**

* Dossier stamp: `MATERIAL LOOP`

***

### ms\_vault\_002 — First Upgrade

**Category:** milestone\
**Context:** Tools make the loop real.

**Unlock condition**

* Complete `1` Workshop purchase or upgrade.

**Reward**

* Title: `Tinkerer`

***

### ms\_vault\_003 — Pattern Recognition

**Category:** milestone\
**Context:** You stopped seeing junk as junk.

**Unlock condition**

* Add `1` item to any set tracker.

**Reward**

* UI stamp: `ARCHIVE LABEL`

***

### ms\_vault\_004 — First Set Complete

**Category:** milestone\
**Context:** A small collection is still a collection.

**Unlock condition**

* Complete `1` full set (any tier).

**Reward**

* Profile frame: `CABINET (BRONZE)`

***

### Bazaar milestones (Deck \[04]) (feature-gated)

### ms\_bazaar\_001 — Listed

**Category:** milestone\
**Context:** If it’s not priced, it’s not real.

**Unlock condition**

* Create `1` Bazaar listing.

**Reward**

* Title: `Vendor`

**Notes**

* Do not require a sale.

***

### ms\_bazaar\_002 — First Sale

**Category:** milestone\
**Context:** The market agreed.

**Unlock condition**

* Complete `1` successful sale (any price).

**Reward**

* Profile badge: `TRADED`

***

### ms\_bazaar\_003 — First Bid

**Category:** milestone\
**Context:** You put Scrap on a belief.

**Unlock condition**

* Place `1` bid on any listing.

**Reward**

* Dossier stamp: `HELD FUNDS`

***

### Archive milestones (Deck \[05]) (feature-gated)

### ms\_archive\_001 — First Exhibit

**Category:** milestone\
**Context:** Profit or prestige. You picked prestige.

**Unlock condition**

* Submit `1` theme-matching item to the Museum.

**Reward**

* Title: `Contributor`

***

### ms\_archive\_002 — Influence Earned

**Category:** milestone\
**Context:** The Archive pays attention now.

**Unlock condition**

* Earn HI `>= 1` from any source (Museum, contract, event).

**Reward**

* Profile frame: `ARCHIVE INK`

**Notes**

* This is intentionally broad. It is the “HI exists” tutorial stamp.

***

### Milestone implementation notes (event mapping)

Use event-driven unlocks.

Do not infer milestones from client UI state.

Recommended event names (example):

* `extract_completed` → ms\_field\_001
* `perfect_survey_hit` → ms\_field\_002
* `crate_obtained` → ms\_field\_003
* `tray_filled` → ms\_field\_004
* `lab_crate_started` → ms\_lab\_001
* `crate_claimed` → ms\_lab\_002
* `sift_attempted` → ms\_lab\_003
* `sift_succeeded_stage_1` → ms\_lab\_004
* `crate_claimed_stage_at_least_3` → ms\_lab\_005
* `crate_shattered_stage_at_least_1` → ms\_lab\_006
* `salvage_success` → ms\_lab\_007
* `pre_sift_appraisal_used` → ms\_lab\_008
* `smelt_completed` → ms\_vault\_001
* `workshop_purchase_completed` → ms\_vault\_002
* `set_entry_added` → ms\_vault\_003
* `set_completed` → ms\_vault\_004
* `bazaar_listing_created` → ms\_bazaar\_001
* `bazaar_sale_completed` → ms\_bazaar\_002
* `bazaar_bid_placed` → ms\_bazaar\_003
* `museum_submitted_theme_match` → ms\_archive\_001
* `hi_granted` → ms\_archive\_002

Hard rules:

* unlock writes are idempotent
* unlock + reward grant is server-owned
* no milestone mutates canonical odds or scoring
