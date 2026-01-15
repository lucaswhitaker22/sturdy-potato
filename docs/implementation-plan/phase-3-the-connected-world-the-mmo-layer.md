# Phase 3: The "Connected World" (The MMO Layer)

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
