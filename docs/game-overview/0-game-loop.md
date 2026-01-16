# 0 - Game Loop

## Relic Vault: Part 0 — Game Loop (Micro / Meso / Macro)

The loop is a single routine that passes through the five UI “Decks.” Each deck exists to answer one player question.

### 0.1 The Core Routine (Deck Flow)

1. **\[01] THE FIELD**: Click **\[EXTRACT]** to generate Scrap, Crates, or Anomalies.
2. **\[02] THE LAB**: Refine Crates. Choose **\[CLAIM]** or **\[SIFT]** at each stage.
3. **\[03] THE VAULT**: Keep, set-lock, smelt, or prep listings.
4. **\[04] THE BAZAAR**: Trade items and materials for Scrap and Vault Credits.
5. **\[05] ARCHIVE**: Compete in the weekly Museum theme for Influence and rewards.

This matches the navigation flow in [6 - UI/UX Wireframe & Flow](6-ui-ux-wireframe-and-flow.md).

***

### 0.2 Micro Loop (Seconds/Minutes): Extract → Refine → Reveal

#### Step A — Extraction (THE FIELD)

* Input: Manual clicks on **\[EXTRACT]**, plus passive auto-dig ticks.
* Output: Mostly **Scrap**, sometimes an **Encapsulated Crate**, rarely an **Anomaly**.
* UI: Progress bar fill, tray slot update, and global feed ping.
* Optional active layer (Seismic Surge): A timing “Sweet Spot” can appear on the progress bar. Hitting it grants a **Perfect Survey** (+5% flat Crate drop rate for that action) and bonus Excavation XP.
* Zone strategy layer (Vault Heatmaps): Each zone has a visible **Static Intensity**. High static grants +2% Crate drop rate, but applies a -5% Sift Stability penalty to items found there.

Detailed mechanics live in [2: The Mechanics](2-the-mechanics.md).

#### Step B — Refining (THE LAB)

Refining is the risk engine. The player chooses when to stop.

| **Stage** | **Action Name** | **Rarity Potential** | **Stability (Success %)** |
| --------- | --------------- | -------------------- | ------------------------- |
| 0         | Raw Open        | Common (95%)         | 100% (Guaranteed)         |
| 1         | Surface Brush   | Uncommon (30%)       | 90%                       |
| 2         | Chemical Wash   | Rare (25%)           | 75%                       |
| 3         | Sonic Vibration | Epic (15%)           | 50%                       |
| 4         | Molecular Scan  | Mythic (10%)         | 25%                       |
| 5         | Quantum Reveal  | Unique (1%)          | 10%                       |

* On success: Reveal the relic with **Rarity**, **Condition**, **Mint #**, and **Historical Value**.
* On fail: Item **Shatters**. Pay out **Fine Dust** or trigger cooldown states.

**Optional active layers (Micro expansions)**

* Active Stabilization: Spend Fine Dust to “Tether” the Stability needle briefly.
* Pre-Sift Appraisal: Before Stage 0, pay Scrap to preview Mint Probability / Condition Range. Appraisal 60+ can reveal one hidden sub-stat.
* Shatter Salvage: On Standard Fail, a 1-second reaction window can improve failure payout (extra Fine Dust, or recover a rolled Cursed Fragment).
* Anomaly Overload: Anomalies fill a 3-segment meter. Triggering it grants a 60s buff (faster extraction, slightly better Stage 0 outcomes).

Loot metadata rules live in [3 - The Loot & Collection Schema](3-the-loot-and-collection-schema.md).

#### Step C — The “Reveal” Payoff

* The reveal is the dopamine beat.
* The UI must over-communicate outcome via glow, sound, and glitch.
* The button language must stay consistent:
  * **\[EXTRACT]** = safe, frequent.
  * **\[SIFT]** = risky, escalating.

***

### 0.3 Meso Loop (Hours/Days): Power Growth via Tools, Skills, and Sets

This loop converts short-term wins into long-term efficiency.

#### Progression: Scrap → Workshop → Better Output

* **Scrap** is the primary progression currency.
* Scrap buys Tool Tiers and efficiency upgrades in the Workshop.
* Better tools increase Scrap/hour and Crate find rates.
* Overclocking becomes the “soft prestige” lever later.

#### RPG Skilling: Permanent Advantage

Actions pay XP into four skills. This ensures “veteran power” persists beyond gear.

* Excavation: Better extraction outcomes.
* Restoration: Better sifting stability.
* Appraisal: Better trading information and fees.
* Smelting: Better Scrap conversion.

Advanced layer (align with [Skills Expansion](../expansion-plan/skills-expansion.md)):

* Level `60` unlocks (per skill):
  * 1 active ability (a “press moment”).
  * 1 sub-specialization branch pick (build choice).
* Level `80/80` pair unlocks:
  * Always-on cross-skill masteries (synergy perks).\n Example: **Certified Restorer** (Restoration+Appraisal) and **Efficiency Engine** (Excavation+Smelting).
* All skills `90+`:
  * Total mastery: **Senior Researcher** (Archive intel + identity).
* Optional endgame prestige:
  * “Archive Rebirth” (reset for ribbons + small permanent account perks).

Skill definitions live in [5 - RPG Skilling System](5-rpg-skilling-system.md).

#### Collection: Sets as Long-Term Goals

* Items belong to Sets.
* Completing a Set locks it into the Vault.
* The reward is a passive buff (Scrap gain, Stability, Bazaar fees).

***

### 0.4 Macro Loop (Weeks/Months): Economy + Competition + Social Proof

The macro loop makes finds matter to other players. It also creates recurring reasons to return.

#### THE BAZAAR (Player Economy)

* List items with a Scrap deposit to reduce spam.
* Use Appraisal to certify listings and surface hidden value.
* Apply an “Archive tax” as a money sink.
* Expansion lanes:
  * Counter-Bazaar (0% tax, confiscation risk).
  * Artifact Leasing (temporary loans).

Full economy details live in [4 - The MMO & Economy (Macro)](4-the-mmo-and-economy-macro.md).

#### ARCHIVE (Weekly Museum Event)

* Weekly theme request.
* Players donate items for a Museum Score.
* Rewards pay out **Historical Influence** and rare keys/crates.
* Macro expansions:
  * Influence tiers (HI → permanent status perks).
  * Syndicate permits (pool HI for temporary team zone access).
  * Endowments (permanent item burn + Hall of Fame).
  * Expeditions (contracts / requisitions).

#### World Events and New Zones

Events should be implemented as time-boxed modifiers to existing systems. Examples:

* Temporary zone unlocks (unique loot table).
* Stability bonuses (more people gambling in the Lab).
* Bazaar fee reductions (more liquidity during events).

Keep these aligned with total-level gates and zone unlock rules.

Static-driven macro volatility is defined in ["The Great Static" Events (incl. Static Pulses)](../expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md).

***

### 0.5 Implementation Notes (UI-First)

* The UI is the world.
* Every loop step needs a visible state change.
* Every risk action needs escalating audiovisual feedback.
