# The "Shiny" Mechanic

## The "Shiny" Mechanic (Prismatic Relics)

Prismatic relics are the chase layer.

They stack on top of rarity, mint, and condition.

They exist to create rare “world moment” finds and premium sinks.

### Rules (canon)

#### When it rolls

Prismatic is a secondary roll on the Lab outcome.

Rule:

* `1%` chance on any **successful** sift outcome.

It is not rolled on failures.

It is not found “directly” in the Field.

Lab loop context: [2: The Mechanics](../2-the-mechanics.md).

#### What it can apply to

Any catalog item can be prismatic.

That includes common trash and mythic masterpieces.

#### Value impact (canon)

* Prismatic applies a `3×` HV multiplier.

This is additive to the normal identity stack:

* rarity → base HV
* condition multiplier
* low-mint multiplier (if `#001–#010`)
* prismatic multiplier (`3×`)

HV breakdown rules live in [The "Mint & Condition" System](the-mint-and-condition-system.md).

### Visual language (required for “juice”)

Prismatic must be unmistakable.

Minimum UI beats:

* Persistent animated prismatic border on item cards.
* A prismatic color-burst during the Lab reveal.
* A distinct badge/tag: `PRISMATIC`.

Polish expectations: [Phase 5 requirements](../../implementation-plan/phase-5-v1-polish/phase-5-requirements.md).

### Social proof (global feed)

Every prismatic find should broadcast globally.

Example string:

* `"<Player> just unearthed [Prismatic] <Item Name> #<Mint>!"`

Feed rules live in [Phase 3 requirements](../../implementation-plan/phase-3-the-connected-world-the-mmo-layer/phase-3-requirements.md).

### The “Dissolve” sink (Vault Credits)

Prismatics can optionally be destroyed for premium currency.

Rule:

* Dissolve destroys the item permanently.
* It awards Vault Credits (payout is tuning).

Guardrails:

* You can’t dissolve if the item is locked (escrow, leased, museum, set-locked).
* Show a burn warning and exact payout before confirming.

Premium currency context: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md).

### Lock states (compatibility)

Prismatic state never changes under locks.

Locks only block actions.

Prismatic items must respect:

* Bazaar escrow
* museum lock
* set-lock
* lease
* endowment

Canonical lock rules: [Sample Collection Tiers](sample-collection-tiers.md).

### Phasing notes

Prismatics are typically Phase 5+ content.

They are called out as out-of-scope in Phase 4 requirements.

See:

* [Phase 4 requirements](../../implementation-plan/phase-4-the-high-curator-meta-game/phase-4-requirements.md)
* [Phase 5 requirements](../../implementation-plan/phase-5-v1-polish/phase-5-requirements.md)
