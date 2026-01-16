# Micro Loop Expansion

The following expansions deepen the micro loop—Extract, Refine, Reveal.

They add optional “active play edges”.

They **do not** rewrite the core RNG model in [2: The Mechanics](../../game-overview/2-the-mechanics.md).

#### 1. The "Seismic Surge" (Active Extraction)

To move beyond the static 3-second cooldown in the Field, the "Seismic Surge" introduces a rhythmic interaction during the \[EXTRACT] progress bar.

* The Mechanic: During the extraction window, a "Sweet Spot" appears on the progress bar. Clicking well grants a "Hit" or a "Perfect Survey".
* The Impact:
  * Hit: `+2%` flat Crate drop rate for that action.
  * Perfect Survey: `+5%` flat Crate drop rate for that action.
  * Both grades award bonus Excavation XP.
* Progression Integration: As Excavation levels increase, the Sweet Spot grows larger, and at Level 99, "The Endless Vein" allows for a second Sweet Spot to appear, potentially triggering the 15% chance for double loot.

Spec: [1. The "Seismic Surge" (Active Extraction)](1.-the-seismic-surge-active-extraction.md)

#### 2. "Active Stabilization" (Lab Triage)

Currently, Sifting is a binary "Success or Shatter" roll. Active Stabilization adds a reactive layer to the Lab tension.

* The Mechanic: While the "Stability Gauge" needle is swinging wildly during a Sift, players can spend small amounts of Fine Dust (recovered from previous shatters) to "Tether" the needle, temporarily slowing its movement.
* The Impact: This doesn't increase the success percentage directly but allows the player to "Force Stop" the needle in a safer zone, reducing the chance of a "Critical Fail" (overheat) outcome.
* Progression Integration: Higher Restoration levels reduce the Fine Dust cost per Tether, while the "Master Preserver" perk (Level 99) makes the needle movement 10% slower by default.

Spec: [2. "Active Stabilization" (Lab Triage)](2.-active-stabilization-lab-triage.md)

#### 3. "Anomaly Overload" (The Combo Meter)

This expansion leverages the 5% Anomaly outcome to create a short-term "Fever Mode" for active players.

* The Mechanic: Every time an Anomaly is triggered, it fills one segment of an "Overload Meter" in the Header. At three segments, the player can manually trigger "Overload."
* The Impact: For 60 seconds, extraction speed is increased by 50%. During Raw Open (Stage 0), if the result would have been Junk, it has an extra 5% chance to upgrade to Common.
* Progression Integration: This interacts with the "Magnetic Interference" world event logic, where during the event, anomalies fill the meter twice as fast.

Spec: [3. "Anomaly Overload" (The Combo Meter)](3.-anomaly-overload-the-combo-meter.md)

#### 4. "Pre-Sift Appraisal" (Crate Prep)

This introduces a "Meso-to-Micro" bridge by allowing players to use their secondary skills before the gambling begins.

* The Mechanic: Before the first Sift (Stage 0), players can \[APPRAISE] a crate in the tray for a Scrap fee.
* The Impact: A successful appraisal reveals the "Mint Probability" or "Condition Range" (e.g., "Contains 80% Preserved or higher").
* Progression Integration: At Appraisal Level 60+, this also reveals one "Hidden Sub-stat" that will be active if the item is successfully claimed, helping the player decide if the risk of Sifting to Stage 5 is worth the potential Historical Value (HV).

Spec: [4. "Pre-Sift Appraisal" (Crate Prep)](4.-pre-sift-appraisal-crate-prep.md)

#### 5. "Shatter Salvage" (The Reaction Beat)

To make failure more interactive, Shatter Salvage adds a high-speed reaction task to the destruction of a relic.

* The Mechanic: On a **Standard Fail** (not overheat), when the "System Error" glitch occurs, a 1-second window opens for the player to click a "Salvage" icon.
* The Impact:
  * Stage 1–2 shatters: Salvage success doubles the Fine Dust payout.
  * Stage 3+ shatters: If the shatter rolled a Cursed Fragment, salvage success recovers it. Salvage miss loses it.
* Progression Integration: This directly feeds the Smelting "Fragment Alchemist" specialization, which increases the chance to recover these rare materials from high-level failures.

Spec: [5. "Shatter Salvage" (The Reaction Beat)](5.-shatter-salvage-the-reaction-beat.md)

#### 6. "Vault Heatmaps" (Zone Strategy)

This expansion makes the choice of where to dig more interactive based on the Global Feed.

* The Mechanic: The Field UI displays a "Static Intensity" heatmap for each unlocked Zone (e.g., The Sunken Mall vs. Rusty Suburbs).
* The Impact: Zones with higher "Static" grant up to `+2%` flat Crate drop rate, but apply up to `-5%` flat Sift Stability penalty in the Lab for items found there.
* Progression Integration: High-level Excavators can "Survey" a zone to briefly reduce its Static penalty for themselves, while Appraisal Level 99 ("The Oracle") provides the ability to see exactly which item catalog IDs are currently "trending" (dropping more frequently) in each zone.

Spec: [6. "Vault Heatmaps" (Zone Strategy)](6.-vault-heatmaps-zone-strategy.md)
