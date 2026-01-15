---
description: >-
  Testable requirements for Phase 4 (Museum, Influence, Events, Advanced
  Skills).
---

# Phase 4 requirements

This is the build contract for Phase 4.

It turns the Phase 4 plan into concrete requirements.

### Scope

Phase 4 ships the meta-game loops:

* Global Museum (weekly theme, locking, scoring, leaderboard).
* Historical Influence (HI) currency + Influence Shop.
* World Events (48-72h global modifiers + community goal).
* Advanced skilling (Appraisal + Smelting at level 60+).

Assumes Phase 3 exists (auth, minting, Bazaar, server authority, realtime feed).

Out of scope:

* Monetization store.
* Guilds/chat.

### Data requirements

#### Profiles

Add to `profiles`:

* `historical_influence` (integer, >= 0)

HI is non-tradable.

#### Museum

Support weekly configuration.

Minimum tables (names can vary):

* `museum_weeks`: `theme_name`, `starts_at`, `ends_at`, `status`.
* `museum_submissions`: `week_id`, `player_id`, `inventory_item_id`, `score`, `locked_until`.

#### World events

Minimum tables:

* `world_events`: `name`, `starts_at`, `ends_at`, `status`, `modifiers`, `global_goal_target`, `global_goal_progress`.
* `world_event_contributions`: `event_id`, `player_id`, `contribution_value`.

#### Item metadata for scoring

Inventory items must expose:

* `rarity_tier`
* `condition`
* `mint_number`
* `set_id` (nullable)

Items must support certification:

* `is_certified` (boolean)
* `certified_by_player_id` (nullable)

### Functional requirements

#### Museum

**R1 - Weekly theme announcement**

When a museum week becomes active:

* Broadcast `MUSEUM THEME: <theme>` in Global Feed.
* Museum screen shows theme + remaining time.

**R2 - Item assignment and locking**

A player can assign Vault items to the current week.

On assignment:

* Item becomes locked until week ends.
* Locked items cannot be listed in Bazaar.
* UI labels the lock state.

**R3 - Submission limit**

Enforce a per-player cap.

Default: 10 submissions per week.

**R4 - Score calculation coverage**

Each submitted item must produce a score that incorporates:

* Rarity and condition.
* Mint number (low mints are a big multiplier).
* Set completion bonus (when the player submits a full themed set).

Scoring must be:

* Server-side.
* Deterministic.
* Explainable (show a breakdown tooltip, or a simple breakdown list).

**R5 - Real-time leaderboard**

Museum shows a realtime leaderboard:

* Top 100.
* Player rank even if outside top 100.
* Updates without refresh.

**R6 - Week end resolution**

At week end:

* Finalize leaderboard.
* Grant HI rewards.
* Unlock all museum-locked items.

Resolution must be server-side and idempotent.

#### Historical Influence (HI)

**R7 - HI earn rules**

HI is earned only via:

* Museum participation.
* World events.

HI is not tradable.

**R8 - Influence Shop inventory**

Influence Shop must offer (at minimum):

* Zone permits (unlock high-level dig sites).
* Elite skill training unlock (push skills from 90 to 99).
* Custom titles (prefix for Global Feed messages).
* Vault expansions.

Each shop item shows HI cost, prerequisites, and purchase state.

**R9 - HI spend integrity**

Purchases must:

* Validate sufficient HI.
* Deduct HI server-side.
* Apply unlock immediately.
* Prevent double-purchase for one-time unlocks.

#### World Events

**R10 - Start announcement**

When an event starts:

* Broadcast `SENSORS DETECT: <message>` in Global Feed.
* UI shows name + time remaining.

Events run 48-72 hours.

**R11 - Event-only loot**

During an active event:

* Event-only items can drop.
* Those items do not drop outside the window.

**R12 - Global modifiers**

Events can apply global stat shifts, at least:

* Extraction speed modifier.
* Sift success modifier.

Modifiers must be applied server-side.

**R13 - Global progress bar**

UI shows a shared progress bar.

Minimum goal type: collectively mine Scrap.

Progress updates without refresh.

**R14 - Participation rewards**

Players who contribute above a minimum threshold get a reward.

Reward granting must be server-side and idempotent.

#### Advanced skilling

**R15 - Appraisal (level 60+): hidden sub-stats**

At Appraisal level 60+:

* UI reveals hidden sub-stats on relics.
* Hidden sub-stats are generated server-side and stored per item.

**R16 - Appraisal: verification and certification**

Appraisers can verify items for others:

* Verification costs a Scrap fee.
* Item gains permanent `Certified` badge.
* Badge is visible in Bazaar listings.
* Store `certified_by_player_id`.

**R17 - Smelting (level 60+): bulk auto-smelt**

Smelting supports auto-smelt by tier:

* Select eligible junk items.
* Confirm.
* Produce Scrap deterministically.

**R18 - Smelting: cursed fragments**

Smelting supports a small chance to recover Cursed Fragments from high-level shatter sources.

Fragments must be server-side drops and stored as a material/inventory entry.

**R19 - Stabilizer Charms hook**

Phase 4 must introduce the material type and storage for Stabilizer Charms inputs.

Full crafting UI can be deferred.

### Security and authority

#### R20 - Server authority

Server must own:

* Museum locking.
* Scoring.
* HI earn/spend.
* Event modifiers and progress.
* Auto-smelt outputs.
* Certification.

RLS must block client-side writes to these outcomes.

### UX requirements

#### R21 - Museum essentials

Museum screen shows:

* Theme.
* Remaining time.
* Player score.
* Player rank.
* Leaderboard.

#### R22 - Locked item messaging

Locked items show: `Locked for Museum until <date>`.

Attempting to list a locked item fails with a clear message.

#### R23 - Titles in feed

If a player buys a title, Global Feed messages include it.

Example: `Archaeologist <PlayerName> found ...`

### Success criteria

Phase 4 is done when:

1. 40%+ of active players submit at least one museum item.
2. Players earn and spend HI to unlock multiple zones.
3. World events cause a 2x spike in active digs during the window.
4. Players reach level 99 in specialized skills and show badges in Museum.

### Open questions

* Exact score formula and multipliers.
* Event reward threshold + reward type.
* Submission cap tuning.
* Whether certification is UI-only or affects valuations.
