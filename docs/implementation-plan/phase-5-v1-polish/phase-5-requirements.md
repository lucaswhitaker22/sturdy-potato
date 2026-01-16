---
description: >-
  Testable requirements for Phase 5 (polish, onboarding, monetization, launch
  readiness).
---

# Phase 5 requirements

This is the build contract for Phase 5.

It turns the Phase 5 plan into concrete requirements.

### Canon and coverage rules

This page is the Phase 5 source of truth.

It must fully cover the functionality described in:

* [4 - The MMO & Economy (Macro)](../../game-overview/4-the-mmo-and-economy-macro.md)
* [3 - The Loot & Collection Schema](../../game-overview/3-the-loot-and-collection-schema.md)
* [6 - UI/UX Wireframe & Flow](../../game-overview/6-ui-ux-wireframe-and-flow.md)
* [Technical Framework (Vue + Supabase)](../technical-framework-vue-+-supabase.md)

Coverage means:

* If it ships in V1, it must be a requirement here.
* If it does **not** ship in V1, it must be named in **Out of scope**.

### Scope

Phase 5 makes the game shippable.

It focuses on:

* Sensory polish (sound, micro-animations, reveal sequences).
* Onboarding and first-session clarity.
* Retention basics (daily logbook + streak).
* Monetization basics (Vault Credits shop).
* Performance, error handling, and observability.

Phase 5 assumes Phase 4 is already working.

#### Out of scope

Explicit non-goals for Phase 5:

* New core gameplay loops, new refine stages, or new rarity tiers.
* New skills beyond those already defined.
* Prestige systems (post-V1):
  * Archive Rebirth (skill resets for ribbons/permanent perks).
* Friends, guilds, chat, DMs.
* Anti-bot enforcement beyond server-authoritative state + basic rate limiting.
* Regional servers.
* Full live-ops tooling (A/B tests, complex CMS).

### Functional requirements

#### Sensory / UI polish

**R1 — Action feedback coverage**

Every high-frequency action must have:

* a sound cue, and
* a visual cue.

Minimum actions:

* `[EXTRACT]` start and completion
* Crate drop
* `[SIFT]` attempt
* Sift success
* Shatter failure
* Claim success
* Mint reveal
* Level up
* Set completion
* Bazaar: outbid, win, sale

**R2 — Lab “Reveal” sequence**

Successful item reveals must include:

* a short anticipation beat (0.5–2.0s),
* a clear success/failure outcome, and
* a distinct mint number stamp beat.

Prismatic reveals must be visually distinct.

#### Onboarding

**R3 — First-session walkthrough**

New accounts must be guided through:

1. Earning Scrap in the Field.
2. Getting at least one Crate.
3. Refining in the Lab.
4. Viewing the item in the Vault.

The walkthrough must be skippable.

**R4 — Glossary tooltips**

The UI must provide lightweight definitions for:

* Scrap
* Crate
* Sift vs Claim
* Shatter
* Mint number
* HV (if shown)
* Condition (if shown)

Tooltips must not block primary buttons.

#### Retention

**R5 — Daily Logbook**

The game must ship a Daily Logbook.

It must:

* reset every 24 hours (server time),
* grant a daily reward on completion, and
* track a streak.

Minimum daily tasks:

* Do N Extracts.
* Complete N Sifts.

**R6 — 30-day streak reward**

At a 30-day streak, the player receives a visible milestone reward.

Reward can be cosmetic.

#### Monetization (Vault Credits)

**R7 — Vault Credits balance**

The game must support a `vault_credits` balance.

Credits must be earned via:

* real-money purchase, and
* dissolving Prismatic relics (from Loot Schema).

**R8 — Archive Shop**

The game must ship an Archive Shop.

It must sell at least:

* cosmetic UI skins,
* Vault/inventory expansions,
* Stabilizer Charms.

**R9 — Stabilizer Charm guardrails**

Stabilizer Charms must:

* have a clear per-use effect,
* show the effect in the Lab UI before confirming, and
* be limited to prevent trivializing shatter risk.

#### Engineering readiness

**R10 — Performance budget**

The app must meet minimum budgets:

* initial load: reasonable on mobile connections,
* no long UI freezes during sifts, listings, or museum actions.

Exact thresholds can be set by implementation.

**R11 — Error handling and recovery**

When server requests fail (RNG, bidding, museum submission):

* show a clear error,
* do not desync client state,
* provide a retry.

**R12 — Observability (analytics events)**

The game must emit analytics events for:

* onboarding completion
* tutorial skip
* D1 retention proxy (daily logbook complete)
* monetization funnel (shop open → checkout start → purchase success)
* core loop actions (extract, sift success/fail)

Events must avoid storing personal data.

### Success criteria

Phase 5 is done when:

1. New users can complete the first-session walkthrough.
2. Core actions feel responsive and readable.
3. Daily Logbook works and rewards reliably.
4. Vault Credits shop works end-to-end.
5. Major server failures degrade gracefully.
