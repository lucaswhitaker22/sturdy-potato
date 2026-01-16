# Phase 5: V1 Polish

#### 1. Persistence and Progression (Phase 2)

The game must move beyond session-based play to a long-term "grind" supported by a database:

* Supabase Integration: Move all player state (Scrap, XP, inventory) from local storage to a permanent database to enable autosaves and cross-device play.
* RPG Skilling System: Implement Action-Based Experience (XP) for skills, including an OSRS-style level curve and level-based payoffs like improved drop rates and stability bonuses.
* The Workshop: Add a "Scrap Sink" where players purchase tool upgrades (e.g., Pneumatic Pick, Industrial Drill) to unlock passive resource generation and offline gains.
* Collection Sets: Implement the \[COLLECTIONS] tab and set-check logic to award permanent account buffs for completing specific item groups.

#### 2. The MMO Layer and Security (Phase 3)

V1 requires a connected world where players interact through a shared economy:

* Server Authority: Move all RNG for sifting and loot drops to the server (Supabase Edge Functions) to prevent client-side tampering and ensure economy integrity.
* The Bazaar: Launch the player-driven auction house with bidding, escrow systems, and a 5% "Archive Tax" to serve as an economic money sink.
* Global Minting: Implement global serial numbers (e.g., #001) for every artifact to create digital scarcity and social prestige.
* Real-time Feed: Deploy a global activity feed that broadcasts significant discoveries and sales to all online players.

#### 3. Meta-Game and World Dynamics (Phase 4)

Deepen the late-game experience with competitive and social systems:

* The Global Museum: Implement weekly themed competitions where players lock their best items into exhibitions to earn Historical Influence (HI) and climb leaderboards.
* The Influence Shop: Create a non-tradable currency loop where HI is spent on "Unbuyables" like gated Zone Permits and elite skill training (Levels 90–99).
* World Events: Introduce time-boxed events (e.g., "The Great Thaw") that trigger global stat modifiers and unique, event-only loot drops.
* Advanced Skilling: Add Appraisal and Smelting skills, unlocking high-level features like item certification and bulk auto-smelting.

#### 4. Sensory Polish and Monetization (Phase 5)

Finalize the "Game Feel" and establish sustainability for the live service:

* Tactile UI & Audio: Implement the full "Scavenger’s Soundscape" and "Juice" pass, including CSS-based CRT filters, haptic screen shakes, and mechanical audio cues for every interaction.
* The "Reveal" Sequence: Maximize tension during Lab refinements with high-quality animations, static glitch effects, and "heavy stamp" sound effects for mint numbers.
* Sustainable Monetization: Launch the Archive Shop for Vault Credits (premium currency) to sell cosmetic UI skins, inventory expansions, and Stabilizer Charms.
* Retention Mechanics: Implement a daily logbook with rewards for consistent play and a 30-day streak bonus.
