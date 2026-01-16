# Currency Systems

## Currency Systems

_Relic Vault_ uses a tri-currency model.

Each currency serves a different loop.

This prevents one resource from solving everything.

Canon anchors:

* Macro context: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md)
* Museum + HI source: [The Global Museum (Social Leaderboard)](the-global-museum-social-leaderboard.md)
* Prismatic + dissolve hook: [The "Shiny" Mechanic](../3-the-loot-and-collection-schema/the-shiny-mechanic.md)
* Bazaar sinks (tax, deposits): [The Bazaar (Auction House)](the-bazaar-auction-house.md)

### Design goals

* Keep early progression readable and grindable (Scrap).
* Keep premium value scarce and optional (Vault Credits).
* Keep prestige merit-based and untradeable (Historical Influence).
* Ensure every currency has sinks that scale with power.

Non-goals:

* No hidden conversions.
* No pay-to-win access to HI-gated content.
* No “infinite money” via circular exchanges.

### The three currencies

#### 1) Scrap (soft currency)

Scrap is the core progression spend.

It is the default Bazaar bidding currency.

Primary sources:

* Field outcomes (core loop).
* Smelting junk and duplicates.
* Selling items in the Bazaar (after tax).

Primary sinks:

* Tool upgrades and Workshop purchases.
* Skill training costs (if used).
* Bazaar fees:
  * Archive Tax on successful sales (`5%` baseline).
  * Listing deposits (anti-spam sink).
* Appraisal costs:
  * certification fees
  * paid intel actions (where applicable)
* Active ability costs (Scrap sinks, not taxes).

Non-currency note:

* **Archive Authorizations (AA)** are not a currency.\n They are a time-based “permission” resource.\n Treat them like stamina, not money.\n Spec anchor: [The Dig Site (Main Screen)](../2-the-mechanics/the-dig-site-main-screen.md).

Integrity rules:

* All deductions and grants are server-ledgered.
* Deterministic rounding is server-owned.

#### 2) Vault Credits (premium currency)

Vault Credits are the scarcity lever.

They support cosmetics and high-end convenience.

They should never be required for baseline progression.

Primary sources:

* Real-money purchase (store).
* Optional gameplay conversion:
  * dissolve Prismatic relics into Credits
  * spec: [The "Shiny" Mechanic](../3-the-loot-and-collection-schema/the-shiny-mechanic.md)

Primary sinks:

* UI skins and “OS themes”.
* Vault expansions beyond the standard track.
* Stabilizer Charms (risk mitigation tools).

Trade rule (recommended baseline):

* Credits are account-bound.
* Credits are not directly tradeable between players.

If you later support Credit-based trading:

* Treat it as a separate lane with explicit rules.
* Keep all settlement server-authoritative.

#### 3) Historical Influence (HI) (social currency)

HI is prestige currency.

It is non-tradable by design.

Primary sources:

* Weekly Museum rewards.
* World Events rewards (48–72h cycles, if shipped).
* Archive contracts / requisitions (if they mint HI).

Primary sinks:

* Influence Shop “Unbuyables”:
  * zone permits
  * elite training unlocks (push skills `90–99`, if used)
  * status tiers and titles
  * permanent Vault expansions
  * deep-cycle battery permits (AA regen rate bonus)

Spec anchor:

* [The Global Museum (Social Leaderboard)](the-global-museum-social-leaderboard.md)

Hard rules:

* HI cannot be purchased.
* HI cannot be traded.
* HI sinks must feel permanent and identity-driven.

### Interplay: how the loop feeds itself

This is the intended macro loop:

1. **Field/Lab** generates items.
2. **Vault** keeps the best items for sets and prestige.
3. **Smelting** turns the rest into Scrap.
4. **Bazaar** turns items into more Scrap (minus tax).
5. **Museum** turns locked items into HI.
6. **HI** unlocks new zones and elite systems.
7. New zones improve your item ceiling, not your odds.

Optional premium hook:

* A Prismatic drop creates a hard choice:
  * sell it for Scrap, or
  * dissolve it for Credits.

### Pricing and display rules (UX requirements)

Wallet display should always show:

* Scrap
* Vault Credits
* Historical Influence

Any spend must show a delta preview:

* “Cost: `250 Scrap`”
* “You will have: `12,340 Scrap`”

Bazaar-specific UI:

* Show held Scrap while bidding.
* Show available vs held amounts.

See: [The Bazaar (Auction House)](the-bazaar-auction-house.md).

### Authority and integrity constraints (non-negotiable)

* Currency updates are server-authoritative.
* Use a ledger model (append-only rows) for auditability.
* Never trust the client for balance checks.
* Prevent double-spend by using atomic holds for Bazaar bids.

### Telemetry (for tuning)

Track:

* Net Scrap minted vs sunk per day.
* Tax collected per day.
* Listing deposit sink rate.
* Credit sources split:
  * purchases vs prismatic dissolves
* HI minted per week and spent per week.
* Wealth distribution percentiles (Scrap).
* Price inflation indicators on key items.

### Links

* Bazaar sinks and held-currency model: [The Bazaar (Auction House)](the-bazaar-auction-house.md)
* Museum and HI source: [The Global Museum (Social Leaderboard)](the-global-museum-social-leaderboard.md)
* Prismatic dissolve hook: [The "Shiny" Mechanic](../3-the-loot-and-collection-schema/the-shiny-mechanic.md)
