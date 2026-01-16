# 4 - The MMO & Economy (Macro)

## Relic Vault: Part 4 — The MMO & Economy (Macro)

The Macro loop is what prevents _Relic Vault_ from being a lonely "clicker" game. By introducing player-to-player trade, competitive display, and a multi-tiered currency system, the game creates a living world where your "finds" have value to others.

***

### 4.1 The Bazaar (Auction House)

The Bazaar serves as the central hub of the player-driven economy, functioning as a high-speed, text-centric interface where archaeologists trade artifacts and raw materials. It transforms the game from a solo experience into a living market where digital scarcity directly dictates value.

**Listing & Escrow Mechanics**

Players can list items from their Permanent Vault to be sold to the highest bidder.

* Listing Requirements: Creating a listing requires exactly one owned inventory item, a set reserve price (minimum bid), and a duration—defaulting to 24 hours for Phase 3.
* Listing Spam Prevention: A small Scrap deposit is required to list an item, acting as a deterrent against "listing spam" and ensuring the market remains high-quality.
* Escrow System: Once an item is listed, it is placed in escrow; the seller cannot use, smelt, or assign the item to the Museum until the auction resolves or is cancelled.

**Bidding & Settlement Logic**

The Bazaar utilizes a "held currency" model to ensure transaction integrity.

* Bidding Holds: When a player places a bid, the required Scrap is instantly "held" by the Archive and cannot be spent elsewhere.
* Outbid Behavior: If a player is outbid, their held Scrap is immediately returned to their account, accompanied by a notification: _"You have been outbid on \[Item Name]!"_.
* Settlement: At the end of the auction duration, the highest bidder receives the item, and the seller receives the Scrap payout minus the Archive Tax.

**The Global Ticker & Activity Feed**

The Bazaar is integrated into the game's "heartbeat" via real-time social proof.

* Live Ticker: A scrolling feed at the top of the Bazaar screen broadcasts new high-value listings (e.g., _"NEWS: User\_Alpha just listed \[Old World Smartphone #004] - Bidding starts at 50,000 Scrap!"_).
* Global Broadcasts: Significant sales are broadcast globally to all players, creating a "gold rush" effect and encouraging active market participation.

**Appraisal & Certification (Skill Synergies)**

The Appraisal skill is essential for players looking to specialize as merchants.

* Level 60 (Certified Listings + Previews): Advanced Appraisers can certify items for a Scrap fee, adding a permanent "Certified" badge to the item. Certification reveals hidden sub-stats and can surface Appraisal previews like "Mint Probability."
* Level 99 (Master Trader): Reaching mastery in Appraisal unlocks the "Auctioneer" title and provides the ultimate economic benefit: reducing the Archive Tax from 5% down to 2.5%.
  * Oracle edge: Appraisal mastery can also expose which item catalog IDs are currently “trending” per zone (pairs with Vault Heatmaps).

**The Archive Tax & Economic Stability**

To prevent runaway inflation, the game utilizes a "money sink" strategy.

* 5% Flat Fee: A standard Archive Tax is deducted from the final sale price of every successful auction.
* Rounding and Integrity: Tax calculations are performed server-side using deterministic rounding rules to maintain economic consistency.

**UI/UX Design: The "Oasis" Aesthetic**

The Bazaar is categorized as an "Oasis" screen, designed to feel like the safety of an underground bunker.

* Visual Language: Unlike the high-noise "Wasteland" screens, the Bazaar features clean text, search filters, and stable UI elements.
* Mobile Scaling: On mobile devices, the Bazaar includes large, thumb-accessible buttons and a condensed single-line Global Feed at the top of the screen.

***

### 4.2 The Global Museum (Social Leaderboard)

The Global Museum is the ultimate "Prestige" system and a rotating, community-driven competitive event. Every week, the Archive announces a specific cultural theme (e.g., _Pre-Collapse Cleaning Supplies_ or _Ancient Entertainment Tech_), challenging players to prove they have the most significant collection in the wasteland.

**Submission and Locking Mechanics**

Players participate by "donating" their best items to the weekly exhibit to earn a Museum Score.

* Assignment: Players can assign up to 10 items from their Vault to the current week's exhibition.
* The Lock: Once assigned, an item is locked until the week ends. Locked items cannot be sold or listed in the Bazaar, emphasizing the choice between immediate profit and long-term social prestige.
* Theme Visibility: When a new Museum week starts, the theme is broadcast globally via the activity feed, and the Museum screen displays the theme alongside the remaining time.

**The Museum Score (MS) Calculation**

Scores are calculated server-side based on the historical significance and condition of the submitted items. The formula is as follows:

\$$MS = \sum (HV \times C) \times S\_{bonus}\$$

* HV (Historical Value): The base value determined by the item's rarity tier.
* C (Condition Multiplier): A multiplier based on the item's state (e.g., Mint condition provides a 2.5x multiplier).
* $$ $S_{bonus}$ $$ (Set Multiplier): A significant bonus awarded if the player submits a full themed set (e.g., 1.5x).
* Mint Multiplier: Low-digit serial numbers (#1 through #10) provide a massive additional multiplier to the final score.

**Competitive Tiers and Rewards**

At the end of each week, the leaderboard is finalized and rewards are distributed based on a player's percentile ranking.

* Top 1% (Grand Curator): Awards a Unique UI Badge, 500 Historical Influence, and a "Master Relic Key".
* Top 10% (Senior Researcher): Awards 200 Historical Influence and 3 "Encapsulated Crates".
* Participation: All participants receive a base reward of 50 Historical Influence.

**Historical Influence (HI): The Third Currency**

The primary reward for Museum participation is Historical Influence, a non-tradable social currency used to unlock "The Unbuyables".

* Influence Shop: HI can be spent in a specialized shop for high-level unlocks, including Zone Permits for new dig sites, elite skill training (levels 90–99), custom username titles for the global feed, and massive Vault expansions.
* Social Proof: High-ranking curators display their "Master's Badges" in the Museum and Bazaar, signaling their expertise and status to the rest of the community.

***

### 4.3 Currency Systems

_Relic Vault_ utilizes a "Tri-Currency" model designed to balance core progression, social prestige, and long-term sustainability. This system ensures that different player archetypes—scavengers, merchants, and curators—each have a specific economic lever to pull while preventing runaway inflation.

| **Currency**         | **Type**       | **Primary Source**                | **Primary Use**                               |
| -------------------- | -------------- | --------------------------------- | --------------------------------------------- |
| Scrap                | Soft           | Digging, Smelting Junk            | Tool Upgrades, Skill Training, Bazaar Bidding |
| Vault Credits        | Hard/Premium   | Real-Money, Dissolving Prismatics | Top-Tier Relics, UI Skins, Charms             |
| Historical Influence | Social (Fixed) | Museum Participation, Quests      | Unlocking Zones, High-Level Skills            |

**1. Scrap: The Lifeblood of the Workshop**

Scrap is the primary progression currency used for the majority of in-game transactions. It represents the raw material value of the wasteland.

* Generation: Players earn Scrap through manual extraction, passive auto-digging, and smelting unwanted junk items.
* Economic Sink: To maintain value, Scrap is removed from the economy through "Archive Taxes" in the Bazaar (5% fee), tool upgrade costs in the Workshop, and fees for certifying items.
* Skill Synergy: High-level Smelters control the Scrap-to-Credit flow by maximizing the yield from junk-tier items.

**2. Vault Credits: The Scarcity Lever**

Vault Credits serve as the premium currency, facilitating high-end trading and personalization.

* Acquisition: Credits are primarily obtained through real-money purchases or by "Dissolving" ultra-rare Prismatic Relics, linking premium value directly to gameplay luck.
* Utility: Beyond cosmetic UI skins and "OS" themes, Credits are used to purchase Stabilizer Charms (which reduce shatter risk) and additional Vault inventory tabs.
* Market Role: Credits allow for the acquisition of the most prestigious relics in the Bazaar without requiring massive hoards of Scrap.

**3. Historical Influence (HI): The Curator’s Weight**

Historical Influence is a non-tradable, social currency that measures a player’s standing within the Archive. It cannot be bought or traded, ensuring that certain endgame content remains gated by merit and participation.

* Earning HI: HI is earned exclusively through participation in the Weekly Museum exhibitions and contributing to 48–72 hour World Events.
* The Influence Shop: HI is spent on "The Unbuyables," including permits for high-level dig sites (e.g., _The Sunken Data Center_), elite skill training to push from level 90 to 99, and unique username titles for the Global Feed.
* Prestige: Accumulating HI is the only way to unlock "Master's Badges" and unique UI frames that signal a player's veteran status to the community.

**Economic Balance and Interplay**

The three currencies are designed to feed into one another to create a stable macro-loop. Smelting junk provides the Scrap needed to buy items in the Bazaar, which increases Appraisal levels, eventually leading to the discovery of Prismatics that can be converted into Vault Credits. Meanwhile, donating those same items to the Museum generates the Historical Influence required to access new zones where higher-tier Scrap and Crates are found.

#### 4.4 OSRS-Inspired Skilling Integration

To drive the player-driven economy, certain skills are required to interact with Macro systems effectively. This creates "Specializations" where players may become masters at finding items but rely on others to sell or certify them, ensuring that the economy remains a collaborative ecosystem. While tools represent temporary equipment, skill levels are permanent advantages that ensure "veteran power" persists beyond gear progression.

**The Macro-Skill Synergies**

The interaction between RPG skilling and the global economy is defined by three primary specialization paths:

* Appraisal (The Merchant Skill):
  * Level 1–30: Provides the ability to see basic Historical Value.
  * Level 60: Unlocks "Certified" listings in the Bazaar, revealing "Mint Probability" and hidden sub-stats on relics to potential buyers.
  * Level 99: The "Master Trader" rank reduces Bazaar listing fees to 2.5% and unlocks the "Auctioneer" title for use in the Global Feed.
* Restoration (The High-Roller Skill):
  * This skill directly influences the Museum Score by providing a passive +1% bonus to the Historical Value of any item successfully claimed from a sift.
  * Higher levels are essential for high-stakes gambling in the Lab, as they provide permanent stability bonuses that mitigate the risk of shattering high-tier artifacts.
* Excavation (The Gatherer Skill):
  * High-level Excavators serve as the primary "suppliers" for the Bazaar.
  * At Level 99, they gain the ability to find "Unidentified Blueprints," which can be sold to other players to unlock advanced Workshop upgrades.

**Economic Skill Loops (Cross-Training)**

Skills are designed to feed into one another, encouraging a balanced playstyle or deep cooperation between specialized players:

* The Archaeologist Loop: High Excavation levels find "Caked Crates," which require high Restoration levels to open without shattering.
* The Merchant Loop: Smelting junk items provides the Scrap needed to bid on items in the Bazaar, which in turn levels up the Appraisal skill through trading volume.
* The Master Loop: Players reaching Level 99 in all four skills unlock the "Founder’s Seal," a unique UI frame featuring an animated "Obsidian Dust" effect.

**Level-Gated Content & Social Proof**

As players increase their Total Level (the sum of all four skills), they unlock new layers of the world and economy:

* Zone Permits: Specific high-level dig sites, such as _The Sunken Mall_ (Total Level 100) or _The Sovereign Vault_ (Total Level 380), are gated by skill progress.
* The "Master's Badge": Reaching Level 99 in any skill triggers a Global Announcement in the feed: _"ARCHIVE ALERT: \[PlayerName] has achieved Level 99 Restoration!"_.
* UI Transformation: Mastery results in a permanent icon next to the player's name in the Bazaar and Global Museum, signaling their status as an elite specialist to the community.
