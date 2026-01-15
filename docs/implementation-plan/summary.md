# Summary

### Phase 1: The "Clicker" Foundation (MVP)

Goal: Create a functional single-player loop where you can dig, find a crate, and gamble it.

* Logic: Set up the basic state machine (Scrap count, Crate inventory).
* The Dig: Implement the \[EXTRACT] button with a basic progress bar.
* The Refiner: Build the 5-stage "Sift" logic. Use simple math for Success/Shatter.
* Item System: Create a JSON database of 20 "Common" and "Rare" items.
* UI: A basic functional layout (Buttons, Labels, and a simple List for inventory).

### Phase 2: The "Amateur Archaeologist" (Progression)

Goal: Introduce the OSRS-style grind and the workshop.

* Skilling Engine: Implement XP tracking for Excavation and Restoration.
* Workshop: Create the Tool Tier system. Link "Scrap Cost" to "Auto-dig" power.
* Collection Sets: Implement the "Collection Book." Create the logic that checks if a set is complete and applies a passive buff.
* Save System: Local browser storage or a simple user account database (Firebase/Supabase).

### Phase 3: The "Connected World" (The MMO Layer)

Goal: Transition from a solo game to a persistent world.

* Real-time Feed: Implement a "Global Activity Feed" using WebSockets (Socket.io) to show when players find rare items.
* The Bazaar: Build the Auction House. Focus on "Listing" and "Bidding" logic.
* Minting Logic: Implement the "Global Serial Number" system so every item has a unique `#ID`.
* Server Logic: Move the "Sifting" logic to the server-side to prevent players from cheating the RNG.

## Phase 3: The "Connected World" (The MMO Layer)

In Phase 3, the game moves from a single-player "clicker" into a living, breathing Massively Multiplayer Online (MMO) environment. This transition focuses on social validation, market competition, and digital scarcity.

***

### 1. The Global Activity Feed (Social Proof)

The Global Feed is a real-time, scrolling text ticker that appears on every player's screen. It serves as the game's "heartbeat," making the world feel populated even if you are playing solo.

* The Content: The feed broadcasts significant events:
  * Epic Finds: _"User\_Scavenger just unearthed \[Old World Smartphone #004]!"_
  * High-Stakes Gambles: _"RNG\_Lord successfully sifted a Crate to Stage 5!"_
  * Bazaar Sales: _"A \[Vintage GameBoy] was just sold for 1.2M Scrap!"_
* The Psychology: Seeing other players succeed in real-time creates a "gold rush" effect, encouraging active play and high-risk refining.

***

### 2. The Bazaar: The Player-Driven Economy

The Bazaar is a centralized UI where players trade artifacts. This introduces a "Buy Low, Sell High" meta-game that exists entirely within menus.

#### 2.1 Listing & Bidding Logic

* Listing: Players put an item from their Vault onto the market. They must set a Duration (e.g., 24 hours) and a Reserve Price (Minimum bid).
* Bidding: Other players place bids using their stored Scrap. When a new bid is placed, the bidder's Scrap is "held" by the Archive.
* The Outbid: If a player is outbid, their Scrap is instantly returned to their account with a notification: _"You have been outbid on \[Item Name]!"_
* The Result: At the end of the duration, the highest bidder gets the item, and the seller receives the Scrap (minus a 5% "Archive Tax").

***

### 3. Minting Logic: The Serial Number System

To make items truly unique and tradable, every artifact generated is assigned a Global Serial Number (e.g., _Toaster #001_).

* Scarcity: There is only ever one "#001" of any item in the entire game world.
* Historical Value (HV): Low-digit mints (#1–#10) receive a massive multiplier to their Historical Value.
* The Pursuit: Players will often prioritize buying a "Common #005" over a "Rare #45,000" because of the prestige and social status associated with early discoveries.

***

### 4. Server Authority: The Security Layer

To ensure the MMO economy remains fair, all "Game Logic" is moved from the player's browser to the Server (Supabase).

* Cheating Prevention: In Phase 1/2, a clever player could potentially "hack" their local browser code to win every gamble. In Phase 3, the player only sends a "Request" to sift. The Server rolls the dice, updates the database, and sends the result back.
*   The "Handshake": 1. Player clicks \[SIFT].

    2\. Client sends sift\_request to Supabase.

    3\. Server checks: Does player have enough Scrap? Is the crate real?

    4\. Server generates the RNG and updates the Vault.

    5\. Client receives the result and plays the animation.

***

### Phase 3 Success Metrics

1. Market Activity: At least 50 successful player-to-player trades in the Bazaar.
2. Live Presence: The Global Feed successfully broadcasts a "Rare Find" to all online players simultaneously.
3. Integrity: Attempting to manually edit "Scrap" values in the browser console results in an error, as the server holds the "Source of Truth."
4. Value Variance: Players are actively bidding significantly more for "#001" items than for higher-numbered versions of the same item.

***

Would you like me to move on to Phase 4: The "High Curator" (Meta-Game), covering the Global Museum and World Events?

[Supabase Realtime with Vue 3](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3DVO0v4C2U7vM)

This video provides a practical guide on implementing real-time broadcast and database listeners in a Vue 3 application using Supabase, which is essential for building the Global Activity Feed and real-time Bazaar updates mentioned in Phase 3.

### Phase 5: The "Polished Vault" (Juice & Launch)

Goal: Make the UI feel like a premium game, not a spreadsheet.

* Visual Juice: Add screen-shake on sifting, glowing borders for rare items, and CRT-flicker effects.
* Audio Pass: Implement the tactile "Click," "Clink," and "Shatter" sounds.
* Monetization: Add the Premium Shop for UI skins and "Stabilizer" charms.
* Retention: Build the "Daily Logbook" (7-day login streak) and Daily Tasks.

***

#### Implementation Priority Matrix

| **Feature**              | **Difficulty** | **Impact** | **Priority**   |
| ------------------------ | -------------- | ---------- | -------------- |
| Sifting RNG Logic        | Low            | Critical   | P0 (Immediate) |
| Item Minting Database    | Medium         | High       | P0 (Immediate) |
| Bazaar (Auction House)   | High           | Critical   | P1 (Core MMO)  |
| Level 99 Masteries       | Medium         | High       | P2 (Mid-Term)  |
| Sound Effects/Animations | Low            | Very High  | P2 (Mid-Term)  |

***

#### Technical Recommendation for "Simple" Start:

1. Backend: Use Supabase or Pocketbase. They handle the database and user authentication out of the box, allowing you to focus on the game logic.
2. Frontend: Use React or Vue. The "State" management (tracking XP/Scrap) is much easier in these frameworks.
3. Hosting: Vercel or Netlify for free/cheap hosting of the UI.

Would you like me to draft a sample "XP Table" for Levels 1–99 or create the specific "Item Attributes" for a JSON database entry?
