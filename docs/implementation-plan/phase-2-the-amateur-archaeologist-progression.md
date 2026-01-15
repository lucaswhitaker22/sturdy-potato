# Phase 2: The "Amateur Archaeologist" (Progression)

## Phase 2: The "Amateur Archaeologist" (Progression)

While Phase 1 proved the loop, Phase 2 builds the "hook." This phase introduces the long-term grind, the dopamine of leveling up, and the strategic satisfaction of automating your resource collection.

***

### 1. The Skilling Engine: Action $$ $\to$ $$ Growth

In this phase, every click counts for more than just Scrap. We introduce the Experience (XP) layer to simulate the OSRS-style progression.

#### 1.1 Excavation Skill (The Gatherer)

* XP Source: Every time a manual \[EXTRACT] finishes or an "Auto-dig" tick occurs.
* The Curve: Level 1 requires 100 XP. Each level increases the requirement by \~10%.
* The Payoff: Every 5 levels increases your "Crate Drop Rate" by 0.5%.

#### 1.2 Restoration Skill (The Gambler)

* XP Source: Awarded upon completing a "Sift" (Success gives 100% XP, Failure/Shatter gives 25% "Pity XP").
* The Payoff: Every level adds a +0.1% flat bonus to your Stability Gauge (Success Chance). At Level 50, a 75% success rate becomes 80%.

***

### 2. The Workshop: Tool Tiers & Automation

The Workshop is the first major "Scrap Sink." It converts your currency into Passive Income.

#### 2.1 The Progression Table

| **Tool Name**    | **Scrap Cost** | **Level Req** | **Passive Power**         |
| ---------------- | -------------- | ------------- | ------------------------- |
| Rusty Shovel     | 0              | 1             | 0 Scrap/sec (Manual Only) |
| Pneumatic Pick   | 1,500          | 5             | 2 Scrap/sec               |
| Ground Radar     | 10,000         | 15            | 10 Scrap/sec              |
| Industrial Drill | 50,000         | 30            | 50 Scrap/sec              |

#### 2.2 Automation Logic

Once a player buys a tool, the UI starts "Passive Extraction."

* Visual: A small secondary progress bar on the \[THE FIELD] screen that fills automatically.
* The Tick: Every time the bar fills, the player gains Scrap. Crates can also drop passively, appearing in the "Crate Tray" with a notification.

***

### 3. The Collection Book: Set Logic & Buffs

The Collection Book turns random items into strategic goals. It introduces "Sets" that provide permanent modifiers to the player's account.

#### 3.1 The "Check" Logic

When an item is added to the Vault, the game runs a `checkSetCompletion()` function.

* Example Set: _The Morning Ritual_ (Ceramic Mug + Rusty Toaster + Spoon).
* The Reward: Once all three are "Vaulted," the set glows Gold.
* The Buff: "Caffeine Rush" — Reduces the \[EXTRACT] cooldown by 0.5 seconds permanently.

#### 3.2 Collection UI

A new tab is added to the Vault labeled \[COLLECTIONS]. It shows silhouettes of missing items to trigger the "Gotta Catch 'Em All" instinct.

***

### 4. The Save System: Persistence

To move away from "Session-only" play, Phase 2 implements a robust save state.

* Supabase Integration: \* The `profiles` table is updated with `scrap`, `excavation_xp`, and `restoration_xp`.
  * The `inventory` table stores all found items.
* Auto-Save: The game pushes a state update to Supabase every 30 seconds or whenever a "Major Event" (Level Up / Rare Find) occurs.
* Offline Gains: When a player logs in, the game calculates the time since `last_logout` and awards the Scrap earned by their Auto-tools during that window.

***

### 5. UI Updates for Phase 2

The UI must now accommodate more data without becoming a "Spreadsheet."

* Header: Added small "Level Bubbles" next to the player name (e.g., _Excav: 12 | Resto: 8_).
* The Toast System: Small pop-ups at the bottom of the screen:
  * _"Excavation Level Up! (Level 13)"_
  * _"Set Complete: 'The Office' (+5% Scrap Yield)"_
* Workshop Tab: A simple vertical list of tools with "BUY" buttons that are greyed out until the player has enough Scrap and the required level.

***

### Phase 2 Success Metrics

1. A player can reach Level 10 in both skills.
2. The player can purchase the Pneumatic Pick and see their Scrap increase without clicking.
3. Completing a set of 3 items successfully applies a visible "Buff" to the player's stats.
4. Refreshing the browser allows the player to continue exactly where they left off.

***

Would you like me to provide the technical Vue/Supabase logic for the "Offline Gains" calculation or the "Collection Set" verification function?
