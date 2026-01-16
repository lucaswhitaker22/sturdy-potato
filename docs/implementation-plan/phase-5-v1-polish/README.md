# Phase 5: V1 Polish

## Phase 5: V1 Polish

Phase 5 is the “ship it” pass.

It turns Phase 4 into a product.

Build contract: [Phase 5 requirements](phase-5-requirements.md).

Canon references:

* UI feel + deck map: [6 - UI/UX Wireframe & Flow](../../game-overview/6-ui-ux-wireframe-and-flow.md)
* Premium currency + sinks: [4 - The MMO & Economy (Macro)](../../game-overview/4-the-mmo-and-economy-macro.md)
* Prismatics + dissolve: [3 - The Loot & Collection Schema](../../game-overview/3-the-loot-and-collection-schema.md)

***

### 1. V1 definition (what “done” means)

V1 is not “more content.”

V1 is a stable, readable, tactile loop.

V1 must feel complete across the five decks:

* Field
* Lab
* Vault
* Bazaar
* Archive

Phase 5 assumes all core systems already work.

Phase 5 does not change core odds or tier math.

***

### 2. Sensory pass (“every click has weight”)

This is the biggest leverage in a UI-only game.

Follow the rule from the UI/UX doc:

> Every click has a sound. Every success has a glow. Every failure has a glitch.

Minimum polish beats:

* **Field**
  * `[EXTRACT]` press: button depress + servo click.
  * Completion: short “reward” sting.
  * Crate drop: UI “thunk” + tray slot flash.
* **Lab**
  * `[SIFT]`: rising hum + stability needle shake.
  * Success: bright border flash + mechanical clink.
  * Shatter: static glitch + glass break.
* **Vault**
  * Item card hover/press states.
  * Set completion “gold glow” transition.
* **Bazaar / Archive**
  * Outbid / win / payout notifications.
  * Museum score ticks with a “ledger” sound.

Visual language must stay consistent:

* Wasteland screens (Field/Lab): noisy, glitchy, harsh.
* Oasis screens (Vault/Archive/Bazaar): stable, readable, safe.

***

### 3. The Lab “Reveal” sequence (mint + prismatic drama)

The reveal is the game’s slot-machine moment.

It should be impossible to miss.

Sequence goals:

* Anticipation (short delay, rising audio).
* Outcome clarity (success vs shatter).
* Identity stamp (mint number is “heavy”).
* Variant callout (Prismatic is unmistakable).

If Prismatics exist in V1, always broadcast them.

***

### 4. Onboarding and first-session clarity

V1 must teach the loop in minutes.

Ship a skippable “first session” flow:

1. Extract until you get a crate.
2. Take the player to the Lab.
3. Force one Sift decision (Claim vs Sift).
4. Show the Vault item card.
5. Point at one next goal (set silhouettes, skill levels, or Bazaar browsing).

Support the jargon with tooltips:

* Scrap, Crate
* Claim vs Sift
* Shatter
* Mint number
* Historical Value (HV) and Condition (if shown)
* Vault Credits and Historical Influence

***

### 5. Retention basics (light live-ops without complexity)

Ship one repeatable reason to log in.

Minimum retention loop:

* Daily Logbook
  * 2–3 tasks based on core actions (Extract, Sift, List/Bid).
  * Daily reward on completion.
  * Streak tracking.
* 30-day streak milestone
  * Cosmetic reward is fine.
  * Visible badge/frame is better.

Do not add complex questlines in V1.

***

### 6. Monetization: Vault Credits + the Archive Shop

Vault Credits are the premium currency (Macro canon).

V1 needs a store that feels native to the world.

Archive Shop minimum catalog:

* Cosmetic UI skins (CRT themes, frames, palettes).
* Vault expansions (more slots, more tabs).
* Stabilizer Charms (risk reduction).

Guardrails (to keep it sane):

* Never sell Scrap.
* Never sell Museum rank.
* Stabilizer Charms must be limited per action.
* Charms must show the exact effect before use.

If you allow “dissolve Prismatic → Vault Credits,” make it a deliberate choice:

* Warn that the item is destroyed.
* Show the credit payout.
* Let the player cancel.

***

### 7. Launch readiness (boring, necessary)

This is the stuff that makes V1 survive contact with players.

Minimum checklist:

* Server authority holds for RNG and currency writes.
* RLS is audited for common exploits.
* Requests fail gracefully (timeouts, retries, clear errors).
* Performance on mobile is acceptable.
* Analytics events exist for:
  * Onboarding completion
  * Extract/sift outcomes
  * Daily logbook completion
  * Store funnel (open → checkout → purchase)

***

### Phase 5 success metrics

1. New users reach Vault within one session.
2. Lab outcomes are readable without explanation.
3. Daily Logbook completes and rewards reliably.
4. The shop works end-to-end.
5. No common client-side cheats can mutate economy state.

***

### Related

* [Phase 5 requirements](phase-5-requirements.md)
