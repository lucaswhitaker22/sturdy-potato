---
description: >-
  Testable requirements for Phase 4 (Museum, Influence, Events, Advanced
  Skills).
---

# Phase 4 requirements

This is the build contract for Phase 4.

It turns the Phase 4 plan into concrete requirements.

### Canon and coverage rules

This page is the Phase 4 source of truth.

It must fully “cover” the functionality described in:

* [Game Overview](../../)
* [0 - Game Loop](../../game-overview/0-game-loop.md)
* [3 - The Loot & Collection Schema](../../game-overview/3-the-loot-and-collection-schema.md)
* [4 - The MMO & Economy (Macro)](../../game-overview/4-the-mmo-and-economy-macro.md)
* [5 - RPG Skilling System](../../game-overview/5-rpg-skilling-system.md)
* [6 - UI/UX Wireframe & Flow](../../game-overview/6-ui-ux-wireframe-and-flow.md)

Coverage means:

* If it ships in Phase 4, it must be a requirement here.
* If it does **not** ship in Phase 4, it must be named in **Out of scope**.

### Scope

Phase 4 ships the meta-game loops:

* Global Museum (weekly theme, locking, scoring, leaderboard).
* Historical Influence (HI) currency + Influence Shop.
* World Events (48-72h global modifiers + community goal).
* Advanced skilling (Appraisal + Smelting at level 60+).

Assumes Phase 3 exists (auth, minting, Bazaar, server authority, realtime feed).

#### Out of scope

Anything in the Game overview docs that isn’t listed as a Phase 4 requirement is out.

Explicit non-goals for Phase 4:

* Monetization store.
* Vault Credits and any premium-currency flows.
* Prismatic variants and “dissolve into Vault Credits”.
* Friends, guilds, chat, DMs.
* Cross-region servers.
* Anti-bot / anti-multibox enforcement beyond server-authoritative state.
* Full crafting systems.
  * Phase 4 can introduce materials.
  * Phase 4 can defer crafting UI and recipes.

### Data requirements

#### Profiles

Add to `profiles`:

* `historical_influence` (integer, >= 0)
* `appraisal_xp` (integer, >= 0)
* `smelting_xp` (integer, >= 0)
* `equipped_title_id` (string, nullable)

HI is non-tradable.

XP must never decrease.

#### Influence Shop and unlocks

The game must support server-owned unlocks purchased with HI.

Minimum tables (names can vary):

* `influence_shop_items`: `id`, `name`, `description`, `hi_cost`, `type`, `metadata`, `is_repeatable`
* `influence_purchases`: `id`, `player_id`, `shop_item_id`, `created_at`

Minimum shop item `type` values:

* `dig_site_permit`
* `elite_training_unlock`
* `title_unlock`
* `vault_expansion`

#### Titles

If titles exist as purchasable items, they must be defined in static data or a table.

Minimum fields:

* `titles`: `id`, `display_prefix`

#### Dig sites (zone permits)

Dig sites can be static catalog data.

Phase 4 must persist which dig sites a player has unlocked.

Minimum approach:

* `profiles.unlocked_dig_site_ids` (list) or a join table.

#### Museum

Support weekly configuration.

Minimum tables (names can vary):

* `museum_weeks`: `theme_name`, `starts_at`, `ends_at`, `status`.
* `museum_submissions`: `week_id`, `player_id`, `inventory_item_id`, `score`, `locked_until`.

The museum system must support deterministic reward payouts.

Minimum fields to support payout without re-computing the universe:

* `museum_submissions`: `finalized_at` (nullable)
* `museum_weeks`: `finalized_at` (nullable)

#### World events

Minimum tables:

* `world_events`: `name`, `starts_at`, `ends_at`, `status`, `modifiers`, `global_goal_target`, `global_goal_progress`.
* `world_event_contributions`: `event_id`, `player_id`, `contribution_value`.

`world_events.modifiers` must be structured JSON.

Minimum modifier keys:

* `extract_speed_multiplier` (number, default `1.0`)
* `sift_success_bonus_flat` (number, default `0.0`)

#### Item metadata for scoring

Inventory items must expose:

* `rarity_tier`
* `condition`
* `mint_number`
* `set_id` (nullable)

Items must support certification:

* `is_certified` (boolean)
* `certified_by_player_id` (nullable)

Inventory items must support “hidden sub-stats” once generated:

* `hidden_stats` (JSON, nullable)

#### Scoring constants (canon)

Phase 4 must define canonical mappings for:

* `rarity_tier -> base_hv`
* `condition -> multiplier`

These can be static constants in code.

They must be consistent across:

* Museum scoring
* Bazaar display (if HV is shown)

### Leveling rules (Appraisal + Smelting)

#### L1 — XP to level mapping

Appraisal and Smelting must use the same XP-to-level system as existing skills.

If the project has multiple competing curves in earlier docs, Phase 4 must pick one curve and apply it consistently.

The UI must show:

* Current level for Appraisal and Smelting.
* XP progress to next level (exact format is flexible).

#### L1a — Elite training gate (90 -> 99)

By default, Appraisal and Smelting progression must stop at level 90.

Buying the “Elite skill training unlock” in the Influence Shop must:

* Lift the cap from 90 to 99.
* Apply immediately.
* Be a one-time purchase.

The UI must clearly show whether the cap is locked or unlocked.

#### L2 — Appraisal XP sources

The player gains Appraisal XP when:

* Creating a Bazaar listing.
* Placing a bid.
* Winning an auction.
* Certifying an item (R16).

#### L3 — Smelting XP sources

The player gains Smelting XP when:

* Smelting an item into Scrap (R17).

### Functional requirements

#### Archive deck (navigation)

#### R0 — Archive deck exists

The game must add an `ARCHIVE` deck.

The Archive deck must include:

* Museum
* World Events
* Influence Shop

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

**R4a - Score inputs must be canonical**

The score must be computed from server-owned item state.

Minimum required canonical inputs:

* `rarity_tier`
* `condition`
* `mint_number`
* `set_id` (if any)
* `is_certified` (if Phase 4 chooses to include certification in scoring)

If any input is missing, scoring must fail safely.

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

**R6a - Reward tiers (minimum)**

Museum rewards must include, at minimum:

* Top 1%: `500` HI + one unique “Master” reward item (can be a key or badge token).
* Top 10%: `200` HI + `3` crates (or the Phase 4 equivalent of a crate reward).
* Participation: `50` HI (for at least one valid submission).

The exact “crates/keys” itemization can be implemented as inventory materials.

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

**R8a - Minimum zone permits**

The Influence Shop must sell permits for at least these dig sites:

* The Sunken Mall
* The Corporate Archive
* The Sovereign Vault

Unlocking a permit must immediately unlock access in the Field UI.

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

**R14a - Contribution sources**

World events must have at least one contribution source that is already a core loop action.

Minimum requirement:

* Passive or manual Scrap gain can contribute `contribution_value`.

#### R14b — Event end announcement

When an event ends:

* Broadcast an “event concluded” message to the Global Feed.
* Freeze the global progress bar.
* Grant rewards.

#### Advanced skilling

**R15 - Appraisal (level 60+): hidden sub-stats**

At Appraisal level 60+:

* UI reveals hidden sub-stats on relics.
* Hidden sub-stats are generated server-side and stored per item.

Hidden sub-stats must be generated at most once per item.

**R16 - Appraisal: verification and certification**

Appraisers can verify items for others:

* Verification costs a Scrap fee.
* Item gains permanent `Certified` badge.
* Badge is visible in Bazaar listings.
* Store `certified_by_player_id`.

**R16a - Certification scope**

Certification must be allowed only on:

* Items owned by the requesting player, or
* Items explicitly shared into a “certification request” flow.

If Phase 4 does not ship sharing, restrict certification to self-owned items.

**R17 - Smelting (level 60+): bulk auto-smelt**

Smelting supports auto-smelt by tier:

* Select eligible junk items.
* Confirm.
* Produce Scrap deterministically.

**R17a - Smelting output integrity**

Smelting output must be computed server-side.

It must be explainable.

Minimum explanation:

* “Smelted 42 Junk items into 1,260 Scrap.”

**R18 - Smelting: cursed fragments**

Smelting supports a small chance to recover Cursed Fragments from high-level shatter sources.

Fragments must be server-side drops and stored as a material/inventory entry.

**R19 - Stabilizer Charms hook**

Phase 4 must introduce the material type and storage for Stabilizer Charms inputs.

Full crafting UI can be deferred.

#### Mastery and broadcasts

**R24 — Level 99 mastery announcements (Appraisal + Smelting)**

When a player reaches level 99 in Appraisal or Smelting:

* Broadcast a Global Feed message.
* Award a permanent “Mastery badge” state for that skill.

The badge must be visible in:

* Museum leaderboard rows, and
* Bazaar identity surfaces (where the player name is shown).

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
* Do hidden sub-stats affect Museum scoring?
* Do certified items affect Museum scoring?
* What are the canonical `rarity_tier` values in Phase 4?
* What are the canonical condition tiers and multipliers in Phase 4?
* Does Museum scoring use HV directly, or derive HV from rarity?
* What is the set bonus rule? (submit full set vs already-completed collection)
