---
description: Testable requirements for the Clicker Foundation MVP.
---

# Phase 1 (MVP) requirements

This is the build contract for Phase 1.

It turns the Phase 1 plan into concrete requirements.

Canon for Phase 1 terms and odds:

* [2: The Mechanics](../../game-overview/2-the-mechanics.md)
* [3 - The Loot & Collection Schema](../../game-overview/3-the-loot-and-collection-schema.md)

### Scope

Phase 1 ships a single-player loop:

* Extract to earn Scrap.
* Occasionally drop a Crate.
* Sometimes trigger an Anomaly (Phase 1: log-only).
* Claim or Sift the Crate in the Lab.
* Save successful items into the Vault.

Out of scope:

* Bazaar and trading.
* Skills and XP.
* Sets, mint numbers, condition, and prismatic variants.
* Multiplayer, leaderboards, and Archive events.

### Data requirements

#### Player state

The game must persist these fields:

* `scrap_balance` (integer, >= 0)
* `crate_tray` (list of Crate objects, max length 5)
* `active_crate_id` (string, nullable)
* `vault_items` (list of item IDs)

Each Crate object must include:

* `id` (string)
* `stage` (integer, 0–5)

Persistence can be local storage for MVP.

A page reload must restore state.

#### Item catalog

A fixed catalog of 20 items must exist:

* 12 Common-tier items
* 8 Rare-tier items

Each item needs:

* `id`
* `name`
* `tier` (`common` | `rare`)
* `flavor_text`

### Functional requirements

#### R1 — Field screen (Extract)

* The Field shows:
  * Scrap balance.
  * Crate tray count (e.g. `3/5`) derived from `crate_tray.length`.
  * An `EXTRACT` button.
  * An extraction progress indicator.
  * An action log.
* Clicking `EXTRACT` triggers a 3-second cooldown.
* While on cooldown:
  * The button is disabled.
  * The progress indicator animates.
* If the crate tray is full (`5/5`):
  * `EXTRACT` is disabled.
  * The UI communicates “Tray full”.

#### R2 — Extract RNG

Each successful Extract resolves exactly one outcome:

* 80%: add `+10` Scrap.
* 15%: add `+1` Crate.
* 5%: trigger an Anomaly.

If the crate outcome occurs:

* A new Crate object is appended to `crate_tray`.
* The new Crate starts at `stage = 0`.
* A “crate obtained” feedback beat plays.

If the Anomaly outcome occurs:

* No currency or inventory state changes.
* The log records an anomaly message.

#### R3 — Navigation between modes

The MVP must let the player move between:

* Field (Extract)
* Lab (Crate refinement)
* Vault (item list)

Navigation can be tabs or buttons.

State must remain consistent across modes.

#### R4 — Lab screen (Crate selection)

* The Lab shows current tray count (0–5).
* The player can select a Crate from the tray to refine.

If no crates exist:

* The Lab shows an empty state.
* Claim / Sift actions are disabled.

#### R5 — Refinement stage model

A Crate has:

* `stage` (integer, 0–5)

The current active Crate is tracked by:

* `active_crate_id` (nullable)

Stage names and odds:

* Stage 0: Raw Open, 100% success, 100% Junk
* Stage 1: Surface Brush, 90% success, 80% Junk / 20% Common
* Stage 2: Chemical Wash, 75% success, 60% Common / 40% Rare
* Stage 3: Sonic Vibration, 50% success, 90% Rare / 10% Epic
* Stage 4: Molecular Scan, 25% success, 100% Epic
* Stage 5: Quantum Reveal, 10% success, 100% Epic

Notes for MVP:

* “Junk” means “no Vault item granted”.
* “Epic” is allowed as a label.
* For MVP, Epic rewards draw from the Rare pool.
* This keeps the catalog at 20 items.

#### R6 — Lab actions (Claim vs Sift)

At any stage, the player can choose:

* `CLAIM` (take reward at current stage)
* `SIFT` (attempt to advance to next stage)

Rules:

* `SIFT` executes the stage success roll.
* On success, stage increments by 1.
* On failure, the Crate shatters.

#### R7 — Shatter failure state

On shatter:

* The active Crate is destroyed.
* The Crate is removed from `crate_tray`.
* Player receives `+3` Scrap.
* The UI plays a clear failure beat.
* The log records the event.

#### R8 — Reward resolution

On `CLAIM`:

* The Crate resolves into either:
  * No item (Junk), or
  * A Vault item from the catalog.

If a Vault item is awarded:

* The item is appended to `vault_items`.
* The log records the item name.

After resolution:

* The Crate is removed.
* The active refinement state clears.

#### R9 — Vault screen

* The Vault lists all awarded items.
* Each item shows name and flavor text.

The Vault also shows progress:

* `items_found / 20`

Duplicates are allowed in MVP.

### UX requirements

#### Feedback beats

The UI must distinguish these events:

* Scrap gain
* Crate drop
* Sift success
* Shatter failure
* Item reveal

Text-only feedback is acceptable.

Sound and animation hooks can be placeholders.

#### Logging

The action log must record:

* Each Extract outcome
* Each Sift attempt outcome
* Each Claim reward outcome

### Success criteria

Phase 1 is done when:

1. Players can earn Scrap through Extract.
2. Crates can drop and fill the tray.
3. Crates can be refined and can shatter.
4. Successful items persist in the Vault.
5. Reloading the page restores state.

### Open questions

* Should the MVP allow refining multiple crates in parallel?
* Do we want an explicit “discard crate” action?
* Do we cap Vault size in Phase 1?
* Do we want true Epic items in Phase 1?
