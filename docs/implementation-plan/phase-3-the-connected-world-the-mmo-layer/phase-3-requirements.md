---
description: Testable requirements for Phase 3 (The MMO Layer).
---

# Phase 3 requirements

This is the build contract for Phase 3.

It turns the Phase 3 plan into concrete requirements.

### Canon and coverage rules

This page is the Phase 3 source of truth.

It must fully “cover” the functionality described in:

* [Game Overview](../../)
* [0 - Game Loop](../../game-overview/0-game-loop.md)
* [2: The Mechanics](../../game-overview/2-the-mechanics.md)
* [3 - The Loot & Collection Schema](../../game-overview/3-the-loot-and-collection-schema.md)
* [4 - The MMO & Economy (Macro)](../../game-overview/4-the-mmo-and-economy-macro/)
* [6 - UI/UX Wireframe & Flow](../../game-overview/6-ui-ux-wireframe-and-flow.md)

Coverage means:

* If it ships in Phase 3, it must be a requirement here.
* If it does **not** ship in Phase 3, it must be named in **Out of scope**.

### Scope

Phase 3 turns the game into a connected, server-authoritative MMO layer:

* Global Activity Feed (realtime social proof).
* Bazaar (listing, bidding, settlement, tax).
* Minting (global serial numbers per item).
* Server authority for RNG and currency writes.

Phase 3 assumes Phase 2 is already working:

* Supabase Auth.
* Supabase persistence for player state and inventory.
* Field / Lab / Vault core loop.
* Skills and Workshop.

#### Out of scope

Anything in the Game overview docs that isn’t listed as a Phase 3 requirement is out.

Explicit non-goals for Phase 3:

* **Archive / Museum layer**
  * Weekly themes, donations, leaderboards, reward payout.
  * Historical Influence and any Influence shop.
  * Global quests.
* **Currencies beyond Scrap**
  * Vault Credits (premium currency) and any monetization flows.
  * Prismatic dissolving into Vault Credits.
* **Loot identity beyond mint**
  * Condition modifiers.
  * Full Historical Value (HV) economy math (unless already shipped earlier).
  * Prismatic (“shiny”) variants (rolls, visuals, value multipliers).
* **Bazaar features not required to ship auctions**
  * Appraisal-based “certified listings” and any skill-gated market perks.
  * Advanced search filters and category browsing.
  * Listing slots / storefront UX.
* **Social systems**
  * Guilds, friends, chat, DMs.
* **Infrastructure**
  * Cross-region servers.
* **Security hardening beyond server authority**
  * Anti-bot / anti-multibox enforcement beyond server-authoritative state.
  * Fraud detection, chargebacks, customer support tooling.

### Data requirements

#### Player profile

`profiles` must remain the source of truth for:

* `scrap` (integer, >= 0)

Client writes to `profiles.scrap` must be blocked.

Only server-side functions may mutate it.

#### Item identity

Every owned item in `inventory` must support minting:

* `item_catalog_id`
* `mint_number` (integer, >= 1)

`mint_number` must be globally unique per `item_catalog_id`.

Example:

* There is one `Ceramic Mug #001` in the entire world.

#### Market data

The game must support auctions.

Minimum tables (names can vary):

* `market_listings`
* `market_bids`

A listing must store:

* `id`
* `seller_id`
* `inventory_item_id`
* `reserve_price_scrap`
* `ends_at`
* `status` (`active` | `ended` | `cancelled`)
* `highest_bid_scrap` (denormalized allowed)
* `highest_bidder_id` (denormalized allowed)

A bid must store:

* `id`
* `listing_id`
* `bidder_id`
* `bid_scrap`
* `created_at`

#### Activity feed

The game must persist broadcastable events.

Minimum fields:

* `id`
* `event_type`
* `created_at`
* `payload` (JSON)

Events must be broadcast via Realtime.

### Functional requirements

#### R1 — Global Activity Feed visibility

The Global Feed must be visible on every primary deck:

* Field
* Lab
* Vault
* Workshop
* Collections
* Bazaar

The feed must be readable on mobile.

It must not block input.

#### R2 — Feed realtime delivery

When a feed event is created, all online clients must receive it within 2 seconds.

Clients must not poll.

Clients must use Supabase Realtime.

#### R3 — Feed event types

The feed must support these event types:

* Epic Finds
* High-Stakes Gambles
* Bazaar Sales

Each event must render as a single-line ticker message.

Minimum required strings:

* `"<player> just unearthed [<Item Name> #<Mint>]!"`
* `"<player> successfully sifted a Crate to Stage <N>!"`
* `"A [<Item Name>] was just sold for <X> Scrap!"`

{% hint style="info" %}
“Epic” is a label here. If Phase 3 does not ship full rarity tiers, use “Rare” as the broadcast gate.
{% endhint %}

#### R4 — Feed retention

Clients must show the last N events on load.

N must be at least 50.

Older events can be truncated.

#### R5 — Bazaar access

The game must add a Bazaar screen/tab.

Only authenticated users can access Bazaar.

#### R6 — Listing creation

A seller can list an item from their Vault.

Listing requires:

* Selecting exactly one owned inventory item.
* Setting a duration.
* Setting a reserve price (minimum bid).

Allowed durations must include:

* 24 hours

On listing creation:

* The item must be escrowed.
* The seller must not be able to use the item.

#### R6a — Listing deposit (anti-spam)

Creating a listing must require a fixed Scrap deposit.

Rules:

* The deposit amount must be a single constant (Phase 3 can pick any value).
* The deposit must be held in escrow while the listing is active.
* On settlement:
  * If the item sells, the deposit is returned to the seller.
  * If the item does not sell, the deposit is returned to the seller.
* If Phase 3 ships seller-cancel (see Open questions), define whether the deposit is returned or burned.

{% hint style="info" %}
This matches the “listing deposit to reduce spam” mechanic described in the Macro economy doc.
{% endhint %}

#### R7 — Listing browsing

Buyers must be able to view active listings.

Each listing must show:

* Item name
* Mint number
* Time remaining
* Current highest bid
* Reserve price

#### R8 — Bidding and bid holds

A buyer can place a bid if:

* Listing status is `active`.
* Current time is before `ends_at`.
* Bid is >= reserve price.
* Bid is > current highest bid.
* Buyer has enough Scrap.

When a bid is accepted:

* Bidder’s Scrap is held.
* Held Scrap cannot be spent elsewhere.

Held Scrap must be released if the bidder is outbid.

#### R9 — Outbid behavior

When a bidder is outbid:

* Their held Scrap must be returned immediately.
* They must receive a notification.

Minimum notification string:

* `"You have been outbid on [Item Name]!"`

#### R10 — Auction settlement

At `ends_at`, the listing must resolve exactly one of these outcomes:

1. No valid bids:
   * Listing ends.
   * Item returns to seller.
2. At least one valid bid:
   * Highest bidder receives the item.
   * Seller receives Scrap minus tax.
   * A Bazaar Sale feed event is created.

Settlement must be performed server-side.

It must be idempotent.

#### R11 — Archive tax

A 5% Archive Tax must be applied to successful sales.

Tax is deducted from the seller payout.

Tax rounding rule must be deterministic.

Example:

* 101 Scrap sale with 5% tax.
* Payout is either 95 or 96.
* Pick one rounding rule and enforce it.

#### R12 — Minting on item generation

When a new inventory item is created via the server authority layer:

* A mint number must be assigned.
* Mint numbers must increment per `item_catalog_id`.

Mint number assignment must be atomic.

Two simultaneous drops must never receive the same mint number.

#### R13 — Mint prestige multiplier

Low mints must be meaningfully special.

Minimum rule:

* Mint numbers 1–10 receive a `+50%` HV multiplier (`1.5x`).

The multiplier must be visible in the UI.

{% hint style="info" %}
If HV is not yet shipped, expose the prestige as a “Low Mint (+50%)” badge. Do not block Phase 3 on HV math.
{% endhint %}

#### R14 — Server-authoritative RNG and economy

The client must not resolve:

* Sift success rolls.
* Loot outcomes.
* Mint assignment.
* Scrap modifications.

The client may only send requests.

The server must validate:

* Player identity.
* Player has the referenced crate.
* Player has enough Scrap for the requested action.

#### R15 — Client request / server response flow (handshake)

The Phase 3 handshake must exist for at least the Sift action:

1. Player clicks `[SIFT]`.
2. Client sends a request to the server.
3. Server validates state.
4. Server performs RNG and writes results.
5. Client receives the result and renders it.

On validation failure:

* No state is mutated.
* Client shows a clear error.

#### R16 — Realtime updates

When these things happen, clients must update without refresh:

* New feed events.
* New bids on a listing.
* A listing ends.

### Security and integrity requirements

#### R17 — Database write policies

Row-level security must prevent:

* A user modifying another user’s inventory.
* A user modifying another user’s scrap.
* A user editing market listings to change reserve price or winner.

#### R18 — Client tamper resistance

Manually editing Scrap in browser devtools must not persist.

Any direct write attempt must fail.

The UI must recover by reloading server state.

### UX requirements

#### R19 — Bazaar notifications

The client must show notifications for:

* Being outbid.
* Winning an auction.
* A listed item selling.

#### R20 — Feed placement

The Global Feed must be present but subtle:

* Single-line ticker.
* Does not cover primary buttons.

### Success criteria

Phase 3 is done when:

1. At least 50 successful player-to-player sales occur in Bazaar.
2. A “Rare Find” feed event reaches all online players simultaneously.
3. Attempting to edit Scrap locally fails and does not persist.
4. Players consistently bid more for low-mint items (e.g. `#001`).

### Open questions (needs decisions)

* What is the minimum rarity threshold for feed broadcasts?
* Do we allow sellers to cancel listings early?
* If sellers can cancel: is the listing deposit returned or burned?
* Do we cap active listings per user?
* Do we implement “held Scrap” as a separate balance (`scrap_available` vs `scrap_held`)?
* Do we ship HV now, or defer and only ship mint prestige UI?
