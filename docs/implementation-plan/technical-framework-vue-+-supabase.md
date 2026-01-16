# Technical Framework (Vue + Supabase)

### 1. System Architecture

The target architecture is server-authoritative.

Phase guidance:

* Phase 1 can be client-only for speed (local persistence).
* Phase 3+ must be server-authoritative for RNG and economy integrity.

When server-authoritative is enabled, all RNG and currency writes happen via Supabase Edge Functions or PostgreSQL RPC, not on the client.

* Frontend: Vue 3 (Composition API) + Pinia (State Management).
* Backend: Supabase Auth, PostgreSQL, and Realtime (Broadcast/Presence).
* Styling: Tailwind CSS (for rapid Brutalist UI styling).

***

### 2. Authority model (the “no cheating” contract)

Server-authoritative means:

* The client sends **intent** only.
* The server resolves outcomes and writes state.
* The client renders the returned result.

Hard rules:

* RNG is never run on the client (Field, Lab, minting, anomaly charge).
* Currency writes are never client-trusted (Scrap, holds, HI, Credits).
* Item lock states are enforced server-side (escrow, museum lock, leased, set-lock).

Canon anchors:

* Core loop + invariants: [2: The Mechanics](../game-overview/2-the-mechanics.md)
* Bazaar integrity (holds + escrow): [The Bazaar (Auction House)](../game-overview/4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)

***

### 3. Database model (minimum viable schema)

This is the “ship it” shape.

You can add fields later, but don’t remove auditability.

#### Core tables

* `profiles`
  * `user_id` (auth UID, PK)
  * `scrap_balance`
  * `vault_credits_balance` (phase 5+)
  * `historical_influence_balance` (phase 4+)
  * AA state (Archive Authorizations):\n `aa_current`, `aa_max`, `aa_updated_at`, `aa_regen_rate_mult`
  * Offline buffer clock:\n `last_seen_at` (or `last_logout_at`)
  * XP fields per skill (or a single xp table)
  * skill branch picks (nullable until 60)
* `inventory_items`
  * `item_id` (PK)
  * `owner_user_id`
  * `item_catalog_id`
  * `rarity`
  * `condition`
  * `mint_number` (nullable until assigned)
  * lock flags / lock state enum (escrow, museum, leased, endowed, set-locked)
* `currency_ledger`
  * append-only rows for all balance changes
  * `user_id`, `currency`, `amount_delta`, `reason`, `idempotency_key`

#### Economy tables (phase 3+)

* `bazaar_listings`
* `bazaar_bids` (optional) or “highest bid only”
* `currency_holds` (for bids)
* `mint_registry` (per `item_catalog_id` counter or atomic allocator)

#### Archive tables (phase 4+)

* `museum_weeks` (theme, start/end)
* `museum_submissions` (user + item)
* `museum_scores` (materialized or computed-on-close)
* `influence_shop_purchases`

{% hint style="info" %}
Prefer explicit “ledger + current balance”.\n Current balance is fast UX.\n Ledger is audit and anti-fraud.
{% endhint %}

***

### 4. RLS + write paths (recommended pattern)

Baseline RLS stance:

* Clients can `SELECT` their own state.
* Clients cannot directly mutate economy-critical rows.

Recommended write paths:

* PostgreSQL RPC (fast, transactional) for:
  * `rpc_extract()`
  * `rpc_sift()`
  * `rpc_claim()`
  * `rpc_smelt_item()` / `rpc_bulk_smelt()`
  * `rpc_create_listing()` / `rpc_place_bid()` / `rpc_settle_auction()`
* Edge Functions for:
  * scheduled settlement jobs
  * world event start/end orchestration
  * admin tooling (theme rotation, event injection)

Idempotency is mandatory for:

* auction settlement
* museum week close
* quest reward claims (if shipped)

***

### 5. Realtime (where it’s worth it)

Use Supabase Realtime for “social proof”, not core truth.

Good realtime targets:

* Global Activity Feed (broadcast channel)
* Bazaar listing updates and bid updates
* Museum leaderboard updates (top slice only)

Bad realtime targets:

* authoritative balance calculations
* mint assignment
* RNG resolution

***

### 6. Frontend state model (Vue + Pinia)

Recommended stores:

* `useProfileStore()` (balances, skill levels, gates)
* `useFieldStore()` (tray state, extract cooldowns, overload meter UI)
* `useLabStore()` (active crate, stage, stability UI)
* `useVaultStore()` (inventory list, set tracker, locks)
* `useBazaarStore()` (listings, bids, held funds)
* `useArchiveStore()` (museum week, submissions, quests/achievements)

Rules:

* Treat the DB as source of truth.
* Use optimistic UI sparingly.\n Only for purely visual transitions.
* Persist only non-authoritative UI preferences locally.
