# Phase 5: The "Polished Vault" (Juice & Launch)

## Phase 5: The "Polished Vault" (Juice & Launch)

In Phase 5, the transition from a "functional prototype" to a "premium-feel game" occurs. Since there is no 3D movement, the "Game Feel" (Juice) is entirely dependent on CSS animations, high-quality audio, and haptic feedback. This phase also focuses on keeping the servers running via fair monetization.

***

### 1. Sensory Design: The "Tactile" UI

The UI should never feel static. It must feel like a physical machine responding to the player.

* The Glow & Flicker: Use CSS "CRT" filters. Rare items should have a persistent, soft pulse. Mythic items should have "Prismatic" shifting gradients on their borders.
* The Shake:
  * Minor: When the \[EXTRACT] button is clicked.
  * Major: When a high-tier Sift succeeds or an item Shatters.
* Dynamic Backgrounds: The background of the UI should subtly shift based on the current "Zone." (e.g., drifting dust particles in the _Dusty Suburbs_, or scrolling binary code in the _Data Center_).

***

### 2. Audio Pass: The Scavenger’s Soundscape

Audio provides the weight that 2D UI lacks.

* The "Satisfying Click": Every button should have a unique, heavy mechanical click. Avoid generic "beeps."
* Rarity Cues:
  * Common: A short, metallic _clink_.
  * Epic: A resonant chime.
  * Unique: A low-frequency "Gong" that echoes for 3 seconds.
* Environmental Audio: A constant, low-bitrate ambient wind track. When in the Bazaar, add the faint sound of a crowded terminal or radio static.

***

### 3. Advanced Feedback Loops: "The Reveal"

The most important screen in the game is the Lab Reveal. We maximize the tension here.

1. The Shake: As the progress bar reaches 100%, the item frame begins to vibrate.
2. The "Glitch": For a split second (0.1s), show "Corrupted" static.
3. The Reveal: The static clears to show the item icon, accompanied by a "flash" effect that covers the UI.
4. The Number: The Mint Number (e.g., #005) slams down onto the card with a heavy stamp sound.

***

### 4. Monetization & Sustainability

To keep the game free-to-play while supporting development, we focus on "Convenience and Cosmetics," avoiding "Pay-to-Win."

#### 4.1 The Archive Shop (Vault Credits)

* Stabilizer Charms: Consumables that reduce the chance of shattering during a Sift. (Can also be earned rarely via high-level Smelting).
* UI Skins: Alternative "OS" themes (e.g., _Military Overhaul_, _Minimalist Ghost_, _Retro 1995_).
* Inventory Expansion: Purchasing additional "Tabs" for the Vault.
* Supporter Badge: A unique icon in the Global Feed that shows the player supports the game.

#### 4.2 The "Daily Logbook" (Retention)

* A UI calendar that rewards daily logins.
* Day 7 Reward: A "Golden Crate" with guaranteed Rare+ loot.
* Streak Bonus: Maintaining a 30-day streak unlocks a unique "Veteran" UI skin.

***

### 5. Technical "Polishing" with Vue + Supabase

* Skeleton Loaders: Instead of "Loading..." text, show animated grey boxes that match the UI shape while fetching data from Supabase.
* Optimistic UI: When a player clicks "Buy" in the Bazaar, the Scrap count should drop _instantly_ in the UI while the server handles the database transaction in the background. If the transaction fails, the Scrap "rolls back."
* Mobile Responsiveness: Ensure all buttons are "Thumb-Target" size (min 44px) for players on mobile browsers.

***

### Phase 5 Success Metrics

1. Dwell Time: Average session length increases because the UI is satisfying to interact with.
2. Conversion: At least 5% of the active player base purchases a cosmetic skin or expansion.
3. Performance: The UI maintains 60fps animations even when the Global Feed is busy.
4. Viral Loop: Players start sharing screenshots of their "Mint #1" items on social media due to the high-quality visual presentation.
