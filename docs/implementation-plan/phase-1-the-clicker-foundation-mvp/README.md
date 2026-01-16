# Phase 1: The "Clicker" Foundation (MVP)

## Phase 1: The "Clicker" Foundation (MVP)

The MVP ships the Micro Loop:

Field → Lab → Vault.

Terms and core odds align to [2: The Mechanics](../../game-overview/2-the-mechanics/).

Build contract: [Phase 1 (MVP) requirements](phase-1-mvp-requirements.md).

### 1. The Core Logic (The "Brain")

In this phase, the game tracks three simple data points for the player. Even without a complex database, the game must "remember" these states:

* Currency Ledger: Your current total of Scrap.
* Crate Tray: A storage area that holds up to 5 Encapsulated Crates.
* The Vault: A list of items you have successfully refined and "claimed."

> MVP Rule: If the Crate Tray is full (5/5), the \[EXTRACT] button is disabled. This forces the player to move from the Field to the Lab.

***

### 2. The Dig: \[EXTRACT] Mechanics

This is the primary interaction on the main screen.

* The Action: Clicking the button runs a short "Survey" progress bar.
* MVP Timing: fixed 3 seconds per extract (tools can vary this later).
* The RNG (Mechanics-aligned):
  * 80% — Scrap gain
  * 15% — Encapsulated Crate
  * 5% — Anomaly (Phase 1: log-only, no gameplay effect)

***

### 3. The Refiner: Stage-based Sift Logic

Once a player has a crate, they enter the Lab. This is the gambling mini-game.

#### The Stages of Refinement

Every crate starts at Stage 0.

At each stage, the player chooses:

* `[CLAIM]` (take the reward now), or
* `[SIFT]` (risk the crate to reach the next stage).

| **Stage** | **Action Name** | **Success Rate** | **Reward Tier**       |
| --------- | --------------- | ---------------- | --------------------- |
| 0         | Raw Open        | 100%             | 100% Junk             |
| 1         | Surface Brush   | 90%              | 80% Junk / 20% Common |
| 2         | Chemical Wash   | 75%              | 60% Common / 40% Rare |
| 3         | Sonic Vibration | 50%              | 90% Rare / 10% Epic   |
| 4         | Molecular Scan  | 25%              | 100% Epic             |
| 5         | Quantum Reveal  | 10%              | 100% Epic             |

MVP note: Epic labels exist, but Epic draws from the Rare pool.

The Failure State: If the "Shatter" roll occurs, the item is destroyed. The player receives 3 Scrap (pity reward) and a "System Error" sound effect.

***

### 4. The Item System: The "Starter 20"

For the MVP, we use 20 items divided into two tiers. These provide the flavor for the world-building.

#### Common Tier (12 Items)

_Found at Stage 1-2. Mostly household debris._

1. Dull Kitchen Knife: "A primitive steak-searing blade."
2. Ceramic Mug: "A vessel for brown caffeinated rituals."
3. AA Battery: "A dead ancient power cell."
4. Plastic Comb: "A scalp-scraping tool of the old elite."
5. Steel Fork: "A three-pronged food-spear."
6. Lightbulb: "A fragile glass orb that once held lightning."
7. Ballpoint Pen: "A manual data-entry stylus (no ink)."
8. Rusty Key: "Unlocks a door that no longer exists."
9. Eyeglass Frame: "A visual-enhancement harness."
10. Soda Tab: "Small aluminum currency? Purpose unknown."
11. Safety Pin: "A primitive emergency garment fastener."
12. Rubber Band: "High-elasticity synthetic binding."

#### Rare Tier (8 Items)

Found at Stage 3-4. Functional tech fragments.

13\. Calculated Tablet: "A solar-powered math-engine (Casio)."

14\. Wrist Chronometer: "Tracks time via ticking gears."

15\. Compact Disc: "A shimmering circle of lost music."

16\. Remote Control: "A long-range button-array for glowing boxes."

17\. Computer Mouse: "A handheld navigation 'rodent'."

18\. Flashlight: "A portable photon-emitter."

19\. Headphone Set: "Private ear-drums for personal audio."

20\. Digital Camera: "A device that freezes light into memories."

***

### 5. MVP UI Layout

The UI should be a single-page application with three distinct areas:

* The Header: Shows Scrap Count and Vault Size (e.g., 5/20 Items Found).
* The Workspace (Center):
  * _Field Mode:_ Big \[EXTRACT] button and the progress bar.
  * _Lab Mode:_ Shows the current Crate and the \[SIFT] vs \[CLAIM] buttons.
* The Sidebar/Footer: A scrolling "Log" of your actions (_"You found a Rusty Key!"_) and a simple list of your Vault items.

***

### 6. Phase 1 Success Metrics

You know Phase 1 is complete when:

1. A player can click to earn Scrap.
2. A crate randomly drops and appears in the inventory.
3. The player can successfully sift that crate to Stage 3 and get a "Rare" item.
4. The item is saved to the "Vault" list.

***

### Related

* [Phase 1 (MVP) requirements](phase-1-mvp-requirements.md)
