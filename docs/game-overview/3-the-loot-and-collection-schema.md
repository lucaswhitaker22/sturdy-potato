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
* Optional hidden sub-stats (revealed via Appraisal)
* Optional set membership
* Optional prismatic state
* A short Archive research note

#### 3.0.1 Preview fields (Appraisal-only)

Some UI-only “preview” values can be shown before the reveal.

* Mint Probability (estimate): A player-facing hint, not a guarantee.
* Condition Range (estimate): E.g., “80% chance Preserved+.”

These previews should never change server RNG. They only surface information.

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

To ensure no two items are truly identical, every relic generated uses a Unique Serial ID. This system introduces digital scarcity and social prestige, making the hunt for "low-digit" artifacts a core driver of the global economy.

**The Mint Number**

When an item is successfully refined and found, it is assigned a Global Serial Number (e.g., _Walkman #001_).

* Global Uniqueness: Every artifact generated is assigned a number that is unique to its specific item catalog ID; for example, there is only ever one "Ceramic Mug #001" in the entire game world.
* Atomic Assignment: Mint numbers are assigned server-side at the moment of item creation, ensuring that two simultaneous discoveries never receive the same serial number.
* The Prestige: Low-mint numbers (#1 through #10) are highly coveted and receive a massive +50% multiplier to their Historical Value (HV).
* Social Status: Players often prioritize acquiring low-digit common items over high-numbered rare items due to the prestige associated with early discoveries.

**Condition Modifier**

Items are recovered in varying states of decay, which significantly alters their worth.

* Wasteland Wrecked (0.5x HV): Heavily damaged or non-functional items.
* Weathered (1.0x HV): The standard state for most recovered artifacts.
* Preserved (1.5x HV): Items found with minimal damage.
* Mint Condition (2.5x HV): Extremely rare finds that appear as though they never left their original packaging.

**Economic and Competitive Impact**

The combination of Mint and Condition defines an item’s total value in both the Bazaar and the Archive.

* Bazaar Valuation: The serial number system creates a "Buy Low, Sell High" meta-game where low-digit mints act as a hedge against inflation.
* Museum Scoring: Weekly leaderboard scores are calculated by summing an item's Base HV, its Condition Multiplier, and any applicable Set Multipliers.
* Skill Synergies:
  * Appraisal: Enables Pre-Sift Appraisal previews (Mint Probability / Condition Range) and can reveal hidden sub-stats that further influence value.
  * Restoration: Advanced restoration skills grant a passive +1% bonus to the Historical Value of any item successfully claimed from a sift.

***

### 3.3 Sample Collection Sets

The Collection system transforms random item acquisition into strategic, long-term goals. By completing specific "Sets," players can lock items into their Permanent Vault, which removes them from the active economy but grants powerful, permanent passive modifiers to the player's account.

**The "Check" and Completion Logic**

When a player successfully refines an item and adds it to their Vault, the game automatically executes a set completion check.

* Automation: The system verifies if the new item completes any known collections.
* Visual Feedback: Once a set is finalized, the collection UI transitions to a "Gold Glow" state.
* The Reward: Completion results in a permanent passive buff, accompanied by a toast notification for the player.
* UI Representation: Within the \[COLLECTIONS] tab of the Vault, missing items are displayed as silhouettes to encourage further scavenging.

**Sample Collection Tiers**

Sets are categorized by their themes and the specialized benefits they provide to various gameplay loops.

Set A: "The 20th Century Kitchen" (Beginner Tier)

* Focus: Early-game resource generation.
* Required Items: Rusty Toaster, Ceramic Mug, Silicone Spatula, and Manual Can Opener.
* Completion Bonus: +10% Scrap gain from all manual digging actions.

Set B: "The Morning Ritual" (Core Progression)

* Required Items: Ceramic Mug, Rusty Toaster, and Spoon.
* Reward (Caffeine Rush): Permanently reduces the \[EXTRACT] cooldown by 0.5 seconds.

Set C: "The Digital Dark Age" (Mid-Game Pursuit)

* Focus: High-stakes refining stability.
* Required Items: CRT Monitor, Mechanical Keyboard, Floppy Disk (3.5"), and Wired Mouse.
* Completion Bonus: +5% Sift Stability, reducing the chance of an item shattering during refinement.

Set D: "The High Delivery Gala" (Late-Game Luxury)

* Focus: Economic efficiency in the player-driven market.
* Required Items: Diamond Tennis Bracelet, Silk Necktie, Gold-Plated Lighter, and Designer Perfume Bottle.
* Completion Bonus: -15% Auction House listing fees in the Bazaar.

**Macro Integration: The Global Museum**

Beyond individual account buffs, collection sets play a critical role in the Phase 4 meta-game.

* Museum Scoring: Submitting a full themed set to the Global Museum provides a significant multiplier to a player's weekly exhibition score.
* Competitive Advantage: Curating complete sets is the primary method for climbing the Museum leaderboard and earning Historical Influence (HI).

***

### 3.4 Flavor Text & World Building

#### 3.4 Flavor Text & World Building

In a UI-centric world without traditional graphics, the Description and Flavor Text perform the heavy lifting of immersion. Every item in the game includes a "Vault Research Note"—a diegetic piece of text written from the perspective of a bureaucratic, slightly clueless researcher from "The Archive".

**Writing Principles for "Vault Research Notes"**

To maintain consistency across the hundreds of relics in the wasteland, all flavor text must adhere to these Archive standards:

* Confident Misinterpretation: The researcher should describe the item’s function with absolute certainty, while being completely wrong about its original 20th-century purpose.
* The "One Joke" Rule: Each description should center on a single, dryly humorous observation about the "Ancient World".
* Avoid Modern Slang: Descriptions must sound clinical, bureaucratic, and detached to reflect the tone of the Archive.
* Brief and Punchy: Item notes should ideally be one to two sentences long.

**Categories of Interpretation**

The Archive typically categorizes relics based on how "The Great Static" has altered their perceived function:

* Ritualistic Objects: Everyday items interpreted as religious or cult artifacts.
  * _Item: Paper Coffee Cup (Starbucks)_: "A sacrificial vessel from the 'Siren Cult.' Thousands have been found, suggesting a global ritual involving brown, caffeinated liquids."
* Primitive Tech: Advanced electronics viewed as mysterious, inert artifacts.
  * _Item: USB Flash Drive (2GB)_: "A 'Knowledge Crystal.' Though the data within is corrupted, the physical vessel remains a symbol of lost omniscience."
* Social Signifiers: Mundane accessories viewed as high-status markers.
  * _Item: Plastic Fidget Spinner_: "A sophisticated inertial dampening device. Ancient texts suggest these were used by high-ranking scholars to focus their minds during the Great Distraction."

**Expanded Relic Examples**

* Standard Fork: "A three-pronged 'food-spear' used by the warrior-class of the Great Dining Era to hunt domestic proteins."
* AA Battery: "A dead ancient power cell; survivors believe these were once 'captured lightning' used to fuel the small gods of the household."
* Remote Control: "A long-range button-array used to communicate with the 'Glowing Boxes.' Most buttons appear to have been pressed in a frantic, repetitive ritual known as 'Channel Surfing.'"
* Soda Tab: "A small aluminum currency of unknown denomination. Often found in massive hoards, suggesting a primitive banking system based on beverage consumption."

**Impact on the Macro Loop**

Flavor text is not merely cosmetic; it enhances the value of items in the Bazaar and Global Museum.

* The Museum Theme: Weekly themes (e.g., "The Age of Plastic") require players to match relics based on these misinterpreted categories to earn high scores and Historical Influence.
* Social Proof: When a rare item is found, its flavor text is broadcast in the Global Activity Feed, cementing its "identity" in the community.

***

### 3.5 The "Shiny" Mechanic (Prismatic Relics)

While rarity tiers and mint numbers provide consistent progression, Prismatic Relics introduce a rare "chase" element to the looting experience. This mechanic is designed to reward high-risk gambling with a visually distinct and economically powerful variant of any existing artifact.

**The Prismatic Roll**

A Prismatic version of an item is not found directly; it is a secondary outcome of the refinement process.

* Success Rate: There is a fixed 1% chance that any successful "Sift" action in the Lab will result in a Prismatic variant.
* Universal Availability: Any item from the catalog—from common household debris like the "AA Battery" to mythic-tier masterpieces—has a chance to trigger this state upon a successful reveal.

**Visual Flair and "Juice"**

As a core part of the game's sensory design, Prismatic items are immediately recognizable through distinct UI behaviors.

* The Border: The UI border of a Prismatic relic pulses with a persistent, shifting rainbow gradient.
* The Reveal: During the "Lab Reveal," the standard flash effect is replaced with a prismatic color-burst, signaling a high-tier discovery to the player.
* Social Proof: Every Prismatic find is broadcast globally via the Activity Feed, creating a shared social "gold rush" effect: _"User\_Scavenger just unearthed a \[Prismatic] Old World Smartphone #004!"_.

**Gameplay and Economic Benefits**

Prismatic Relics serve as the ultimate value-multipliers for both the player's personal collection and their standing in the global economy.

* Historical Value (HV): A Prismatic variant provides 3x the base Historical Value of the standard version, making them essential for high-ranking positions in the Weekly Museum leaderboards.
* The "Dissolve" Mechanic: Unique to this tier, players have the option to "Dissolve" a Prismatic item. This process destroys the artifact but converts it into Vault Credits, the game’s premium currency used for high-end trading, cosmetic UI skins, and Stabilizer Charms.

**Market Impact**

In the Bazaar, Prismatic Relics represent the pinnacle of digital scarcity.

* Bidding Wars: Due to their triple HV and premium conversion potential, Prismatics often command the highest bids in Scrap or Vault Credits.
* The Collector’s Ultimate Flex: Because the Prismatic state is independent of the Mint Number, finding a Prismatic #001 is considered the rarest achievement in _Relic Vault_, granting the owner significant prestige and Historical Influence.
