# Game Overview

## Relic Vault: Official Game Overview

A UI-Based Post-Apocalyptic Archaeology MMORPG

***

### Executive Summary

Relic Vault is a persistent, UI-centric MMORPG where players take on the role of specialized Archaeologists in a world buried by "The Great Static." Unlike traditional RPGs focused on combat, _Relic Vault_ centers on discovery, digital scarcity, and high-stakes gambling. Players excavate "Crates" from the wasteland, use risky refining processes to unveil ancient artifacts (Relics), and trade them in a player-driven global economy.

***

### 1. The Core Loop: From Dust to Glory

The core mechanics and gameplay features of Relic Vault are structured into three distinct layers that govern the player's progression from a lone scavenger to a prestigious curator.

#### Core Gameplay Loops

* Micro Loop (Seconds/Minutes): Players manually or passively Extract raw Scrap and Encapsulated Crates from the Field, then move to the Lab to Refine crates through multiple high-stakes gambling stages to Reveal ancient relics.
* Meso Loop (Hours/Days): Players convert Scrap into Workshop tool upgrades and earn XP to level up RPG Skills, while completing Collection Sets in the Vault to unlock permanent account-wide buffs.
* Macro Loop (Weeks/Months): Players engage in the global economy via the Bazaar for trading and compete in the Global Museum for Historical Influence and social prestige.

#### Micro Loop Mechanics: The Field & The Lab

* Manual Extraction: Players click the \[EXTRACT] button to trigger a survey progress bar (0.5s–2s) to find Scrap (80%), Crates (15%), or Anomalies (5%).
  * Active extraction add-on (Seismic Surge): A timing “Sweet Spot” can appear on the bar. Hitting it grants a **Perfect Survey** (+5% flat Crate drop rate for that action) and bonus Excavation XP.
* Passive Extraction: Automated tools (Auto-Diggers) generate Scrap and Crates every 10-second "Tick," even while the player is offline, up to a "Battery Capacity" limit.
* The Refiner (Sifting): A multi-stage gambling process (Stages 0–5) where players choose between \[CLAIM] (safely taking the current item) or \[SIFT] (risking the item to reach higher rarity tiers).
* Stability Gauge: Each sifting stage has a success percentage (from 100% at Stage 0 to 10% at Stage 5) that can be improved by the Restoration skill.
  * Active lab add-on (Active Stabilization): Players can spend Fine Dust to “Tether” the needle, slowing it briefly.
* Shatter State: If a stability check fails, the item is destroyed, awarding the player "Fine Dust" or "Pity XP" instead of a relic.
  * Reactive fail add-on (Shatter Salvage): On Standard Fail, a 1-second reaction window can improve failure payout (extra Fine Dust, or recover a rolled Cursed Fragment).
* Micro “Fever Mode” (Anomaly Overload): Anomalies fill a 3-segment meter. Triggering it grants a 60s buff (faster extraction, slightly better Stage 0 outcomes).
* Pre-Sift Appraisal: Before Stage 0, players can pay Scrap to preview a crate (Mint Probability / Condition Range). Higher Appraisal can reveal one hidden sub-stat.
* Zone Strategy (Vault Heatmaps): Zones show “Static Intensity.” Higher static grants up to +2% Crate drop rate, but applies up to -5% Sift Stability for items found there.

#### Meso Loop Mechanics: Progression & Skilling

* RPG Skilling System: Action-based XP is earned for four core skills:
  * [Excavation](game-overview/5-rpg-skilling-system/excavation.md): Improves crate drop rates and unlocks high-tier tool blueprints.
  * [Restoration](game-overview/5-rpg-skilling-system/restoration.md): Increases sifting stability and grants Historical Value (HV) bonuses to claimed items.
  * [Appraisal](game-overview/5-rpg-skilling-system/appraisal.md): Enables Pre-Sift Appraisal previews, reveals hidden item stats, unlocks certifications, and reduces market fees.
  * [Smelting](game-overview/5-rpg-skilling-system/smelting.md): Increases Scrap yield from junk and facilitates bulk processing.
  * Full system overview: [5 - RPG Skilling System](game-overview/5-rpg-skilling-system/)
* Advanced skilling (60+): Each skill gains a “press moment” and a build choice.
  * Active abilities (unlocked at level `60`): Focused Survey, Emergency Glue, Hype Train, Overclock Furnace.
  * Sub-specializations (chosen at level `60`): one branch per skill (respec later).
  * Details: [Skills Expansion](expansion-plan/skills-expansion.md).
* Cross-skill masteries (late-game): Always-on synergy perks.
  * Pair masteries unlock at `80/80` (e.g., **Certified Restorer**, **Efficiency Engine**).
  * Total mastery unlocks at all skills `90+` (e.g., **Senior Researcher**).
* Workshop Tool Tiers: Progression through equipment tiers—from the Rusty Shovel to the Satellite Uplink—which exponentially increases Scrap/sec and crate find rates.
* Collection Sets: Grouping specific items (e.g., "The Morning Ritual") to lock them into the Vault in exchange for permanent modifiers like reduced extraction cooldowns.
* Prestige (endgame): Optional “Archive Rebirth” loop for players who hit 99s.\n It trades levels for permanent identity perks (ribbons) and small global modifiers.\n See [Skills Expansion](expansion-plan/skills-expansion.md).

#### Macro Loop Mechanics: The MMO Economy

* The Bazaar: A player-driven auction house featuring real-time bidding, listing deposits to prevent spam, and a 5% "Archive Tax" on successful sales.
  * Macro expansion: **Counter-Bazaar**, a 0% tax lane with confiscation risk.\n Details in [The "Counter-Bazaar" (Black Market Trading)](expansion-plan/macro-loop-expansion/1.-the-counter-bazaar-black-market-trading.md).
  * Macro expansion: **Artifact Leasing**, temporary item loans for set completion.\n Details in [Artifact Leasing (The Rental Economy)](expansion-plan/macro-loop-expansion/3.-artifact-leasing-the-rental-economy.md).
* Global Museum: A weekly competitive event where players curate themed collections to earn a Museum Score and Historical Influence.
  * Macro expansion: **Museum Endowments**, permanent item burns into a Hall of Fame.\n Details in [Museum Endowments (Permanent Prestige)](expansion-plan/macro-loop-expansion/4.-museum-endowments-permanent-prestige.md).
* World Events: Global modifiers (48–72 hours) that introduce event-only loot and shared community goals, such as mining a set amount of Scrap together.
  * Macro expansion: **The Great Static** event system, including macro-economic “Static Pulses”.\n Details in ["The Great Static" Events (incl. Static Pulses)](expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md).
* Level-Gated Zones: Access to deep-wasteland areas like the Sovereign Vault is restricted by both Total Level requirements and Historical Influence "Zone Permits."
  * Macro expansion: **Syndicate Permits**.\n Teams pool HI for temporary shared access.\n Details in [Influence-Gated Social Tiers (and Syndicate Excavations)](expansion-plan/macro-loop-expansion/2.-influence-gated-social-tiers-and-syndicate-excavations.md).

#### Macro “quest” layer (directed goals)

The Archive can also issue contracts that ask for specific evidence.\n This creates long-term targets and item sinks.\n Details in [Lore Keeper Requisitions (Archive Expeditions)](expansion-plan/macro-loop-expansion/6.-lore-keeper-requisitions-archive-expeditions.md).

#### Loot & Scarcity Systems

* Rarity Hierarchy: Items are tiered from Junk (Grey) to Unique (Red/Glow), determining their base Historical Value.
* Minting System: Every artifact is assigned a globally unique Mint Number (Serial ID); low-digit mints (#1–10) receive a +50% multiplier to their value.
* Condition Modifiers: Items are recovered in states ranging from Wasteland Wrecked (0.5x value) to Mint Condition (2.5x value).
* Prismatic Relics: Rare variants (1% sift chance) that pulse with a rainbow gradient and can be "Dissolved" into premium currency.

#### Tri-Currency Model

* Scrap: The primary soft currency earned by digging and smelting; used for tool upgrades and Bazaar bidding.
* Vault Credits: Premium currency for high-end trading, cosmetic UI skins, and Stabilizer Charms.
* Historical Influence (HI): Non-tradable currency earned through the Museum to unlock "The Unbuyables," such as elite skill training and zone permits.

***

### 2. Key Gameplay Pillars

| **Pillar**       | **Description**                                                                                                        |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Tactile UI       | A "Brutalist" aesthetic where every button click feels mechanical and heavy, mimicking a salvaged wasteland terminal.  |
| Digital Scarcity | The Minting system ensures that early finds are more valuable, creating a permanent "Gold Rush" for new item releases. |
| Server-Side RNG  | All gambling and drops are calculated on the server to ensure a fair, cheat-proof economy for all players.             |
| Community Soul   | A real-time Global Feed broadcasts every major win and catastrophic shatter, creating a shared social experience.      |

***

### 3. World & Narrative

The world is a silent, dusty expanse. Modern technology is gone, and the "Ancient World" (our current era) is a mystery.

* The Archives: The last bastion of humanity, living in underground bunkers.
* The Artifacts: Mundane objects from our time—fidget spinners, remote controls, soda tabs—are treated as sacred "Blueprints of the Past."
* The Goal: Increase your Historical Value (HV) to climb the ranks of the Archive and unlock deeper, more dangerous dig sites.

***

### 4. Systems Overview

#### RPG Skilling (OSRS Inspired)

* Excavation: Faster digging and better crate drop rates.
* Restoration: Higher stability (success chance) during sifting.
* Appraisal: Revealing hidden item stats and reducing market fees.
* Smelting: Maximizing scrap yield from junk.

#### The Bazaar (Marketplace)

A real-time auction house where the economy is 100% player-driven. Scrap is the soft currency used for bidding, while Vault Credits serve as the premium currency for high-end trading and cosmetics.

#### The Global Museum

A weekly leaderboard competition where players curate themed collections. High-ranking Curators earn Historical Influence, used to unlock endgame content and "Master's Badges."

***

### 5. Technical Stack

* Frontend: Vue 3 (Reactive UI, Pinia State Management).
* Backend: Supabase (PostgreSQL, Edge Functions, Auth).
* Real-time: Supabase Realtime (WebSockets for Global Feed and Market updates).
* Platform: Web-based (Desktop & Mobile Browser).

***

### 6. Development Roadmap Summary

* Phase 1: Core "Clicker" MVP (Digging & Sifting logic).
* Phase 2: Progression & Automation (Skills and Workshop).
* Phase 3: The Connected World (Bazaar, Global Feed, Minting).
* Phase 4: The Meta-Game (Museum, Advanced Skills, World Events).
* Phase 5: Polish & Launch (Audio, CSS "Juice," and Monetization).
