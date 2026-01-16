# The "Mint & Condition" System

## The "Mint & Condition" System

Mint and Condition are the two identity layers that make duplicates matter.

They turn “same catalog item” into a unique object with prestige and pricing weight.

This system is server-authoritative.

### What this system controls

It controls:

* **Mint number** (global serial per `item_catalog_id`).
* **Condition** (quality tier with a fixed HV multiplier).
* The **HV breakdown lines** shown in Vault, Bazaar, and Museum.

It does not control:

* Lab stage tables.
* Lab success odds.
* Any extraction odds.

Those are defined in [2: The Mechanics](../2-the-mechanics.md).

### Data model (minimum)

Every owned relic needs, at minimum:

* `item_catalog_id` (the static “what is this” ID)
* `mint_number` (integer, `>= 1`)
* `condition` (enum)
* `rarity_tier` (enum)
* `is_prismatic` (boolean, optional)
* `hidden_stats` (JSON, optional; Appraisal gated)
* lock state fields (escrow / museum / set-lock / lease / endowed)

The “display string” is derived, not stored:

* `"<Item Name> #<mint_number>"`

### Mint number (global serial)

#### Rules

* Mint numbers are **unique per item catalog ID**.
  * There is exactly one `Ceramic Mug #001` globally.
* Mint numbers are assigned **once**.
* Mint numbers never change after assignment.
  * Not after trades, leases, museum submissions, or set-locking.

#### When mint is assigned

Mint is assigned at **item creation**, which happens on a successful reveal / claim outcome.

The client never assigns mint numbers.

#### Atomic assignment (hard requirement)

Mint assignment must be atomic and server-owned.

Two simultaneous drops must never receive the same mint.

This is a Phase 3 “server authority” cornerstone.

See [Phase 3 requirements](/broken/pages/GcPUD3swAP8KbhaBt30Q).

#### Low-mint prestige multiplier (canon)

* Mint numbers `#001–#010` apply a `+50%` HV multiplier.
  * That’s `1.5×`.

If HV is not shipped yet, show this as a **Low Mint** badge.

### Condition (quality tier)

Condition is the quality state of the recovered object.

It is rolled once on item creation.

It is immutable in the current design.

#### Canon condition tiers and multipliers

These constants must stay consistent everywhere (Bazaar display + Museum scoring):

* `wasteland_wrecked` → **Wasteland Wrecked** (`0.5×` HV)
* `weathered` → **Weathered** (`1.0×` HV)
* `preserved` → **Preserved** (`1.5×` HV)
* `mint_condition` → **Mint Condition** (`2.5×` HV)

Source of truth: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md).

### Historical Value (HV) breakdown and stacking rules

HV must stay readable.

Every modifier must show as an explicit line item.

No hidden multipliers.

#### Recommended player-facing breakdown

Show these lines in this order:

1. Base HV (from rarity tier)
2. Condition multiplier
3. Mint multiplier (only if `#001–#010`)
4. Prismatic multiplier (if applicable)
5. Skill-based HV bonuses (explicit lines)
6. Contextual multipliers (Museum-only set bonus, event multipliers, etc.)

#### “Once per item” guardrail

If a perk is “once per item”, enforce it server-side.

Never let it stack repeatedly via re-certification or re-processing.

### Integration points (how other systems use Mint + Condition)

#### Lab (Reveal moment)

Mint and Condition are part of the “reveal stamp” beat.

They are never previewed for free at low levels.

Lab loop details live in [2: The Mechanics](../2-the-mechanics.md).

#### Appraisal (bounded information, never RNG changes)

Appraisal interacts with this system in two ways:

* **Pre-Sift Appraisal** can reveal:
  * Mint probability band (not certainty)
  * Condition range label (not certainty)
* **Certification** can reveal hidden sub-stats and add explicit HV bonuses.

Full spec: [Appraisal](../5-rpg-skilling-system/appraisal.md).

#### Restoration (stability + explicit HV edge at 99)

Restoration never changes:

* mint assignment
* condition rolls
* stage rarity tables

It can add value as explicit HV lines:

* Restoration 99: claimed items gain `+1%` HV (always-on).

Full spec: [Restoration](../5-rpg-skilling-system/restoration.md).

#### Prismatic (“Shiny”) variants

Prismatic is a separate variant layer.

It stacks on top of mint + condition.

Canon hooks (keep consistent):

* Roll: `1%` chance on any **successful** sift result.
* Value: `3×` base HV (variant multiplier).
* Optional sink: dissolve into Vault Credits.

Full spec: [The "Shiny" Mechanic](the-shiny-mechanic.md).

#### Collections and set multipliers

Collections are account-level buffs.

They do not rewrite mint or condition.

Museum scoring can also apply a **set bonus** when you submit a full themed set.

Set tiering and lock rules: [Sample Collection Tiers](sample-collection-tiers.md).

#### Bazaar pricing and trust surfaces

Bazaar listings should surface:

* Item name + mint
* condition stamp
* prismatic state (if any)
* certification badge (if any)
* HV breakdown (if HV is shown)

Bazaar and tax rules: [4 - The MMO & Economy (Macro)](../4-the-mmo-and-economy-macro.md).

#### Smelting (item sink, not identity rewrite)

Smelting is an inventory cleanup loop.

It must never change mint or condition.

It simply destroys an item and awards Scrap deterministically.

Full spec: [Smelting](../5-rpg-skilling-system/smelting.md).

### Lock state compatibility (so players can’t exploit value)

Mint and Condition never change under locks.

Locks only change what actions are allowed.

Canonical lock states to keep compatible:

* **Escrow** (Bazaar listing): locked, un-smeltable, un-donatable.
* **Museum lock** (weekly submission): locked until the week ends.
* **Set-locked** (completed collection): removed from trade and sinks.
* **Leased**: temporary transfer, untradeable, cannot be dissolved/endowed.
* **Endowed**: burned permanently, never returns.

Ownership-state canonical rules live in:

* Loot schema: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md)
* Leasing: [Artifact Leasing (The Rental Economy)](../../expansion-plan/macro-loop-expansion/3.-artifact-leasing-the-rental-economy.md)
* Endowments: [Museum Endowments (Permanent Prestige)](../../expansion-plan/macro-loop-expansion/4.-museum-endowments-permanent-prestige.md)

### Worked examples

#### Example A — low mint + preserved

Assume:

* Base HV (Rare) = `250`
* Condition = Preserved (`1.5×`)
* Mint = `#004` (low mint, `1.5×`)

Then:

* `HV = 250 × 1.5 × 1.5 = 562.5` → apply a deterministic rounding rule (server-owned).

#### Example B — add prismatic

If the same item is Prismatic (`3×`):

* `HV = 250 × 1.5 × 1.5 × 3 = 1687.5`

Prismatic does not change the mint number.

### Phasing notes (so scope stays clean)

* **Phase 3**: minting and low-mint prestige surfaces.
* **Phase 4**: condition + HV constants + Museum scoring.
* **Phase 5+**: prismatics + dissolve into Vault Credits (if shipped).

See:

* [Phase 3 requirements](/broken/pages/GcPUD3swAP8KbhaBt30Q)
* [Phase 4 requirements](/broken/pages/W0goIsLgTGnXgIRcgKtm)
