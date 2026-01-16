# 2: The Mechanics

## Relic Vault: Part 2 — The Mechanics (Micro & Meso)

This document defines the core gameplay loops.

The Micro Loop is Digging and Refining.

The Meso Loop is Workshop upgrades and efficiency scaling.

***

### 2.1 The Dig Site (Main Screen)

The Dig Site, designated as \[01] THE FIELD, serves as the player's primary interface and represents the "Frontier" of the wasteland. It is designed with a high-noise, industrial aesthetic, featuring flickering text and scanlines to simulate a salvaged terminal.

**The Active Dig (Manual)**

This is the core interaction for active play, allowing players to manually scavenge the surface.

* The Action: A large, weathered button labeled \[EXTRACT].
* The Mechanic: Each click triggers a "Survey" progress bar that takes between 0.5s and 2s to fill, depending on the equipped tool's efficiency. In the early stages (Phase 1), this action initiates a 3-second cooldown during which the button is disabled and the "Extraction Gauge" animates.
  * Seismic Surge (optional active layer): During the bar fill, a timing “Sweet Spot” can appear. Clicking on the Sweet Spot grants a **Perfect Survey**.
  * Excavation active ability (60+): **Focused Survey**.\n A paid 60s buff window that adds `+10%` flat Crate chance on **manual** extracts (clamped `≤ 95%`).\n It never changes the 5% Anomaly roll.\n Details: [Active Skill Abilities](../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md).
* The Output:
  * 80% Chance — Surface Scrap: The primary soft currency for workshop upgrades and training.
  * 15% Chance — Encapsulated Crate: Requires refinement in the Lab to reveal potential relics.
  * 5% Chance — Anomaly: Temporary mini-events or global modifiers that appear in the realtime feed.
* Perfect Survey Bonus: +5% flat Crate drop rate for that specific action, plus bonus Excavation XP.
  * Progression: Higher Excavation makes the Sweet Spot larger. Level 99 (“The Endless Vein”) can add a second Sweet Spot.

**The Auto-Digger (Passive)**

Progression past basic manual tools unlocks automated systems, allowing for resource gathering without constant manual input.

* Unlocking: Automated Extraction units become available once the player upgrades beyond the initial Shovel.
* Passive Income: These units generate Scrap and Crates continuously. This extraction continues while the player is offline, though total accumulation is limited by the current "Battery Capacity".
* The Logic: Automation operates on a 10-second "Tick" system. Every tick, the game rolls for a find based on the player’s total Extraction Power. On the UI, this is represented by a secondary passive progress bar that fills automatically.

**Resource Generation (Scrap)**

Scrap is the fundamental currency used for progression, workshop upgrades, and economy participation.

* Scaling: Scrap per hour ($$ $S_{ph}$ $$) increases with higher tool tiers—ranging from the Pneumatic Pick to the Satellite Uplink—and total skill modifiers.
*   The Formula:

    \$$S\_{ph} = (Base\\\_Power \times Multiplier) \times 3600\$$

**Efficiency Modifiers:**

* Excavation Skill: Leveling this skill increases the base crate drop rate by +0.5% every five levels. At Level 99 Mastery ("The Endless Vein"), players gain a 15% chance for double loot drops on every find.
* Tool Tiers: Higher-tier tools like the Industrial Drill or Seismic Array exponentially increase automation output (e.g., the Drill provides 100 Scrap/sec).
* Collection Buffs: Completing sets like "The Morning Ritual" grants passive buffs, such as the "Caffeine Rush," which permanently reduces manual extraction cooldowns.

#### Vault Heatmaps (Zone Strategy)

Zones are not just cosmetics. Each unlocked zone exposes a visible **Static Intensity** heatmap.

* Static tiers (example tuning): LOW / MED / HIGH
  * Crate bonus: `+0% / +1% / +2%` flat while extracting in that zone.
  * Lab penalty (for loot found there): `+0% / -2.5% / -5%` flat Sift Stability.
* Source integrity: Crates should store their source zone + static tier at drop time. The Lab reads that stored metadata.
* Personal Mitigation: Excavation `70+` can **Survey** a zone to temporarily reduce the Static penalty for themselves (recommended gate).
* Information Edge (Appraisal 99): “The Oracle” can see which item catalog IDs are currently “trending” per zone.

***

### 2.2 The Refiner (The Gambling Hub)

The Lab is the high-stakes heart of _Relic Vault_. While the Field provides the raw materials, the Lab determines their ultimate value. In this clinical, subterranean environment, players must decide whether to play it safe or push ancient technology to its breaking point.

**The "Sift" Logic (Risk vs. Reward)**

Refining is a multi-stage gambling process. Every "Encapsulated Crate" starts at Stage 0, and at each stage, the player must choose between \[CLAIM] (safely taking the current reward) or \[SIFT] (risking the item to reach the next rarity tier).

| **Stage** | **Action Name** | **Rarity Potential** | **Stability (Success %)** |
| --------- | --------------- | -------------------- | ------------------------- |
| 0         | Raw Open        | Common (95%)         | 100% (Guaranteed)         |
| 1         | Surface Brush   | Uncommon (30%)       | 90%                       |
| 2         | Chemical Wash   | Rare (25%)           | 75%                       |
| 3         | Sonic Vibration | Epic (15%)           | 50%                       |
| 4         | Molecular Scan  | Mythic (10%)         | 25%                       |
| 5         | Quantum Reveal  | Unique (1%)          | 10%                       |

**Skill Synergy: Restoration**

A player’s effectiveness in the Lab is governed by their Restoration Skill. This skill is leveled by performing sifts, with successes granting full XP and failures providing a "Pity XP" award.

* Stability Bonus: Every Restoration level adds a +0.1% flat bonus to the Stability Gauge, making high-level gambles significantly more viable for veterans.
* Master Preserver: Reaching Level 99 grants a permanent +10% Base Stability to all sifting tiers and makes the Stability needle 10% slower by default.

#### Active Stabilization (Lab Triage)

Sifting is not purely a binary roll. During the Stability needle swing, the player can spend **Fine Dust** to “Tether” the needle briefly.

* This does not raise Stability directly.
* It gives the player more time to **Force Stop** in a safer zone.
* Restoration reduces Fine Dust cost per tether.

**Failure States: The "Shatter" Outcomes**

If a stability check fails, the item Shatters. The severity of the failure and the resulting materials depend on the stage of refinement.

* Standard Fail: The most common outcome. The player receives 5–10 Fine Dust, a material used for low-tier crafting.
* Critical Fail: A catastrophic technical failure. The player receives zero materials, and the Refiner enters a 5-minute cooldown period due to overheating.
* Cursed Fragment: There is a 1% chance upon shattering a high-tier item (Stage 3+) to recover a Cursed Fragment. These are rare components later used to craft "Stabilizer Charms" that can force a successful sift.

#### Shatter Salvage (The Reaction Beat)

When a sift fails and the “System Error” glitch fires, a 1-second reaction window opens.

* Triggers on **Standard Fail** only. It does not trigger on Critical Fail / overheat.
* If the player clicks **\[SALVAGE]** in time:
  * Stage 1–2 shatters: Double Fine Dust payout.
  * Stage 3+ shatters:
    * Roll the Cursed Fragment chance as normal.
    * If a fragment was rolled, salvage success recovers it.
    * If salvage is missed, the fragment is lost in the break.
* This is designed to make failure interactive without removing risk.

#### Emergency Glue (Restoration 60+ reaction)

Emergency Glue is a rare “save” button that fires in the same 1-second failure beat.

* Trigger: **Standard Fail** only.\n Never on Critical Fail / overheat.\n Never on Stage 0.
* Cost: consumes `1` Cursed Fragment.
* Effect: converts the failure into a forced **\[CLAIM]** at the **current stage**.\n It never converts a fail into a success.
* Interaction rule: one failure beat = one reaction choice.\n If both buttons exist, the first pressed wins (the other disables).

Details: [Active Skill Abilities](../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md).

#### Pre-Sift Appraisal (Crate Prep)

Before the first sift (Stage 0), the player can pay a Scrap fee to **\[APPRAISE]** the crate.

* On success: Reveal **Mint Probability** or a **Condition Range** preview (e.g., “80% Preserved+”).
* Appraisal 60+: Also reveals one hidden sub-stat that will apply if the item is successfully claimed.

#### Anomaly Overload (The Combo Meter)

Anomalies fill an **Overload Meter** (3 segments) in the header UI.

* At 3 segments, the player can trigger **Overload** manually.
* Overload lasts 60 seconds:
  * +50% extraction speed.
  * Raw Open: If the result would have been Junk, it has an extra 5% chance to upgrade to Common.
* World Event hook: During “Magnetic Interference,” anomalies fill the meter twice as fast.

**Sensory Payoff: "The Reveal"**

The Lab UI is designed to maximize tension through a "Juice" system.

* Anticipation: When \[SIFT] is clicked, the Stability Gauge needle swings wildly while a low-frequency hum builds in volume.
* Success: A successful sift is signaled by a bright border flash and a crisp mechanical _clink-clink_ sound.
* Shatter: A failure triggers a brief static glitch effect, the sound of breaking glass, and a visual "System Error" notification.
* The Reveal: For high-tier items, the Mint Number (e.g., #001) slams onto the item card with a heavy stamp sound, punctuating the discovery of a rare artifact.

***

### 2.3 The Workshop (Progression)

The Workshop is the primary "Scrap Sink" of _Relic Vault_, where players convert their hard-earned currency into long-term efficiency. Progression is strictly gated by Scrap costs and Skill levels, ensuring a steady, OSRS-inspired grind toward automation.

**Tool Tiers & Stats**

While tools provide a massive boost to resource generation, they are equipment-based upgrades that supplement the player's permanent Skill levels.

| **Tool Name**    | **Type** | **Crate Find Rate** | **Automation (Scrap/sec)** | **Level Req** | **Scrap Cost** |
| ---------------- | -------- | ------------------- | -------------------------- | ------------- | -------------- |
| Rusty Shovel     | Manual   | 5%                  | 0                          | 1             | 0 (Starter)    |
| Pneumatic Pick   | Hybrid   | 8%                  | 5                          | 5             | 2,500          |
| Ground Radar     | Auto     | 12%                 | 25                         | 15            | 15,000         |
| Industrial Drill | Auto     | 18%                 | 100                        | 30            | 80,000         |
| Seismic Array    | Auto     | 25%                 | 500                        | 50            | 500,000        |
| Satellite Uplink | Global   | 40%                 | 2,500                      | 80            | 2,500,000      |

* Manual Tools: Require active clicking on the \[EXTRACT] button to generate resources.
* Hybrid/Auto Tools: Unlock passive extraction, allowing the player to accumulate Scrap and Crates without manual input.
* Global Tools: Provide high-tier efficiency and are required to access deeper, more dangerous "Zones" or "Dig Sites".

**The Upgrade Curve & Automation Logic**

To prevent rapid completion, tool costs follow an exponential growth formula: $$ $Cost = Base\_Cost \times 1.5^{Level}$ $$.

Once an automated tool is purchased, the \[THE FIELD] screen initiates a secondary passive progress bar.

* Tick System: Automation operates on a 10-second tick. Every time the passive bar fills, the player gains Scrap and a chance for a Crate drop based on their current Extraction Power.
* Offline Gains: Passive units continue to work while the player is logged out. Upon returning, the game calculates the time elapsed and awards Scrap, though this is capped by the current "Battery Capacity" of the player's equipment.

**Prestige Mechanic: Overclocking**

Once a tool reaches "Max Efficiency," it can be Overclocked. This serves as a "soft prestige" lever for veteran players.

* The Trade-off: Overclocking resets the tool to Level 1, requiring the player to re-invest Scrap.
* The Reward: The process grants a permanent +5% multiplier to the "Sift" success rate in the Lab, making high-risk refinement significantly safer.

{% hint style="info" %}
Overclocking is tool-based “soft prestige”.\n It is separate from the optional skilling prestige concept (“Archive Rebirth”) in [Skills Expansion](../expansion-plan/skills-expansion.md).
{% endhint %}

**UI Component Summary**

The Workshop UI is designed to feel like a salvaged industrial terminal, emphasizing tactile feedback.

* The "Vitals" Bar: A persistent header showing Scrap balance, Vault Credits, and current Battery/Offline time.
* The Tray: A dedicated area at the bottom of the screen that holds up to 5 unrefined Crates. If the tray is full, manual extraction is disabled to encourage players to move to the Lab.
* The Feed: A scrolling ticker that broadcasts major player events, such as finding a rare relic via a Quantum Reveal. This feed provides social proof and creates psychological pressure to engage in high-risk sifting.
* Tactile Feedback: "Buy" buttons remain dim and greyed out until the player meets both the Scrap cost and the Excavation level requirement. Every purchase is met with a unique, heavy mechanical "click" sound to provide weight to the progression.

***

### 2.4 Macro integrity notes (events + contracts)

This document defines canonical micro/meso odds.\n Macro systems must not rewrite them.

Allowed:\n

* World Events applying explicit, time-boxed modifiers.\n See ["The Great Static" Events (incl. Static Pulses)](../expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md).
* Contracts that change what players pursue.\n They never change base drop tables.\n See [Lore Keeper Requisitions (Archive Expeditions)](../expansion-plan/macro-loop-expansion/6.-lore-keeper-requisitions-archive-expeditions.md).

Never allowed:\n

* Modifying the base 5% Anomaly outcome.\n
* Revealing exact mint math or exact catalog IDs for free.
