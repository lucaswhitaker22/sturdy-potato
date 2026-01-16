# The Bazaar (Auction House)

## The Bazaar (Auction House)

The Bazaar is the player-driven market.

It turns loot identity into social value.

It is a core pillar of the Macro loop.

Location: **\[04] THE BAZAAR**.

Canon anchors:

* Macro role and lane overview: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md)
* Loot identity surfaces (mint, condition, HV lines): [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md)
* Mint + condition hard rules: [The "Mint & Condition" System](../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)
* Appraisal skill gates (certification, tax edge, Hype Train): [Appraisal](../5-rpg-skilling-system/appraisal.md)

### Design goals

* Make rare finds liquid without losing identity.
* Create a clean Scrap sink via tax and deposits.
* Keep transactions server-authoritative and auditable.
* Make market activity feel “alive” via broadcasts and feeds.
* Reward Appraisal as “trust + visibility”, not RNG manipulation.

Non-goals:

* No direct drop-rate changes.
* No hidden multipliers.
* No client-trusted pricing or settlement.

### What the Bazaar sells

The Bazaar sells **owned items** from the Vault.

Minimum supported item types:

* Any standard relic item.
* Certified relics (badge + disclosed stats).
* Prismatics (if shipped in your phase).

Optional later:

* Lease Offers. See [Artifact Leasing (The Rental Economy)](../../expansion-plan/macro-loop-expansion/3.-artifact-leasing-the-rental-economy.md).

### Core concepts

#### Listing

A Listing is an auction wrapper around one item.

It has:

* seller
* reserve price (minimum bid)
* duration
* end timestamp
* market lane (`bazaar` vs `counter`)

#### Escrow (hard requirement)

Listed items are placed into escrow.

Escrow rules:

* The seller cannot use the item.
* The seller cannot smelt the item.
* The seller cannot submit the item to the Museum.
* The seller cannot lease or endow the item.

This must match the canonical lock-state rules in:

* [The "Mint & Condition" System](../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)

#### Held currency (hard requirement)

Bids use a held-currency model.

When you bid, Scrap is held immediately.

Held Scrap cannot be spent elsewhere.

If outbid, held Scrap returns immediately.

### Player flows

#### Flow A — create a listing

Requirements:

* Exactly one owned item.
* Item is not locked (escrow, museum, set-lock, leased).
* Reserve price in Scrap.
* Duration.

Recommended Phase 3 defaults:

* Duration: `24h`.
* Max active listings per player: `5` (tunable).

Listing deposit (anti-spam):

* Creating a listing costs a small Scrap deposit.
* Deposit is a sink by default (recommended).

{% hint style="info" %}
If you want a softer sink, refund deposit on successful sale only.
{% endhint %}

#### Flow B — bid on a listing

Rules:

* A bid must be `>=` the reserve price.
* A bid must be `>= current_bid + min_increment`.
* Scrap is held on bid placement.

Recommended minimum increment:

* `min_increment = max(1% of current_bid, 10 Scrap)` (tunable).

Outbid behavior:

* Previous highest bidder gets an immediate refund.
* Send a notification: `You have been outbid on <Item>.`

#### Flow C — auction resolution

At `end_at`, the server settles the listing.

On successful sale:

* Buyer receives the item.
* Seller receives Scrap payout minus Archive Tax.
* Listing becomes immutable and archived.

On no bids:

* The item returns to the seller.
* Listing closes as `expired`.

### Archive Tax (inflation control)

The Bazaar has an Archive Tax.

Baseline tax:

* `5%` of final sale price.

Appraisal mastery edge:

* Appraisal `99` reduces seller tax to `2.5%`.
* This is a seller-side perk only.

Tax integrity rules:

* Tax is computed server-side.
* Use deterministic rounding.
* Store the applied tax rate on the sale record.

Counter lane exception:

* Counter-Bazaar uses `0%` tax.
* It adds confiscation risk instead.
* Full spec: [The "Counter-Bazaar" (Black Market Trading)](../../expansion-plan/macro-loop-expansion/1.-the-counter-bazaar-black-market-trading.md)

### Anti-abuse rules (recommended baseline)

These prevent griefing and market spam.

Listing constraints:

* Enforce a per-player listing cap.
* Disallow listing items in any lock state.
* Rate-limit listing creation per minute.

Bidding constraints:

* Rate-limit bids per listing per minute.
* Require a minimum bid increment.
* Block bids if held funds are insufficient.

Cancellation constraints (tunable):

* Allow cancel only if there are no bids.
* Optionally block cancel in last `5m`.

Anti-sniping (optional):

* If a bid lands in the last `60s`, extend by `30s`.
* Cap extensions to prevent infinite auctions.

### Item information surfaces (trust + pricing)

Listings must surface loot identity consistently.

Minimum listing card fields:

* Item name + mint number (`<Item> #<mint>`).
* Rarity tier.
* Condition stamp.
* Prismatic badge (if any).
* Certified badge (if any).
* Seller name.
* Current bid and reserve.
* Time remaining.

HV display rule:

* If you show HV, show breakdown lines.
* No hidden multipliers.

Source of truth:

* [The "Mint & Condition" System](../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)

### Search, filters, and sorting (minimum UX)

This is a text-first market.

Minimum filters:

* Search by item name substring.
* Rarity tier.
* Condition.
* `Certified only`.
* `Prismatic only` (if shipped).
* Price range (Scrap).
* Time remaining.

Minimum sorting:

* Ending soon.
* Lowest current bid.
* Highest current bid.
* Newest listed.

### UI/UX requirements (the “Oasis” screen)

The Bazaar is an “Oasis” screen.

It should feel safe and stable.

Visual rules:

* Clean text layout.
* Low visual noise.
* Stable, non-animated background beats.
* Filters always visible, not buried in menus.

Mobile rules:

* Large thumb-accessible buttons.
* Condensed single-line ticker at the top.

### Social proof: ticker + broadcasts

The Bazaar should feel like the world’s heartbeat.

#### Global ticker (Bazaar-local)

Show a scrolling ticker at the top of the Bazaar.

Ticker events (recommended):

* New listing created (high-signal only).
* Big sale completed.
* Global announcements (Unique drops, 99 mastery pings).

#### Global broadcasts (game-wide)

Broadcast only meaningful events.

Recommended thresholds:

* Mythic+ sale.
* Prismatic sale.
* Any Unique sale.

### Appraisal integration (merchant skill)

Appraisal is the Bazaar’s “trust layer”.

It must not change loot RNG.

#### Certification (trust + disclosure)

Certification adds a permanent `Certified` badge.

It reveals hidden sub-stats in a trusted way.

Rules:

* Certification is server-owned and audited.
* Certified status is stored on the item.
* “Once per item” HV bonuses must not stack.

Full spec: [Appraisal](../5-rpg-skilling-system/appraisal.md).

#### Hype Train (visibility spike)

Hype Train is Appraisal `60+`.

It boosts visibility only.

It must not change prices or bid rules.

Spec: [Active Skill Abilities](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md).

### Data model (minimum, server-side)

This is the minimum shape needed for integrity.

#### Listing record

* `listing_id`
* `lane` (`bazaar` | `counter`)
* `item_id`
* `seller_player_id`
* `reserve_price_scrap`
* `current_bid_scrap` (nullable)
* `highest_bidder_player_id` (nullable)
* `end_at`
* `status` (`active` | `sold` | `expired` | `cancelled` | `confiscated`)
* `deposit_paid_scrap`
* `created_at`
* `closed_at` (nullable)

#### Bid holds

You can store holds as ledger rows.

Minimum fields:

* `hold_id`
* `listing_id`
* `player_id`
* `amount_scrap`
* `created_at`
* `released_at` (nullable)
* `reason` (`outbid` | `win` | `cancelled` | `expired`)

### Authority and integrity constraints (non-negotiable)

* Escrow is server-authoritative.
* Auction end and settlement are server-owned.
* Mint numbers are never assigned client-side.
* Bids use held currency, not “promise to pay”.
* All multipliers shown to players are explicit lines.

### Telemetry (for tuning)

Track:

* Active listings over time.
* Listing conversion rate (sold vs expired).
* Median time-to-sale by rarity tier.
* Total tax collected per day.
* Bid spam signals (bids/min, cancels, relists).
* Hype Train usage and sale-time delta.
* Counter lane confiscation rate (if shipped).

### Links

* Macro overview: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md)
* Counter lane: [The "Counter-Bazaar" (Black Market Trading)](../../expansion-plan/macro-loop-expansion/1.-the-counter-bazaar-black-market-trading.md)
* Leasing lane: [Artifact Leasing (The Rental Economy)](../../expansion-plan/macro-loop-expansion/3.-artifact-leasing-the-rental-economy.md)
* Loot identity: [The "Mint & Condition" System](../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)
* Appraisal and certification: [Appraisal](../5-rpg-skilling-system/appraisal.md)
