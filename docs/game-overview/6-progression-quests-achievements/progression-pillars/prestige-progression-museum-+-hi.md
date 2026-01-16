# Prestige progression (Museum + HI)

## Prestige progression (Museum + HI)

Prestige progression is the social ladder.

It turns collecting skill into server-visible status.

Canon anchors:

* Weekly competition rules: [The Global Museum (Social Leaderboard)](../../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)
* Prestige currency rules: [Currency Systems](../../4-the-mmo-and-economy-macro/currency-systems.md)
* Item value breakdown rules: [The "Mint & Condition" System](../../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)
* Permanent sink expansion: [Museum Endowments (Permanent Prestige)](../../../expansion-plan/macro-loop-expansion/4.-museum-endowments-permanent-prestige.md)

### What “prestige” means here

Prestige is not raw power.

Prestige is:

* rank,\n in weekly Museum seasons,
* HI,\n an untradeable prestige currency,
* permits and status,\n access to elite content.

### The weekly loop (player view)

This is the default weekly beat:

1. See the new theme in Archive.
2. Hunt items that match it.
3. Decide what to lock for the week.
4. Submit up to `10` items.
5. Items become Museum-locked.
6. Season ends.\n Rewards distribute.\n Locks clear.

Canon: [The Global Museum (Social Leaderboard)](../../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)

### Museum lock (the key mechanic)

Museum submissions are a hard choice.

Submitted items become `MUSEUM_LOCKED` for the whole week.

While locked, they cannot be:

* sold or listed,
* smelted,
* leased,
* endowed.

Canon: [The Global Museum (Social Leaderboard)](../../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)

### Scoring (what makes a good exhibit)

Score is server-calculated and explainable.

The base unit is item Total HV.

HV must show breakdown lines:

* Base HV (rarity)
* Condition multiplier
* Low-mint multiplier (`#001–#010`)
* Prismatic multiplier (if any)
* Explicit skill bonuses (if shipped)

Canon:

* [The "Mint & Condition" System](../../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)
* [The Global Museum (Social Leaderboard)](../../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)

### Historical Influence (HI)

HI is the prestige reward currency.

Hard rules:

* HI cannot be bought.
* HI cannot be traded.
* HI sinks must feel permanent and identity-driven.

Canon: [Currency Systems](../../4-the-mmo-and-economy-macro/currency-systems.md)

### What HI buys (the “unbuyables”)

The Influence Shop should focus on:

* zone permits,\n access and identity,
* status tiers,\n social ranks,
* permanent Vault expansions,\n long-horizon goals,
* elite training unlocks,\n if you gate `90–99`.

Canon references:

* Museum and HI role: [The Global Museum (Social Leaderboard)](../../4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)
* Currency rules: [Currency Systems](../../4-the-mmo-and-economy-macro/currency-systems.md)

### Endowments (permanent prestige sink)

Endowments are a separate lane from weekly Museum play.

They permanently burn items into a Hall of Fame.

Canon: [Museum Endowments (Permanent Prestige)](../../../expansion-plan/macro-loop-expansion/4.-museum-endowments-permanent-prestige.md)

### Broadcast rules (keep the feed clean)

Prestige should create rare, high-signal moments.

Recommended broadcasts:

* Museum season start.\n Theme announcement.
* Museum season end.\n Top tier winners.
* Any Top `1%` placement.

Feed tone reference:

* [The Dig Site (Main Screen)](../../2-the-mechanics/the-dig-site-main-screen.md)

### Telemetry (for tuning)

Track:

* Weekly participation rate.
* Average submitted items per participant.
* Score curve.\n Detect runaway metas.
* HI minted vs spent per week.
* Lock friction signals.\n “I regret locking” feedback.
* Market impact on theme tags.\n Price spikes and shortages.
