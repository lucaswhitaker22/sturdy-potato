# 5 - RPG Skilling System

## Relic Vault: Part 5 — RPG Skilling System

The RPG Skilling system provides the "long-term grind" essential to any OSRS-inspired MMORPG. It ensures that a veteran player with a "Rusty Shovel" is still more effective than a novice with a "Deep Drill." Skill levels are permanent, whereas tools are equipment.

***

### 5.1 Core Skill Directory

Skills are leveled up through Action-Based Experience (XP). Every time a player interacts with the UI in a specific way, they gain a small amount of XP.

| **Skill**   | **Primary XP Source**                | **Level 99 Mastery Benefit**                                                    |
| ----------- | ------------------------------------ | ------------------------------------------------------------------------------- |
| Excavation  | Clicking \[EXTRACT] / Auto-dig ticks | "The Endless Vein": 15% chance for "Double Loot" drops on every find.           |
| Restoration | Successful Sifts (Lab)               | "Master Preserver": +10% Base Stability to all sifting tiers.                   |
| Appraisal   | Buying/Selling in Bazaar             | "The Oracle": Ability to see the "Condition" of an item before opening a crate. |
| Smelting    | Breaking down items into Scrap       | "Pure Yield": 2x Scrap output from all Junk-tier items.                         |

***

### 5.2 The XP Curve & Leveling Logic

To maintain the "Old School" feel, the XP required for each level follows an exponential curve. This ensures that the early levels feel fast, while the jump from Level 98 to 99 represents a massive time investment.

The XP required for a given level ($$ $L$ $$) is calculated as:

\$$XP(L) = \sum\_{n=1}^{L-1} \lfloor n + 300 \cdot 2^{n/7} \rfloor\$$

* Levels 1–30: Rapid progression. Unlocks basic tool tiers and set visibility.
* Levels 31–70: The "Mid-Game" grind. High-efficiency tools require these levels.
* Levels 71–98: Specialized tiers. High-stakes gambling in the Lab becomes viable.
* Level 99: The Cap. Total XP required is approximately 13,034,431.

***

### 5.3 Skill Synergies (Cross-Training)

Skills are designed to feed into one another, encouraging a balanced playstyle.

* The Archaeologist Loop: High Excavation level finds more "Caked Crates." High Restoration is then required to open them without shattering the items.
* The Merchant Loop: Smelting junk provides the Scrap needed to buy items in the Bazaar, which in turn levels up Appraisal.
* The Master Loop: At Level 99 in all four skills, the player unlocks the "Founder’s Seal," a unique UI frame that glows with an animated "Obsidian Dust" effect.

***

### 5.4 The "Master's Badge"

Reaching Level 99 is a global event.

1. Global Announcement: The feed scrolls: _"ARCHIVE ALERT: \[PlayerName] has achieved Level 99 Restoration!"_
2. UI Transformation: The specific skill tab in the player's UI changes from standard Amber to a "Prismatic" or "Gold" theme.
3. The Badge: A permanent icon appears next to the player's name in the Bazaar and Global Museum, signaling their expertise to other players.

***

### 5.5 Level-Gated Content

Certain "Zones" or "Dig Sites" are locked behind total skill levels (Total Level = Sum of all 4 skills).

* The Sunken Mall: Requires Total Level 100.
* The Corporate Archive: Requires Total Level 250.
* The Sovereign Vault: Requires Total Level 380 (Near Max).

***

#### Summary of Skilling Principles

* No "Dead" Actions: Even a failed sift provides a small "Pity XP" amount to Restoration.
* Visual Growth: As skills increase, UI elements (like progress bars) become more ornate.
* Economic Impact: High-level Smelters and Appraisers control the Scrap-to-Credit flow in the Bazaar.
