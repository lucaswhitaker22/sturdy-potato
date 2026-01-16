# Economy Achievement List

## Economy Achievement List (Bazaar identity)

Economy achievements reward **market behavior**, not loot luck.

They build player archetypes:

* seller (liquidity provider),
* buyer (sniper / investor),
* appraiser (trust + disclosure),
* outlaw (Counter-Bazaar),
* collector-broker (leasing, if shipped).

System anchors:

* taxonomy + broadcast rules: [Achievement System](./)
* auction rules, escrow, holds, taxes: [The Bazaar (Auction House)](../../4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)
* currency integrity: [Currency Systems](../../4-the-mmo-and-economy-macro/currency-systems.md)
* Appraisal trust layer (certs, tax edge): [Appraisal](../../5-rpg-skilling-system/appraisal.md)
* Counter lane (confiscation risk): [The "Counter-Bazaar" (Black Market Trading)](../../../expansion-plan/macro-loop-expansion/1.-the-counter-bazaar-black-market-trading.md)
* Leasing lane (temporary transfers): [Artifact Leasing (The Rental Economy)](../../../expansion-plan/macro-loop-expansion/3.-artifact-leasing-the-rental-economy.md)

{% hint style="warning" %}
Economy achievements must not grant power that impacts pricing or odds.

No fee reductions, no tax reductions, no bid advantages.

Those belong to Appraisal and macro systems, not achievements.
{% endhint %}

***

### Global rules (hard requirements)

* Category is always `economy`.
* Progress is server-owned.
* Use **settled events** only:
  * listing created,
  * bid placed,
  * auction settled,
  * sale settled,
  * certification completed,
  * lease accepted/completed (if shipped).
* Never reward “profit” as a computed metric.
  * Reward volume and participation instead.
* Feature gates apply:
  * Bazaar achievements only exist if Bazaar ships.
  * Counter-Bazaar achievements only exist if Counter ships.
  * Leasing achievements only exist if Leasing ships.

Broadcast defaults:

* Local toast + Dossier log for almost everything.
* Global feed only for extreme signal:
  * Unique/Prismatic sales (if shipped),
  * very high sale thresholds (tune later).

***

### Track A — Seller ladder (list → sell)

### econ\_001 — Listed

**Tier:** bronze\
**Context:** If it’s not priced, it’s not real.

**Unlock condition**

* Create `1` Bazaar listing.

**Reward**

* Title: `Vendor`

**Broadcast**

* local only

***

### econ\_002 — First Sale

**Tier:** silver\
**Context:** The market agreed.

**Unlock condition**

* Complete `1` successful sale (auction settled as sold).

**Reward**

* Profile badge: `TRADED`

**Broadcast**

* local only

***

### econ\_010 — Seller I

**Tier:** silver\
**Context:** You’re providing liquidity now.

**Unlock condition**

* Complete `10` successful sales.

**Reward**

* Dossier badge: `SELLER I`

**Broadcast**

* local only

***

### econ\_011 — Seller II

**Tier:** gold\
**Context:** People recognize your listings.

**Unlock condition**

* Complete `100` successful sales.

**Reward**

* Title: `Market Regular`

**Broadcast**

* local only

***

### Track B — Sales volume (Scrap earned)

This measures **turnover**, not profit.

It should use post-tax settlement amounts.

### econ\_020 — Scrap Earned I

**Tier:** silver\
**Context:** You moved value, not just items.

**Unlock condition**

* Earn `100,000` Scrap from sales (net received after tax).

**Reward**

* Profile badge: `TURNOVER I`

**Broadcast**

* local only

***

### econ\_021 — Scrap Earned II

**Tier:** gold\
**Context:** You’re playing the macro loop.

**Unlock condition**

* Earn `1,000,000` Scrap from sales (net received after tax).

**Reward**

* Title: `Dealer`
* Profile badge: `TURNOVER II`

**Broadcast**

* local only

***

### econ\_022 — Scrap Earned III

**Tier:** gold\
**Context:** You’re part of the server’s economy.

**Unlock condition**

* Earn `10,000,000` Scrap from sales (net received after tax).

**Reward**

* Profile frame: `MARKET MAKER`
* Title: `Market Maker`

**Broadcast**

* global feed (optional, high signal)

{% hint style="info" %}
These numbers are tuning knobs.

Keep the ladder concept. Adjust thresholds after launch telemetry.
{% endhint %}

***

### Track C — Buyer ladder (bids → wins)

### econ\_030 — First Bid

**Tier:** bronze\
**Context:** You put Scrap on a belief.

**Unlock condition**

* Place `1` bid.

**Reward**

* Dossier stamp: `HELD FUNDS`

**Broadcast**

* local only

***

### econ\_031 — First Win

**Tier:** silver\
**Context:** The timer hit zero and it was yours.

**Unlock condition**

* Win `1` auction.

**Reward**

* Title: `Buyer`

**Broadcast**

* local only

***

### econ\_032 — Auction Winner I

**Tier:** silver\
**Context:** You know when to pay.

**Unlock condition**

* Win `25` auctions.

**Reward**

* Profile badge: `WINNER I`

**Broadcast**

* local only

***

### econ\_033 — Auction Winner II

**Tier:** gold\
**Context:** You are the demand side.

**Unlock condition**

* Win `250` auctions.

**Reward**

* Title: `Sniper`

**Broadcast**

* local only

***

### Track D — Trust + disclosure (certification)

Certification is an Appraisal-adjacent economy action.

Achievements should reward the habit, not add more power.

### econ\_040 — Certified

**Tier:** silver\
**Context:** You made the value legible.

**Unlock condition**

* Certify `1` item.

**Reward**

* Profile badge: `CERTIFIED`

**Broadcast**

* local only

**Notes**

* Feature-gate if Certification is not shipped.

***

### econ\_041 — Chain of Custody

**Tier:** gold\
**Context:** You’re a trusted seller now.

**Unlock condition**

* Certify `50` items.

**Reward**

* Title: `Notary`

**Broadcast**

* local only

**Notes**

* Feature-gate if Certification is not shipped.

***

### Track E — Big-ticket moments (high signal)

These are optional and can be used to drive the global feed.

They should remain rare.

### econ\_050 — Big Sale

**Tier:** gold\
**Context:** The ticker noticed you.

**Unlock condition**

* Complete a single sale with final price `>= 100,000` Scrap (tune later).

**Reward**

* Profile badge: `BIG SALE`

**Broadcast**

* global feed (optional)

**Notes**

* Keep the threshold server-configurable.
* Consider Mythic+ gating once rarity surfaces exist.

***

### econ\_051 — Unique Sale (optional)

**Tier:** gold\
**Context:** You sold history.

**Unlock condition**

* Complete `1` sale of a Unique item (if shipped).

**Reward**

* Profile frame: `UNIQUE DEALER`
* Title: `Unique Dealer`

**Broadcast**

* global feed (high signal)

**Notes**

* Hide if Uniques are not shipped in the current phase.

***

### econ\_052 — Prismatic Sale (optional)

**Tier:** gold\
**Context:** You sold the chase layer.

**Unlock condition**

* Complete `1` sale of a Prismatic item (if shipped).

**Reward**

* Profile frame: `PRISMATIC SALE`
* Title: `Prismatic Broker`

**Broadcast**

* global feed (high signal)

**Notes**

* Hide if Prismatics are not shipped.

***

### Track F — Counter-Bazaar (high-risk lane) (feature-gated)

These reward risk-taking in the 0% tax lane.

They should never encourage griefing.

### econ\_060 — Under the Table

**Tier:** silver\
**Context:** You avoided the Archive’s paperwork.

**Unlock condition**

* Create `1` Counter-Bazaar listing.

**Reward**

* Title: `Runner (Counter)`

**Broadcast**

* local only

**Notes**

* Hide if Counter-Bazaar is not shipped.

***

### econ\_061 — Counter Sale

**Tier:** gold\
**Context:** You got paid with zero tax and full risk.

**Unlock condition**

* Complete `10` successful Counter-Bazaar sales.

**Reward**

* Profile badge: `COUNTER DEALER`

**Broadcast**

* local only

**Notes**

* Hide if Counter-Bazaar is not shipped.

***

### econ\_062 — Confiscated

**Tier:** gold\
**Context:** The Archive took it.

**Unlock condition**

* Have `1` Counter-Bazaar listing confiscated.

**Reward**

* Dossier stamp: `CONFISCATED`

**Broadcast**

* local only

{% hint style="info" %}
This is a “lesson” achievement.

It should fire once and be memorable.
{% endhint %}

***

### Track G — Leasing (rental economy) (feature-gated)

Leasing creates a collector-broker role.

Achievements here should be about completed contracts.

### econ\_070 — Lender

**Tier:** silver\
**Context:** You rented history instead of selling it.

**Unlock condition**

* Complete `1` lease as the lender (lease expires/returns cleanly).

**Reward**

* Title: `Lender`

**Broadcast**

* local only

**Notes**

* Hide if Leasing is not shipped.

***

### econ\_071 — Borrower

**Tier:** silver\
**Context:** You borrowed what you were missing.

**Unlock condition**

* Complete `1` lease as the borrower.

**Reward**

* Title: `Borrower`

**Broadcast**

* local only

**Notes**

* Hide if Leasing is not shipped.

***

### econ\_072 — Lease Network

**Tier:** gold\
**Context:** You turned duplicates into contracts.

**Unlock condition**

* Complete `25` leases total (lend + borrow combined).

**Reward**

* Profile badge: `LEASE NETWORK`

**Broadcast**

* local only

**Notes**

* Hide if Leasing is not shipped.

***

### Implementation notes (event mapping)

Use settlement-driven events so progress can’t be faked.

Recommended server events:

* `bazaar_listing_created(lane)` → econ\_001 / econ\_060
* `bazaar_bid_placed(listing_id, amount)` → econ\_030
* `bazaar_auction_won(listing_id, amount)` → econ\_031+ / econ\_032+ / econ\_033+
* `bazaar_sale_settled(lane, amount_final, tax_paid, item_flags)` → seller + turnover + big-ticket
  * `item_flags` can include: `is_unique`, `is_prismatic`, `is_certified`
* `certification_completed(item_id)` → econ\_040 / econ\_041
* `counter_confiscated(listing_id)` → econ\_062
* `lease_completed(role, fee_scrap, duration)` → econ\_070 / econ\_071 / econ\_072

Hard rules:

* unlocks and reward grants are idempotent
* held funds don’t count as “spent” until settlement
* never compute progress from client-reported prices
