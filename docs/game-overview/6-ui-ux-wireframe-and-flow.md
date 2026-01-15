# 6 - UI/UX Wireframe & Flow

## Relic Vault: Part 6 — UI/UX Wireframe & Flow

In a game without 3D environments, the User Interface IS the world. The UI must feel heavy, tactile, and responsive. This section outlines the navigation structure, the visual language for interactions, and the sensory feedback loops that drive engagement.

***

### 6.1 The Global Screen Map

The game is organized into five primary "Decks" (Tabs). Navigation is handled via a persistent Command Bar at the bottom of the screen.

| **Deck**         | **Function**     | **Key UI Elements**                                   |
| ---------------- | ---------------- | ----------------------------------------------------- |
| \[01] THE FIELD  | Primary Gameplay | Large \[EXTRACT] button, Heatmap, Tool Status.        |
| \[02] THE LAB    | RNG / Gambling   | Sifting tray, Stability gauge, Chemical Wash buttons. |
| \[03] THE VAULT  | Inventory / RPG  | Grid view, Set completion trackers, Skill level bars. |
| \[04] THE BAZAAR | MMO Economy      | Live auction ticker, Search filters, Listing slots.   |
| \[05] ARCHIVE    | Social / Macro   | Museum leaderboard, Global quests, Influence shop.    |

#### The Flow: "The Scavenger's Routine"

1. Field: Player clicks \[EXTRACT] $$ $\to$ $$ Progress bar fills $$ $\to$ $$ Crate drops into "Pending" slot.
2. Lab: Player clicks a Crate $$ $\to$ $$ Opens Refiner UI $$ $\to$ $$ Performs "Sifts" (RNG) $$ $\to$ $$ Item revealed.
3. Vault: Player views item $$ $\to$ $$ Decides: Equip to Museum, Sell in Bazaar, or Smelt for Scrap.

***

### 6.2 Interaction Palette & Visual Language

To help the player navigate "information-dense" screens, we use a strict color and behavior language.

#### Button States

* Action (Green/Amber): High-frequency buttons like \[EXTRACT] or \[CLAIM]. They pulse slightly when ready.
* Risk (Deep Red): The \[SIFT] button. As the risk increases, the red glow intensifies and the button begins to "vibrate" (CSS shake).
* Disabled (Dim Grey): Buttons on cooldown or unaffordable upgrades.

#### The "Oasis" vs. "Wasteland" Aesthetic

* Wasteland Screens (Field/Lab): High "visual noise," flickering text, scanlines, and darker backgrounds to simulate the harsh surface.
* Oasis Screens (Vault/Archive): Cleaner text, stable UI, and slightly warmer colors to simulate the safety of the underground bunkers.

***

### 6.3 Feedback Loops (The "Juice")

Because there are no combat animations, we use Micro-Animations to make actions feel impactful.

#### The RNG "Roll" (Sifting)

* Anticipation: When the player clicks \[SIFT], the "Stability Gauge" needle swings wildly. A low-frequency hum builds in volume.
* The reveal:
  * Success: Bright border flash and a crisp mechanical _clink-clink_.
  * Shatter: Brief static glitch, glass-break, and a Dust icon.

#### The "OSRS" Level Up

* When a skill (e.g., Excavation) levels up, a banner slides down from the top: "LEVEL 40 EXCAVATION REACHED."
* The icons for that skill briefly glow, and a "Skill Point" notification appears next to the Workshop tab.

***

### 6.4 OSRS-Inspired Skill Hub (Wireframe Concept)

The \[THE VAULT] screen contains the "Skill Dashboard."

* Left Pane: List of skills (Excavation, Restoration, Appraisal, Smelting).
  * Each has a circular progress bar showing % to next level.
  * Clicking a skill expands a "Milestones" list (e.g., _Level 50: Unlock Deep-Sea Crates_).
* Right Pane: The "Relic Set" list.
  * Greyed-out silhouettes of missing items.
  * Hovering over a silhouette shows where it's found (e.g., _"Found in: Rusty Suburbs"_).

***

### 6.5 Mobile vs. Desktop Scaling

* Mobile: Buttons are large and thumb-accessible at the bottom. The "Global Feed" is a single line at the very top.
* Desktop: The "Global Feed" moves to a sidebar on the right. Inventory and The Lab can be viewed side-by-side.

***

#### Summary of UI Principles

> "Every click must have a sound. Every success must have a glow. Every failure must have a glitch."
