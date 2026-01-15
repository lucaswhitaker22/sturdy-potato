# 2: The Mechanics

## Relic Vault: Part 2 — The Mechanics (Micro & Meso)

This document defines the core gameplay loops.

The Micro Loop is Digging and Refining.

The Meso Loop is Workshop upgrades and efficiency scaling.

***

### 2.1 The Dig Site (Main Screen)

The Dig Site is the player’s primary interface. It represents the "Frontier."

#### The Active Dig (Manual)

* The Action: A large, weathered button labeled \[EXTRACT].
* The Mechanic: Each click triggers a "Survey." A progress bar fills (0.5s to 2s based on tool).
* The Output:
  * 80% chance: Surface Scrap (currency).
  * 15% chance: Encapsulated Crate (requires Refining).
  * 5% chance: Anomaly (temporary mini-event or bonus).

#### The Auto-Digger (Passive)

Once the player upgrades past the Shovel, they unlock Automated Extraction units.

* Passive Income: These units generate Scrap and Crates even while the player is offline (capped by "Battery Capacity").
* The Logic: Automation runs on a "Tick" system. Every 10 seconds, the game rolls for a find based on the player’s Extraction Power.

#### Resource Generation (Scrap)

Scrap is the lifeblood of the workshop.

* Scrap per hour ($$S_{ph}$$) scales with tool tier.
* It also scales with efficiency modifiers.
* The formula:

$$
S_{ph} = (Base\_Power \times Multiplier) \times 3600
$$

***

### 2.2 The Refiner (The Gambling Hub)

When a player finds a Crate, they must bring it here. Opening a raw crate almost always yields "Common" junk. To get "Relics," they must Refine.

#### The "Sift" Logic (Risk vs. Reward)

Refining is a multi-stage process. At each stage, the player chooses to \[Claim] or \[Sift].

| **Stage** | **Action Name** | **Rarity Potential** | **Stability (Success %)** |
| --------- | --------------- | -------------------- | ------------------------- |
| 0         | Raw Open        | Common (95%)         | 100% (Guaranteed)         |
| 1         | Surface Brush   | Uncommon (30%)       | 90%                       |
| 2         | Chemical Wash   | Rare (25%)           | 75%                       |
| 3         | Sonic Vibration | Epic (15%)           | 50%                       |
| 4         | Molecular Scan  | Mythic (10%)         | 25%                       |
| 5         | Quantum Reveal  | Unique (1%)          | 10%                       |

#### Failure States

If the Stability check fails, the item Shatters.

1. Standard Fail: Player receives 5–10 "Fine Dust" (Used for low-tier crafting).
2. Critical Fail: The Refiner overheats. Player receives nothing and the Refiner goes on a 5-minute cooldown.
3. Cursed Fragment: A 1% chance upon shattering a high-tier item (Stage 3+). These fragments are used later in the Macro loop to "Force" a success.

***

### 2.3 The Workshop (Progression)

The Workshop is where Scrap is converted into Tool Tiers. Progression is gated by Scrap costs that scale exponentially.

#### Tool Tiers & Stats

| **Tool Name**    | **Type** | **Crate Find Rate** | **Automation (Scrap/sec)** | **Scrap Cost** |
| ---------------- | -------- | ------------------- | -------------------------- | -------------- |
| Rusty Shovel     | Manual   | 5%                  | 0                          | 0 (Starter)    |
| Pneumatic Pick   | Hybrid   | 8%                  | 5                          | 2,500          |
| Ground Radar     | Auto     | 12%                 | 25                         | 15,000         |
| Industrial Drill | Auto     | 18%                 | 100                        | 80,000         |
| Seismic Array    | Auto     | 25%                 | 500                        | 500,000        |
| Satellite Uplink | Global   | 40%                 | 2,500                      | 2,500,000      |

#### The Upgrade Curve

To prevent players from reaching the end too quickly, the cost follows a growth formula:

$$
Cost = Base\_Cost \times 1.5^{Level}
$$

* Prestige Mechanic: Once a tool reaches "Max Efficiency," the player can Overclock it. This resets the tool to Level 1 but adds a permanent $$ $+5\%$ $$ multiplier to the "Sift" Success rate.

***

#### UI Component Summary

* The "Vitals" Bar: Always visible. Shows Scrap, Vault Credits, and current Battery (Offline time).
* The Tray: A small UI area at the bottom showing up to 5 unrefined Crates.
* The Feed: A scrolling text log: _"Player\_99 found \[Antique Spoon #902] via Quantum Reveal!"_ (Creates social pressure to gamble).
