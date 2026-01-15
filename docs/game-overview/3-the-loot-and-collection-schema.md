# 3 - The Loot & Collection Schema

## Relic Vault: Part 3 — Loot, Identity, and Collections

Loot is the long-term retention layer.

It must support scarcity, storytelling, and trading.

### 3.0 Core item fields (conceptual)

Every item should be able to carry:

* Name
* Rarity tier
* Historical Value (HV)
* Condition
* Mint number
* Optional set membership
* Optional prismatic state
* A short Archive research note

### 3.1 Rarity Hierarchy

Every item dropped from a Crate is assigned a Rarity Tier. This determines its base "Historical Value" (HV) and its visual flair in the UI.

| **Tier** | **UI Color** | **Base HV** | **Description**                                      |
| -------- | ------------ | ----------- | ---------------------------------------------------- |
| Junk     | Grey         | 1-5         | Broken glass, rusted wire, plastic scraps.           |
| Common   | White        | 20          | Everyday items (Spoons, Pens, Bolts).                |
| Uncommon | Green        | 75          | Branded goods (Soda cans, basic tools).              |
| Rare     | Blue         | 250         | Complex tech (Phones, Calculators, Watches).         |
| Epic     | Purple       | 1,000       | Cultural touchstones (Game consoles, Designer bags). |
| Mythic   | Orange       | 5,000+      | Masterpieces (Prototypes, High-end jewelry).         |
| Unique   | Red/Glow     | ???         | One-of-a-kind items with global announcements.       |

***

### 3.2 The "Mint & Condition" System

To ensure no two items are truly identical, every relic generated uses a Unique Serial ID.

1. The Mint Number: When an item is found, it is assigned a number (e.g., _Walkman #001_).
   * The Prestige: Low-mint numbers (#1 through #10) grant a +50% bonus to Historical Value and are highly coveted in the Auction House.
2. Condition Modifier: Items are found in varying states of decay.
   * Wasteland Wrecked: 0.5x HV
   * Weathered: 1.0x HV
   * Preserved: 1.5x HV
   * Mint Condition: 2.5x HV (Extremely rare).

***

### 3.3 Sample Collection Sets

Players don't just hoard; they curate. Completing a "Set" locks the items into the player's Permanent Vault, removing them from the economy but granting a Passive Buff.

#### Set A: "The 20th Century Kitchen"

_Focus: Beginner set, easy to find._

* Items: Rusty Toaster, Ceramic Mug, Silicone Spatula, Manual Can Opener.
* Completion Bonus: +10% Scrap gain from manual digging.

#### Set B: "The Digital Dark Age"

_Focus: Mid-game tech pursuit._

* Items: CRT Monitor, Mechanical Keyboard, Floppy Disk (3.5"), Wired Mouse.
* Completion Bonus: +5% Sift Stability (Reduces break chance).

#### Set C: "The High Society Gala"

_Focus: Late-game luxury._

* Items: Diamond Tennis Bracelet, Silk Necktie, Gold-Plated Lighter, Designer Perfume Bottle.
* Completion Bonus: -15% Auction House listing fees.

***

### 3.4 Flavor Text & World Building

Since there are no graphics, the Description must do the heavy lifting. Every item includes a "Vault Research Note" which misinterprets the item's original purpose.

* Item: _Plastic Fidget Spinner_
  * Description: "A sophisticated inertial dampening device. Ancient texts suggest these were used by high-ranking scholars to focus their minds during the Great Distraction."
* Item: _USB Flash Drive (2GB)_
  * Description: "A 'Knowledge Crystal.' Though the data within is corrupted by the Static, the physical vessel remains a symbol of lost omniscience."
* Item: _Paper Coffee Cup (Starbucks)_
  * Description: "A sacrificial vessel from the 'Siren Cult.' Thousands of these have been found, suggesting a global ritual involving brown, caffeinated liquids."

***

### 3.5 The "Shiny" Mechanic (Prismatic Relics)

There is a 1% chance that any successful "Sift" results in a Prismatic version of the item.

* Visual: The UI border pulses with a rainbow gradient.
* Effect: Prismatic items provide 3x the Historical Value and can be "Dissolved" into Vault Credits (Premium Currency).
