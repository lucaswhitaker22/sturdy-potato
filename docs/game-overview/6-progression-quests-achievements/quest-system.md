# Quest System

## Quest System (Archive Directives)

Quests are **directed goals**, not a new mini-game.

They exist to answer: **“What should I do next?”**

They must plug into the existing 5-deck loop.

Core loop anchor: [0 - Game Loop](../0-game-loop.md).

***

### Design goals

Quests must:

* Teach the loop without walls of text.
* Create short-term targets that feed long-term systems.
* Add narrative flavor in a UI-first world.
* Respect canonical odds and scoring.

Quests must not:

* Change drop tables, stability, or mint odds.
* Force “chore play” every day.
* Require Bazaar usage for core dailies.
* Ask for RNG outcomes (“find a Mythic”).

{% hint style="info" %}
Quests are a guidance layer.

They do not replace skills, sets, HI, or the Workshop.
{% endhint %}

***

### Where quests live (UI)

Primary location: **\[05] ARCHIVE**.

This matches the navigation model in [6 - UI/UX Wireframe & Flow](../6-ui-ux-wireframe-and-flow.md).

Recommended surfaces:

* **Quest Board** (list of available and accepted directives).
* **Tracker chip** (up to 3 pinned objectives, visible in any deck).
* **Claim panel** (one-click claim, then auto-show “next quest”).

***

### Vocabulary (keep this consistent)

Use one in-world umbrella term: **Archive Directives**.

Within that:

* **Onboarding Directives**: the first-session questline.
* **Daily Directives**: low-friction repeatables.
* **Weekly Contracts**: longer repeatables aligned to the Museum week.
* **Event Contracts**: time-boxed directives tied to world events.
* **Expeditions / Requisitions**: “quest board” contracts that often consume items.
  * Full spec: [Lore Keeper Requisitions (Archive Expeditions)](../../expansion-plan/macro-loop-expansion/6.-lore-keeper-requisitions-archive-expeditions.md).

{% hint style="warning" %}
Don’t invent a second quest system.

Expeditions are a _type_ of directive, not a parallel feature.
{% endhint %}

***

### Quest lifecycle (state machine)

Keep quest states minimal and deterministic:

1. `AVAILABLE` (visible on board).
2. `ACCEPTED` (player has it).
3. `IN_PROGRESS` (any objective has progress).
4. `COMPLETED` (all objectives met).
5. `CLAIMED` (rewards granted).
6. `EXPIRED` (time-boxed content ended).

Recommended limits:

* Max **accepted** at once: `3–5` (tunable).
* Max **tracked** at once: `3`.

Hard rule:

* Reward grant must be idempotent.
* “Double claim” must be impossible.

***

### Quest anatomy (canonical template)

Every quest must define:

* **Context line** (one sentence of fiction).
* **Requirements** (prereqs and gates).
* **Objectives** (server-tracked counters).
* **Rewards** (explicit lines).
* **Expiry** (optional).
* **Anti-cheese** rules (optional).

#### Minimal data shape

```json
{
  "id": "archive_boot_01",
  "type": "onboarding",
  "title": "Boot Sequence",
  "context": "The Archive terminal is waking up.",
  "requirements": {
    "min_total_level": 0,
    "min_hi": 0,
    "prereq_quest_ids": []
  },
  "objectives": [
    { "kind": "extract_manual", "target": 10, "zone_id": null }
  ],
  "rewards": [
    { "kind": "scrap", "amount": 250 },
    { "kind": "title", "id": "field_agent" }
  ],
  "expires_at": null,
  "anti_cheese": { "count_unique_actions": true }
}
```

The backend can store a different shape.

The concept must match this everywhere.

***

### Objective language (what quests can ask for)

Objectives must be:

* measurable,
* server-owned,
* based on existing loop actions.

#### Preferred objective types

Field / Lab:

* `extract_manual`: complete `N` manual **\[EXTRACT]** actions.
* `crate_obtained`: obtain `N` Encapsulated Crates.
* `sift_attempted`: attempt `N` **\[SIFT]** actions.
* `claim_stage_at_least`: successfully **\[CLAIM]** at Stage `X+`.

Vault / Smelting:

* `smelt_items`: smelt `N` items (optionally gated by tier).
* `set_entries_added`: add `N` items to set tracking.
* `set_completed`: complete `N` sets.

Bazaar (never required for dailies):

* `listings_created`: create `N` listings.
* `auctions_won`: win `N` auctions (cap per week).

Archive / Museum:

* `museum_submissions`: submit `N` theme-matching items.
* `museum_score_earned`: earn `N` Museum Score this week.

Canon anchors:

* Field actions: [The Dig Site (Main Screen)](../2-the-mechanics/the-dig-site-main-screen.md)
* Lab actions: [The Refiner (The Gambling Hub)](../2-the-mechanics/the-refiner-the-gambling-hub.md)
* Museum rules: [The Global Museum (Social Leaderboard)](../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)

#### Avoid objective types

* RNG outcomes (“Find a Unique”, “Get Mint #001”).
* “Play X days”.
* “Spend premium currency”.

If you want “chase” content, use Achievements.

See: [Achievement System](achievement-system.md).

***

### Rewards (safe by default)

Rewards should mostly be:

* **Scrap** (early/mid progression).
* **Cosmetics** (titles, frames, UI stamps).
* **Convenience unlocks** (extra preset slot, extra listing slot).

Allowed prestige rewards:

* small HI grants on rare contracts,
* but only if it fits the economy.

HI rules: [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md).

{% hint style="warning" %}
Do not reward:

* Crate chance,
* Anomaly chance,
* direct Lab Stability,
* “better rarity odds”.

Those are canonical system surfaces.
{% endhint %}

***

### Quest types (baseline catalog)

#### 1) Onboarding chain (one-time)

Goal: teach the loop in order.

Target completion time: `15–30m`.

Recommended baseline sequence:

1. **Boot Sequence**: `10` manual extracts → `250` Scrap.
2. **First Crate**: obtain `1` crate → `500` Scrap.
3. **Enter the Lab**: open `1` crate → `100` Scrap.
4. **First Gamble**: attempt `1` sift (Stage 1+) → `10` Fine Dust.
5. **Claim Discipline**: claim (Stage 1+) → `1,000` Scrap.
6. **The Vault Matters**: smelt `3` Junk items → `750` Scrap.
7. **Set Awareness**: add `1` item to a set tracker → cosmetic “ARCHIVE LABEL”.
8. **The Bazaar Door**: create `1` listing → temporary listing slot or Scrap.
9. **Museum Week**: submit `1` theme match → `25` HI starter grant.
10. **Your First Title**: finish chain → title “Field Agent”.

The “profit vs prestige” lesson must be explicit.

Museum rules: [The Global Museum (Social Leaderboard)](../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md).

#### 2) Daily Directives (repeatable)

Goal: a “small win” that nudges the loop.

Target completion time: `5–15m`.

Rules:

* Never require the Bazaar.
* Never require specific items.

Examples:

* “Run the Field”: `25` manual extracts.
* “Push Your Luck”: attempt `5` sifts (any stage).
* “Clean House”: smelt `10` items.

#### 3) Weekly Contracts (repeatable)

Goal: align to the weekly Museum cycle.

Target completion time: `30–90m`.

Examples:

* “Exhibit Prep”: submit `5` theme matches this week.
* “Risk Week”: claim `3` times at Stage `3+`.
* “Market Week”: create `5` listings (no sales required).

#### 4) Event Contracts (time-boxed)

Goal: attach a goal to a world event without changing odds.

Event system: ["The Great Static" Events (incl. Static Pulses)](../../expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md).

Examples:

* “Magnetic Interference”: trigger `3` anomalies (still `5%` per extract).
* “Archive Audit”: submit `10` items across the event window.

#### 5) Expeditions / Requisitions (contract board)

These are directive templates that often involve **turn-ins**.

They create item sinks and long-term targets.

Full mechanics and anti-abuse: [Lore Keeper Requisitions (Archive Expeditions)](../../expansion-plan/macro-loop-expansion/6.-lore-keeper-requisitions-archive-expeditions.md).

***

### Gates and pacing rules

Quests can introduce gates.

They must not bypass them.

Canon gate model:

* Total Level gates: [5 - RPG Skilling System](../5-rpg-skilling-system/)
* HI permit gates: [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md)

Rule:

* If a quest references a locked zone, show the exact lock reason.

***

### Integrity rules (non-negotiable)

* All progress tracking is server-authoritative.
* All reward granting is server-authoritative.
* Objectives increment only from validated events.
* Rewards grant once, enforced by an idempotency key.
* Quests must not rewrite canonical odds.

Canonical odds to protect:

* Field anomaly chance is always `5%`.\
  Spec: [The Dig Site (Main Screen)](../2-the-mechanics/the-dig-site-main-screen.md)
* Lab stage table is canonical.\
  Spec: [The Refiner (The Gambling Hub)](../2-the-mechanics/the-refiner-the-gambling-hub.md)

***

### Telemetry (so tuning is real)

Track:

* Onboarding completion rate and time-to-complete.
* Step drop-off points in onboarding.
* Daily completion rate and abandon rate.
* Weekly completion distribution (by power band).
* Reward claim rate (detect UI issues).
* Quest-induced behavior shifts:
  * more sifts,
  * more museum submissions,
  * more smelting.
