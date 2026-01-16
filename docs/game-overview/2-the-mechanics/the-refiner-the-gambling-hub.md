# The Refiner (The Gambling Hub)

## \[02] THE LAB — The Refiner (Gambling Hub)

The Lab is the risk engine.

The Field produces Crates. The Lab decides their value.

This page is the canonical spec for **sifting**.

Related:

* Loop context: [0 - Game Loop](../0-game-loop.md)
* Field inputs: [The Dig Site (Main Screen)](the-dig-site-main-screen.md)
* Loot identity rules: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md)
* Skill powering this screen: [Restoration](../5-rpg-skilling-system/restoration.md)

***

### Goals

This screen must:

* Make risk readable in one glance.
* Create “one more sift” pressure.
* Make failure interactive, not passive.
* Keep the economy fair via server-owned RNG.

Non-goals:

* No hidden stability changes.
* No macro system rewriting base stage chances.

***

### Inputs and outputs

#### Inputs

* **Encapsulated Crates** from the Field.
* Optional consumables:
  * **Fine Dust** (used for Active Stabilization).
  * **Cursed Fragments** (used for Emergency Glue).
* Optional paid intel:
  * **Appraisal fee** for Pre-Sift Appraisal.

#### Outputs

* A revealed relic (success path).
* Or materials + XP (failure path).

***

### The Sift loop (core)

Each crate progresses through stages.

At each stage, the player chooses:

* **\[CLAIM]** to stop safely.
* **\[SIFT]** to gamble for the next tier.

#### Stages (canonical baseline)

| Stage | Action name     | Rarity potential | Base Stability |
| ----- | --------------- | ---------------- | -------------- |
| 0     | Raw Open        | Common (95%)     | 100%           |
| 1     | Surface Brush   | Uncommon (30%)   | 90%            |
| 2     | Chemical Wash   | Rare (25%)       | 75%            |
| 3     | Sonic Vibration | Epic (15%)       | 50%            |
| 4     | Molecular Scan  | Mythic (10%)     | 25%            |
| 5     | Quantum Reveal  | Unique (1%)      | 10%            |

Notes:

* Stage 0 is always safe.
* Stages 1–5 can shatter.
* Stage names are UI copy. Keep them consistent everywhere.

***

### Stability rules (what players can trust)

Stability is the visible success chance for the current stage.

It must be computed server-side.

#### Restoration synergy (baseline)

* Each Restoration level adds `+0.1%` **flat** Stability.
* Restoration XP comes from sifting.
* Failures grant “Pity XP.”

#### Restoration 99 mastery (baseline)

Reaching level 99 grants:

* `+10%` **base** Stability to all sifting tiers.
* The Stability needle moves `10%` slower by default.

{% hint style="info" %}
“Needle slower” is UX only.\n It does not change the underlying success roll.\n The roll stays server-side.
{% endhint %}

#### Zone Static penalties (from the Field)

Crates carry Static metadata from their source zone.

Static can apply a **flat** Stability penalty in the Lab.

Rule:

* Read the stored `staticTierAtDrop`.
* Do not recalc zone static at open time.

Spec anchor: [The Dig Site (Main Screen)](the-dig-site-main-screen.md).

***

### Failure states (Shatter outcomes)

When a stability check fails, the item **Shatters**.

Failure must feel loud and final.

#### Standard Fail

* Common failure result.
* Payout: `5–10` Fine Dust.

#### Critical Fail (overheat)

* Catastrophic failure result.
* Payout: `0` materials.
* Lab enters a `5m` cooldown.

#### Cursed Fragment (rare salvage component)

On shattering a **Stage 3+** attempt:

* Roll `1%` chance to recover **1 Cursed Fragment**.
* This roll is independent of Fine Dust payout.

{% hint style="warning" %}
The Cursed Fragment roll is not a “success.”\n It is a consolation roll on high-stage failure.\n Keep it rare.
{% endhint %}

***

### Active layers (micro “press moments”)

These layers make the Lab feel skill-based without removing risk.

#### Active Stabilization (Lab triage)

During the needle swing, the player can spend **Fine Dust** to “Tether” the needle.

Rules:

* Tether does not increase Stability.
* It briefly slows or pauses the needle.
* Restoration reduces Fine Dust cost per tether.

#### Shatter Salvage (reaction beat)

On **Standard Fail** only, open a `1s` reaction window.

If the player clicks **\[SALVAGE]** in time:

* Stage 1–2 shatters: Double Fine Dust payout.
* Stage 3+ shatters:
  * Roll the Cursed Fragment chance as normal.
  * If a fragment was rolled, Salvage success recovers it.
  * If Salvage is missed, the fragment is lost.

This makes failure interactive.

It does not remove the loss.

#### Emergency Glue (Restoration 60+ reaction)

Emergency Glue is a “save” button in the same failure beat.

Rules:

* Trigger: Standard Fail only.
* Never triggers on Critical Fail.
* Never triggers on Stage 0.
* Cost: consumes `1` Cursed Fragment.
* Effect: converts the failure into a forced **\[CLAIM]** at the **current stage**.
* It never converts a fail into a success.

Interaction rule:

* One failure beat = one reaction choice.
* If both buttons exist, first pressed wins.

Details: [Active Skill Abilities (Tactile Commands)](../../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md).

#### Pre-Sift Appraisal (crate prep)

Before Stage 0, the player can pay Scrap to **\[APPRAISE]** a crate.

On success, Appraisal reveals one preview:

* Mint Probability (estimate), or
* Condition Range (estimate).

Appraisal `60+` can also reveal:

* One hidden sub-stat that will apply if the item is claimed.

Hard rule:

* Appraisal never changes the RNG outcome.\n It only reveals information.

See: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md).

***

### The reveal and item identity (server rules)

#### Mint number assignment

Mint numbers are assigned server-side at item creation time.

They must be atomic per catalog ID.

Rule:

* There is only one “#001” per item catalog ID.

See: [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md).

#### Condition, HV, and hidden stats

On success, the revealed item must be generated server-side with:

* Rarity tier.
* Condition.
* Mint number.
* Historical Value (HV) breakdown.
* Optional hidden sub-stats (if rolled).

Reveal rules are defined in:

* [3 - The Loot & Collection Schema](../3-the-loot-and-collection-schema.md)
* [The "Mint & Condition" System](../3-the-loot-and-collection-schema/the-mint-and-condition-system.md)

#### Prismatic roll (“Shiny”)

On any **successful SIFT** action, roll for a Prismatic variant.

Baseline:

* Chance: `1%`
* Effect: item becomes Prismatic.
* Presentation: border pulse + special reveal burst.

Prismatics also support “Dissolve → Vault Credits.”

Spec anchor: [The "Shiny" Mechanic](../3-the-loot-and-collection-schema/the-shiny-mechanic.md).

{% hint style="info" %}
Prismatic is a secondary roll.\n It does not replace rarity, condition, or mint assignment.\n It layers on top.
{% endhint %}

***

### UI layout (recommended)

#### Primary components

* **Crate queue / tray**
  * Shows unopened crates.
  * Shows source zone + static tier icons.
* **Stage panel**
  * Current stage name.
  * Current Stability %.
  * Reward preview for claiming (what you’d lock in now).
* **Action buttons**
  * **\[CLAIM]** (safe stop).
  * **\[SIFT]** (risk).
  * Optional: **\[APPRAISE]** (pre-sift).
* **Needle / stability widget**
  * A visible swing that sells tension.
  * Must not imply client-side RNG.
* **Failure beat overlay**
  * “System Error” glitch moment.
  * Reaction buttons (Salvage / Emergency Glue) when applicable.

#### Readability rules

* Always show:
  * current stage,
  * current Stability,
  * what “Claim” means right now.
* Never show:
  * exact mint math,
  * exact catalog IDs,
  * hidden stat exact values before reveal.

***

### Sensory payoff (“the reveal”)

This is the dopamine beat.

It must escalate with stage risk.

Recommended cues:

* Anticipation: low hum ramps during needle swing.
* Success: bright border flash + crisp mechanical `clink-clink`.
* Shatter: static glitch + breaking glass + “System Error.”
* High-tier reveal:
  * Mint number “stamp” animation.
  * Feed ping for Mythic/Unique and Prismatics.

***

### System integrity notes (non-negotiable)

* Stage table values above are canonical baselines.
* Stage 0 is always `100%`.
* Static penalties must come from stored crate metadata.
* All rolls are server-owned.
* Macro systems may apply explicit time-boxed modifiers.
* Macro systems must not rewrite baseline odds.

See:

* World events: ["The Great Static" Events (incl. Static Pulses)](../../expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md)
* Currency sinks (Fine Dust, Vault Credits): [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md)

***

### State machine and edge cases (implementation rules)

These rules prevent exploits and “it ate my crate” tickets.

#### Crate state

Each crate should have a single authoritative state:

* `UNOPENED`
* `IN_PROGRESS` (current stage stored)
* `CLAIMED` (item minted and delivered)
* `SHATTERED` (rewards delivered)

Rule:

* A crate can only transition forward.\n Never backward.\n Never twice.

#### Disconnect safety

If the player disconnects mid-attempt:

* The server finishes the attempt.\n It already has the roll.
* On reconnect, show the outcome replay.\n Do not re-roll.

#### Cooldown (overheat) gating

If a Critical Fail triggered overheat:

* Lock **\[SIFT]** actions for `5m`.
* Allow browsing inventory and reading logs.
* Allow claiming already-safe rewards (if any).\n Never allow new gambles.

#### Claim button behavior

**\[CLAIM]** must be deterministic:

* It never fails.
* It ends the crate.
* It produces one item with final identity fields.

***

### Telemetry (for tuning)

Track:

* Sifts started per stage per day.
* Claim rate vs sift rate per stage.
* Success rate vs theoretical Stability (detect bugs).
* Standard vs Critical fail distribution.
* Fine Dust earned vs spent.
* Cursed Fragments minted vs consumed.
* Prismatic rate per stage and per day.
