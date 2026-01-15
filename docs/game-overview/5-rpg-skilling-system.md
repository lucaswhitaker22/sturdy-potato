# 5 - RPG Skilling System

## Relic Vault: Part 5 — RPG Skilling System

The RPG Skilling system provides the "long-term grind" essential to any OSRS-inspired MMORPG. It ensures that a veteran player with a "Rusty Shovel" is still more effective than a novice with a "Deep Drill." Skill levels are permanent, whereas tools are equipment.

***

### 5.1 Core Skill Directory

Skills are leveled up through Action-Based Experience (XP). Every time a player interacts with the UI in a specific way, they gain a small amount of XP. This "Action-Based" progression ensures that player expertise is permanent, persisting even when tools are upgraded or replaced.

| **Skill**   | **Primary XP Source**                | **Level 99 Mastery Benefit**                                                                                                       |
| ----------- | ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| Excavation  | Clicking \[EXTRACT] / Auto-dig ticks | "The Endless Vein": 15% chance for "Double Loot" drops on every find. Also unlocks "Unidentified Blueprints" for selling.          |
| Restoration | Successful Sifts (Lab)               | "Master Preserver": +10% Base Stability to all sifting tiers. Grants a passive +1% bonus to Historical Value on all claimed items. |
| Appraisal   | Buying/Selling in Bazaar             | "The Oracle": Ability to see item "Condition" before opening a crate. "Master Trader": Fees reduced to 2.5%.                       |
| Smelting    | Breaking down items into Scrap       | "Pure Yield": 2x Scrap output from all Junk-tier items.                                                                            |

***

**Detailed Skill Breakdown**

1\. Excavation (The Gatherer)

* XP Mechanics: Granted upon completion of a manual extraction or an automated tick.
* Progression Perks: Every 5 levels increases the Crate Drop Rate by 0.5%.
* Mastery: At Level 99, Excavators become the primary suppliers for the Bazaar by finding unique blueprints required for high-tier Workshop upgrades.

2\. Restoration (The Gambler)

* XP Mechanics: Completion of a Sift attempt awards XP. Success provides 100% XP, while a failure/shatter grants a 25% "Pity XP" award.
* Progression Perks: Every level adds a +0.1% flat bonus to the Stability Gauge (Success Chance).
* Mastery: Beyond the stability capstone, Masters receive a permanent boost to the Historical Value (HV) of every relic they recover, increasing their Museum and Bazaar potential.

3\. Appraisal (The Merchant)

* XP Mechanics: Gained through active participation in the Bazaar's player-driven economy.
* Mid-Game Milestones: At Level 60, players reveal hidden "sub-stats" on relics and gain the ability to certify items for others for a fee.
* Mastery: Unlocks the "Auctioneer" title in the Global Feed and represents the pinnacle of market efficiency with the lowest possible Archive Tax.

4\. Smelting (The Refiner)

* XP Mechanics: Earned by converting unwanted finds or junk into Scrap.
* Mid-Game Milestones: Level 60 unlocks "Bulk Auto-Smelt," allowing players to process entire tiers of junk instantly.
* Mastery: Provides the highest yield of raw materials, including a chance to recover "Cursed Fragments" from shattered high-level items, which are used to craft Stabilizer Charms.

***

### 5.2 The XP Curve & Leveling Logic

To maintain the "Old School" feel essential to a persistent scavenger RPG, the experience required for each level follows a steep exponential curve. This design ensures that early progression feels rapid and rewarding, while reaching the highest echelons of expertise represents a massive, prestigious time investment.

**The Mathematical Formula**

The total XP required for a given level ($L$) is calculated using a cumulative sum that scales power-wise:

\$$XP(L) = \sum\_{n=1}^{L-1} \lfloor n + 300 \cdot 2^{n/7} \rfloor\$$

* Cumulative Total: Reaching the level cap of 99 requires approximately 13,034,431 XP.
* The Halfway Point: In keeping with OSRS-inspired logic, the "halfway point" in terms of raw XP occurs long after the numerical halfway point of Level 50, emphasizing the intensity of the late-game grind.

**Progression Phases**

The leveling journey is divided into four distinct phases, each offering different gameplay focuses and rewards:

* Levels 1–30: The Rapid Ascent
  * Focus: Tutorialization and early dopamine hits.
  * Milestones: Players quickly unlock basic tool tiers (like the Pneumatic Pick) and gain visibility into "Collection Sets" within the Vault.
* Levels 31–70: The Mid-Game Grind
  * Focus: Efficiency and automation.
  * Milestones: High-efficiency tools like the Industrial Drill and Seismic Array become accessible, requiring significant skill gates to operate.
* Levels 71–98: The Specialist Tier
  * Focus: High-stakes gambling and economic dominance.
  * Milestones: Advanced sifting in the Lab becomes statistically viable, and Appraisal levels allow for certifying high-value relics in the Bazaar.
* Level 99: Mastery
  * Focus: Social prestige and ultimate efficiency.
  * Milestones: Achieving Level 99 triggers a global announcement, transforms the skill's UI theme to "Prismatic" or "Gold," and grants a permanent Master's Badge.

**Total Level Gates**

The "Total Level" (the sum of all four primary skills) serves as a secondary progression metric. Certain "Zones" or "Dig Sites" are locked behind these cumulative gates to ensure players maintain a balanced skill set:

* The Sunken Mall: Requires Total Level 100.
* The Corporate Archive: Requires Total Level 250.
* The Sovereign Vault: Requires Total Level 380 (Near Max).

***

### 5.3 Skill Synergies (Cross-Training)

In _Relic Vault_, skills are not isolated silos; they are designed to feed into one another, encouraging a balanced playstyle and rewarding players who diversify their expertise. This cross-training creates specialized "gameplay loops" that maximize efficiency and economic power.

**1. The Archaeologist Loop (Gatherer + Gambler)**

This is the primary engine for high-value relic discovery.

* The Synergy: High-level Excavation increases the frequency of finding rare "Caked Crates" in the wasteland.
* The Payoff: Players then require a high Restoration skill to successfully "Sift" through these complex layers without shattering the artifact inside.
* Efficiency: A master in both skills can consistently pull high-tier loot from the ground and successfully refine it to Mythic or Unique stages.

**2. The Merchant Loop (Refiner + Trader)**

This loop focuses on maximizing wealth and market influence through the Bazaar.

* The Synergy: Smelting down common junk and failed sifts provides the steady stream of Scrap necessary to participate in high-stakes auctions.
* The Payoff: Using that Scrap to buy and sell artifacts in the Bazaar levels up the Appraisal skill.
* Efficiency: High-level Appraisers can identify the true "Condition" and "Mint Probability" of items, allowing them to flip artifacts for a significant profit while paying reduced Archive Taxes.

**3. The Master Loop (The Perfectionist)**

This represents the ultimate endgame pursuit for veteran players.

* Total Level Synergy: Many of the most dangerous and rewarding "Zones," such as the Sovereign Vault, are gated by a player's Total Level (the sum of all four skills).
* The Reward: Reaching Level 99 in all four skills—Excavation, Restoration, Appraisal, and Smelting—unlocks the "Founder’s Seal".
* Visual Prestige: The Founder's Seal is a unique, animated UI frame that glows with an "Obsidian Dust" effect, signaling absolute mastery of the wasteland to all other players in the Global Feed and Museum.

**Summary of Synergetic Principles**

* No "Dead" Actions: Every interaction provides a benefit; for example, even a failed sift that shatters an item provides "Pity XP" to Restoration and raw materials for Smelting.
* Economic Impact: Specialized players, such as High-level Smelters, control the flow of Scrap, which dictates the bidding power of the entire server in the Bazaar.

***

### 5.4 The "Master's Badge"

Reaching Level 99 in a core skill is a rare, global event that signifies absolute dedication to a specific discipline of the wasteland. It transitions the player from a specialist to a recognized authority within the Archive's social hierarchy.

**1. Global Announcement**

The moment a player hits the experience cap, the Global Activity Feed triggers a high-priority broadcast to every active user:

* The Ticker: The feed scrolls a unique alert: _"ARCHIVE ALERT: \[PlayerName] has achieved Level 99 Restoration!"_.
* Social Proof: This broadcast serves as the ultimate social validation, often sparking a "Gold Rush" of players checking the new Master's Vault or Bazaar listings.

**2. UI Transformation**

The player's personal interface undergoes a permanent aesthetic shift to reflect their mastery:

* Theme Shift: The specific skill tab within the \[03] THE VAULT screen changes from the standard utilitarian Amber to a "Prismatic" or "Gold" theme.
* Animated Effects: The progress bar for the mastered skill is replaced by a static, glowing "MAX" indicator, often accompanied by subtle animated "Obsidian Dust" or "Static" particles.

**3. The Badge & Social Signaling**

The Master's Badge is a permanent icon that appears next to the player's name in all social and competitive interfaces:

* Bazaar Presence: In auction listings, the badge signals to buyers that the seller is a high-level specialist (e.g., a Master Appraiser), which can increase trust and bidding volume.
* Museum Standing: The badge is prominently displayed next to entries in the Global Museum leaderboard, distinguishing veteran curators from newcomers.
* The "Founder’s Seal": For those who achieve Level 99 in all four primary skills (Excavation, Restoration, Appraisal, and Smelting), the individual badges merge into the Founder’s Seal—the rarest UI frame in the game, featuring a pulsing prismatic glow.

**4. Mastery Perks**

Beyond the visual prestige, the badge represents the activation of the skill's ultimate mechanical benefit:

* Excavation: "The Endless Vein" (15% chance for double loot).
* Restoration: "Master Preserver" (+10% base stability).
* Appraisal: "The Oracle" (Visibility of item condition before opening).
* Smelting: "Pure Yield" (2x Scrap output from junk).

***

### 5.5 Level-Gated Content

To maintain progression pacing and provide meaningful long-term milestones, access to the wasteland's most lucrative environments is restricted by a player's cumulative expertise. These gates ensure that high-value "Zones" and "Dig Sites" remain prestigious targets for dedicated scavengers who have mastered the core mechanics of the Archive.

**The Total Level Metric**

The primary requirement for unlocking new regions is the player's Total Level, which is calculated as the sum of their levels across all four primary skills: Excavation, Restoration, Appraisal, and Smelting. This metric encourages a balanced playstyle, as players cannot rely on a single discipline to reach the game's deepest secrets.

**Core Zone Gates**

The Archive enforces strict entry requirements for specific high-tier regions:

* The Sunken Mall (Total Level 100): Often the first major goal for emerging archaeologists, this zone contains a higher density of common and uncommon household artifacts.
* The Corporate Archive (Total Level 250): A mid-game milestone that grants access to complex tech fragments, requiring significant restoration expertise to successfully recover.
* The Sovereign Vault (Total Level 380): Reserved for elite scavengers, this near-max zone contains the most concentrated deposits of Mythic and Unique artifacts in the world.

**Zone Permits and Historical Influence**

In addition to raw skill levels, advanced zones often require a physical "Zone Permit" for entry.

* The Influence Shop: Permits must be purchased using Historical Influence (HI), a currency earned exclusively through social participation in the Weekly Museum and World Events.
* Dual-Gating Strategy: This system ensures that players are not only mechanically skilled but are also active contributors to the Archive's global community.

**Purpose of Level-Gating**

* Pacing and Protection: Gating prevents players from encountering high-tier loot tables before they have the workshop tools or restoration stability needed to manage the risk.
* Macro-Loop Objectives: These zones serve as the primary drivers for the "Macro Loop," giving players recurring reasons to engage with the Museum and Bazaar to earn the HI and Scrap necessary for advancement.
* Social Status: Access to restricted zones functions as a visible status symbol, often signaled to the community via Global Activity Feed broadcasts when a player first breaches a new tier.

***

#### Summary of Skilling Principles

* No "Dead" Actions: Even a failed sift provides a small "Pity XP" amount to Restoration.
* Visual Growth: As skills increase, UI elements (like progress bars) become more ornate.
* Economic Impact: High-level Smelters and Appraisers control the Scrap-to-Credit flow in the Bazaar.
