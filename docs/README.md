# Game Overview

## Relic Vault: Official Game Overview

A UI-Based Post-Apocalyptic Archaeology MMORPG

***

### Executive Summary

Relic Vault is a persistent, UI-centric MMORPG where players take on the role of specialized Archaeologists in a world buried by "The Great Static." Unlike traditional RPGs focused on combat, _Relic Vault_ centers on discovery, digital scarcity, and high-stakes gambling. Players excavate "Crates" from the wasteland, use risky refining processes to unveil ancient artifacts (Relics), and trade them in a player-driven global economy.

***

### 1. The Core Loop: From Dust to Glory

The gameplay is structured into three distinct layers that feed into one another:

#### The Micro Loop: Extract & Sift

Players interact with the Field to dig up raw Scrap and Encapsulated Crates. These crates are taken to the Lab, where players engage in a multi-stage gambling mini-game called Sifting. Each stage increases the item's rarity but also the risk of it "Shattering" into worthless dust.

#### The Meso Loop: Skilling & Automation

Through OSRS-inspired skilling, players level up Excavation, Restoration, Appraisal, and Smelting. Higher levels unlock more efficient tools (Auto-diggers) and increase the statistical odds of successful refinement.

#### The Macro Loop: The Global Economy

Every successful relic find is assigned a Global Mint Number (e.g., _Walkman #001_). These items are unique, tradable assets. Players list items in the Bazaar (Auction House) or donate them to the Global Museum to earn prestige and "Historical Influence."

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
