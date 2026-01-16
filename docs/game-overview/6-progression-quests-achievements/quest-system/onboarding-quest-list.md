# Onboarding Quest List

## Onboarding Directives (Quest List)

Onboarding Directives are the first-session questline.

They teach the 5-deck loop without forcing luck.

They should feel like the Archive booting you into duty.

Related system rules: [Quest System](./).

### Global rules (keep these consistent)

* Chain length target: `15–30m`.
* Auto-accept the next directive on claim.
* Never require an RNG outcome.
  * No “get a Rare”.
  * No “trigger an Anomaly”.
  * No “shatter a crate”.
* Feature-gate steps that require macro decks.
  * Bazaar-only steps appear only if **\[04] THE BAZAAR** exists.
  * Museum-only steps appear only if **\[05] ARCHIVE** exists.

{% hint style="info" %}
If you’re shipping a V1 onboarding walkthrough (Field → Lab → Vault only), you still keep this list.

You just hide steps 8–10 until Bazaar/Archive ship.
{% endhint %}

***

### archive\_onboard\_01 — Boot Sequence

**Type:** onboarding (one-time)

**Context:** The Archive terminal is waking up.

**Requirements**

* none

**Objectives**

* `extract_manual`: `10`

**Rewards**

* `250` Scrap

**UX notes**

* Highlight **\[EXTRACT]** and the Survey bar.
* Show the base outcome split (`80/15/5`), but don’t over-explain.

**Next:** `archive_onboard_02`

***

### archive\_onboard\_02 — First Crate

**Context:** You need evidence, not dust.

**Requirements**

* prereq: `archive_onboard_01`

**Objectives**

* `crate_obtained`: `1`

**Rewards**

* `500` Scrap

**UX notes**

* Flash the tray slot.
* Teach “tray full blocks extracting”.

**Next:** `archive_onboard_03`

***

### archive\_onboard\_03 — Enter the Lab

**Context:** The Refiner is online. Don’t touch anything you can’t explain.

**Requirements**

* prereq: `archive_onboard_02`

**Objectives**

* `crate_opened`: `1`

**Rewards**

* `100` Scrap

**UX notes**

* Force a navigation nudge: Field → Lab.
* Stage 0 is readable as “safe”.

**Next:** `archive_onboard_04`

***

### archive\_onboard\_04 — First Gamble

**Context:** The Archive prefers risk, as long as it’s documented.

**Requirements**

* prereq: `archive_onboard_03`

**Objectives**

* `sift_stage_at_least`: Stage `1+` (attempt `1`)

**Rewards**

* `10` Fine Dust

**UX notes**

* Make the risk escalation obvious.
* Teach “SIFT is optional” and “CLAIM is the exit”.

**Next:** `archive_onboard_05`

***

### archive\_onboard\_05 — Claim Discipline

**Context:** You can’t sell a story you never brought back.

**Requirements**

* prereq: `archive_onboard_04`

**Objectives**

* `claim_stage_at_least`: Stage `1+` (complete `1`)

**Rewards**

* `1,000` Scrap

**UX notes**

* Show the “keep vs sell vs smelt” decision teaser.
* Do not require Bazaar access yet.

**Next:** `archive_onboard_06`

***

### archive\_onboard\_06 — The Vault Matters

**Context:** Hoarding is not a strategy. Convert waste into throughput.

**Requirements**

* prereq: `archive_onboard_05`

**Objectives**

* `smelt_items`: `3`

**Rewards**

* `750` Scrap

**UX notes**

* Teach “smelt duplicates”.
* Teach “smelting is a sink and a pace lever”.

**Next:** `archive_onboard_07`

***

### archive\_onboard\_07 — Set Awareness

**Context:** The Archive remembers patterns. You should too.

**Requirements**

* prereq: `archive_onboard_06`

**Objectives**

* `set_entries_added`: `1`

**Rewards**

* Cosmetic UI stamp: `ARCHIVE LABEL`

**UX notes**

* Show silhouettes.
* Explain set-lock at a high level.
  * “Completing a set removes items from trade.”

**Next:** `archive_onboard_08`

***

### archive\_onboard\_08 — The Bazaar Door

**Context:** If it’s not priced, it’s not real.

**Requirements**

* prereq: `archive_onboard_07`
* feature gate: Bazaar unlocked

**Objectives**

* `listings_created`: `1`

**Rewards**

* `2,000` Scrap **or** `+1` listing slot for `24h` (if temporary slots exist)

**UX notes**

* Teach listing deposit + Archive tax.
* Never require a sale here.

**Next:** `archive_onboard_09`

***

### archive\_onboard\_09 — Museum Week

**Context:** The Archive rewards exhibits, not excuses.

**Requirements**

* prereq: `archive_onboard_08`
* feature gate: Museum unlocked

**Objectives**

* `museum_submissions`: `1` (must match current theme)

**Rewards**

* `25` HI (starter grant)

**UX notes**

* Teach “Museum submissions lock items for the week”.
* Teach “HI is non-tradable”.

**Next:** `archive_onboard_10`

***

### archive\_onboard\_10 — Field Agent

**Context:** Clearance granted. You’re officially a problem now.

**Requirements**

* prereq: `archive_onboard_09`

**Objectives**

* none (auto-complete when all onboarding directives are claimed)

**Rewards**

* Title: `Field Agent`

**UX notes**

* After claim, show three “what next” cards:
  * Push Lab risk.
  * Chase a set.
  * Participate in the Museum week.
