# Status

This page is the build-facing “what’s left / what’s next” list.

It also links to every other doc, so nothing gets orphaned.

### Canon map (where truth lives)

Use these as your primary sources:

* Product + tone: [1. The Vision & World Bible](../game-overview/1.-the-vision-and-world-bible.md)
* Player loop: [0 - Game Loop](../game-overview/0-game-loop.md)
* System rules master: [2: The Mechanics](../game-overview/2-the-mechanics.md)
* Loot identity + HV: [3 - The Loot & Collection Schema](../game-overview/3-the-loot-and-collection-schema.md)
* Macro economy: [4 - The MMO & Economy (Macro)](../game-overview/4-the-mmo-and-economy-macro.md)
* Skilling baseline: [5 - RPG Skilling System](../game-overview/5-rpg-skilling-system/)
* UI surfaces: [6 - UI/UX Wireframe & Flow](../game-overview/6-ui-ux-wireframe-and-flow.md)
* Tech approach: [Technical Framework (Vue + Supabase)](technical-framework-vue-+-supabase.md)

### Gap analysis (ALL docs → buildable backlog)

This is the “everything we still need to build” list, based on _all_ docs.

It explicitly covers:

* [6 - Progression, Quests, Achievements](../game-overview/6-progression-quests-achievements/)
* [5 - RPG Skilling System](../game-overview/5-rpg-skilling-system/)
* [4 - The MMO & Economy (Macro)](../game-overview/4-the-mmo-and-economy-macro.md)

#### Phase coverage gaps (requirements → tasks)

These are lifted from the phase “build contract” pages.

<details>

<summary><strong>Phase 1 gaps</strong> (Field → Lab → Vault MVP)</summary>

Source: [Phase 1 (MVP) requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/whZFSOeTpyhQynDJUqds)

* [ ] Field screen:
  * [ ] Show Scrap balance + tray count.
  * [ ] `[EXTRACT]` button with progress + cooldown.
  * [ ] Disable `[EXTRACT]` when tray is full (`5/5`) + clear message.
* [ ] Extract RNG (exactly one outcome per extract):
  * [ ] `80%` → add `+10` Scrap.
  * [ ] `15%` → add `+1` Crate (stage 0) to tray.
  * [ ] `5%` → Anomaly (Phase 1: log-only).
* [ ] Navigation between Field / Lab / Vault without state loss.
* [ ] Lab:
  * [ ] Select crate from tray.
  * [ ] Stage model (`0–5`) and stage odds table.
  * [ ] `[CLAIM]` resolves reward at current stage.
  * [ ] `[SIFT]` attempts success roll → stage+1 or shatter.
  * [ ] Shatter destroys crate, grants `+3` Scrap, logs + failure beat.
* [ ] Vault:
  * [ ] Lists earned items with name + flavor text.
  * [ ] Shows progress `items_found / 20`.
* [ ] Persistence:
  * [ ] Local persistence restores state on reload.
* [ ] Decisions (open questions):
  * [ ] Parallel refining vs single active crate.
  * [ ] “Discard crate” action or not.
  * [ ] Vault size cap or not.
  * [ ] True Epic items in MVP or not.

</details>

<details>

<summary><strong>Phase 2 gaps</strong> (progression + persistence)</summary>

Source: [Phase 2 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/3UMkX37vTIwHL0uoayLS)

* [ ] XP + levels:
  * [ ] Track Excavation + Restoration XP server-side.
  * [ ] OSRS XP curve mapping → levels.
  * [ ] UI shows `Excav: <level> | Resto: <level>`.
* [ ] Excavation:
  * [ ] XP from manual extracts and auto ticks.
  * [ ] Crate chance bonus `+0.5%` per 5 levels (additive) + tooltip display.
* [ ] Restoration:
  * [ ] XP from sifts (100% on success, 25% pity on fail).
  * [ ] Stability bonus `+0.1%` per level (flat) + UI breakdown.
  * [ ] Decide and implement Stability cap rule (open question).
* [ ] Workshop:
  * [ ] Workshop tab with tool tiers (min list: Shovel, Pick, Radar, Drill).
  * [ ] Purchase gating: Scrap + level requirement.
  * [ ] Set purchased tool as active tool.
* [ ] Passive extraction:
  * [ ] 10s tick loop (online) with Scrap gain.
  * [ ] Passive crate rolls.
  * [ ] Define behavior when tray is full (open question; recommended: no crates, Scrap continues).
* [ ] Collections:
  * [ ] Vault `[COLLECTIONS]` tab with silhouettes.
  * [ ] Set completion check on item acquire.
  * [ ] Minimum set: “Morning Ritual” + reward `-0.5s` `[EXTRACT]` cooldown.
  * [ ] Buff system that persists and re-applies on login.
* [ ] Persistence (Supabase):
  * [ ] `profiles`: scrap, excavation\_xp, restoration\_xp, active\_tool\_id, last\_logout.
  * [ ] `inventory`: player\_id + item\_catalog\_id rows.
  * [ ] Autosave every 30s + on major events.
  * [ ] Offline gains calculation + Battery Capacity cap + UI readout.
* [ ] Integrity:
  * [ ] Server-owned RNG for any new RNG in Phase 2 (passive crate rolls).

</details>

<details>

<summary><strong>Phase 3 gaps</strong> (MMO layer)</summary>

Source: [Phase 3 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/GcPUD3swAP8KbhaBt30Q)

* [ ] Global Activity Feed:
  * [ ] Visible on all primary decks.
  * [ ] Realtime delivery via Supabase Realtime (≤2s).
  * [ ] Retain last 50 events on load.
  * [ ] Event types: finds, high-stage sifts, bazaar sales.
* [ ] Bazaar (auctions):
  * [ ] Create listings from Vault items.
  * [ ] Escrow lock state on listed item.
  * [ ] Listing deposit (held + refund rules).
  * [ ] Browse active listings.
  * [ ] Bid holds (held Scrap), outbid refund + notification.
  * [ ] Auction settlement at `ends_at` (server, idempotent).
  * [ ] Archive tax `5%` + deterministic rounding rule.
  * [ ] Realtime listing + bid updates.
* [ ] Minting:
  * [ ] Atomic mint assignment per `item_catalog_id`.
  * [ ] Low mint (`#001–#010`) prestige badge / `+50%` HV multiplier surface.
* [ ] Server authority + RLS:
  * [ ] Block client writes to Scrap, inventory, listings, bids, settlement.
  * [ ] Handshake flow for `[SIFT]` at minimum.
* [ ] Decisions (open questions):
  * [ ] Feed broadcast rarity threshold.
  * [ ] Seller cancellation policy + deposit return/burn.
  * [ ] Listing cap per user.
  * [ ] Held Scrap representation (`available` vs `held`).
  * [ ] HV now vs later.

</details>

<details>

<summary><strong>Phase 4 gaps</strong> (Archive meta-game + advanced skills)</summary>

Source: [Phase 4 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/W0goIsLgTGnXgIRcgKtm)

* [ ] Archive deck exists:
  * [ ] Museum
  * [ ] World Events
  * [ ] Influence Shop
* [ ] Museum:
  * [ ] Weekly theme schedule + start/end announcements in feed.
  * [ ] Submissions UI + locking until week ends (cap: 10).
  * [ ] Deterministic scoring + readable breakdown.
  * [ ] Realtime leaderboard (top 100 + your rank).
  * [ ] Week end finalization: payout + unlock items (server, idempotent).
  * [ ] Reward tiers: Top 1%, Top 10%, participation.
* [ ] Historical Influence (HI):
  * [ ] `profiles.historical_influence` ledgered.
  * [ ] Earn HI only via Museum + World Events.
  * [ ] Influence Shop items + purchases table.
  * [ ] Zone permits (Sunken Mall, Corporate Archive, Sovereign Vault).
  * [ ] Dual-gates: permit + Total Level (`100 / 250 / 380`) lock UX.
  * [ ] Elite training unlock: cap Appraisal/Smelting at 90 until HI unlock.
* [ ] World Events (“Great Static”):
  * [ ] Event start/end broadcasts + persistent banner + full effects view.
  * [ ] Event-only loot window support.
  * [ ] Modifiers (extract speed, sift success bonus) applied server-side.
  * [ ] Global goal progress bar + realtime updates.
  * [ ] Contribution tracking + participation rewards (idempotent).
* [ ] Advanced skills (Appraisal + Smelting):
  * [ ] XP sources for both skills.
  * [ ] Appraisal 60+: hidden sub-stats generation (once per item).
  * [ ] Smelting: deterministic smelt outputs + bulk auto-smelt.
  * [ ] Cursed Fragments as materials (storage + drop rules).
  * [ ] Stabilizer Charms: introduce material type + storage (full crafting UI can wait).
* [ ] 60+ ability framework (server-owned):
  * [ ] Focused Survey (Excav 60+).
  * [ ] Emergency Glue (Resto 60+).
  * [ ] Hype Train (Appraisal 60+).
  * [ ] Overclock Furnace (Smelting 60+).
* [ ] Branch picks (level 60):
  * [ ] Choose 1 branch per skill.
  * [ ] Respec: paid + cooldown, blocked mid-action.
* [ ] Mastery layer:
  * [ ] Level 99 broadcasts + mastery badges shown in Museum + Bazaar.
  * [ ] Activate all 99 perks (Excav double loot, Resto base stability + HV, Appraisal oracle + tax, Smelting pure yield).
  * [ ] Cross-skill masteries (80/80) as a system + at least 2 effects implemented.
  * [ ] Total mastery (all 90+): Senior Researcher + Research Notes panel (theme preview).
* [ ] Decisions (open questions):
  * [ ] Exact Museum score formula and what affects it (certified? hidden stats?).
  * [ ] Set bonus rule in Museum scoring.

</details>

<details>

<summary><strong>Phase 5 gaps</strong> (V1 polish + monetization)</summary>

Source: [Phase 5 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/CuGFgLZMnJn3FCWcFAB7)

* [ ] Sensory coverage:
  * [ ] Sound + visual cue for every high-frequency action.
  * [ ] Distinct Lab reveal sequence (anticipation + mint stamp + prismatic distinct).
* [ ] Onboarding:
  * [ ] First-session walkthrough (skippable).
  * [ ] Glossary tooltips (Scrap, Crate, Sift vs Claim, Shatter, Mint, HV/Condition if shown).
* [ ] Retention:
  * [ ] Daily Logbook (server time reset) + streak tracking.
  * [ ] 30-day streak cosmetic reward.
* [ ] Vault Credits + monetization:
  * [ ] `vault_credits` balance.
  * [ ] Earn via purchases + dissolving Prismatics.
  * [ ] Archive Shop sells skins, vault expansions, Stabilizer Charms.
  * [ ] Charm guardrails (clear effect, per-use limit).
* [ ] Engineering readiness:
  * [ ] Performance pass (mobile).
  * [ ] Error handling + retry without desync.
  * [ ] Analytics events for onboarding, core loop, logbook, shop funnel.

</details>

#### System-level gaps (specs → tasks)

These are “spec says it exists” items that weren’t represented as backlog work.

<details>

<summary><strong>Macro loop core (NOT just expansions)</strong></summary>

Sources:

* [4 - The MMO & Economy (Macro)](../game-overview/4-the-mmo-and-economy-macro.md)
* [The Bazaar (Auction House)](../game-overview/4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)
* [The Global Museum (Social Leaderboard)](../game-overview/4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)
* [Currency Systems](../game-overview/4-the-mmo-and-economy-macro/currency-systems.md)

Bazaar (core, beyond “it exists”):

* [ ] Search + filters (minimum set in Bazaar doc).
* [ ] Sorting (ending soon, low/high bid, newest).
* [ ] Anti-abuse baseline:
  * [ ] Listing caps and rate limits.
  * [ ] Bid rate limits + min increment.
  * [ ] Cancellation rules.
  * [ ] Optional anti-sniping extension.
* [ ] “Held Scrap” UX surfaces (available vs held).
* [ ] Ticker + global broadcast thresholds.

Museum (core, beyond “it exists”):

* [ ] Theme matching tags and `MATCH/OFF-THEME` UI.
* [ ] MS breakdown UI lines (sum HV, set mult, event mult).
* [ ] Anti-cheese lock rules (submit once = locked for week).

Currencies:

* [ ] Scrap ledger + bid holds (atomic).
* [ ] Vault Credits:
  * [ ] account-bound rules
  * [ ] dissolve prismatic → credits
  * [ ] shop sinks
* [ ] HI:
  * [ ] earn/spend ledger + auditability
  * [ ] “unbuyables” catalog definition (permits, titles, vault expansions, elite training)

</details>

<details>

<summary><strong>Progression + directed goals (quests + achievements)</strong></summary>

Sources:

* [6 - Progression, Quests, Achievements](../game-overview/6-progression-quests-achievements/)
* [Quest System](../game-overview/6-progression-quests-achievements/quest-system.md)
* [Achievement System](../game-overview/6-progression-quests-achievements/achievement-system.md)

Quest system:

* [ ] Quest state machine (`AVAILABLE → … → CLAIMED/EXPIRED`).
* [ ] Objective counter plumbing (server-authoritative).
* [ ] Quest board UI + tracker chip (pin up to 3).
* [ ] Rewards grant idempotency keys.
* [ ] Seed content:
  * [ ] Onboarding directives list implementation.\n Source: [Onboarding Quest List](../game-overview/6-progression-quests-achievements/quest-system/onboarding-quest-list.md)
  * [ ] Unboarding directives list implementation.\n Source: [Unboarding Quest List](../game-overview/6-progression-quests-achievements/quest-system/unboarding-quest-list.md)
* [ ] Daily directives pool + weekly contracts pool (if shipped).

Achievements:

* [ ] Achievement catalog + per-player progress records.
* [ ] Categories + unlock criteria (milestones/mastery/risk/collection/economy/prestige/legacy).
* [ ] Reward types (titles/frames/stats pages) + claim rules.
* [ ] Broadcast rules (high-signal only).

</details>

<details>

<summary><strong>RPG skilling “missing pieces”</strong></summary>

Source: [5 - RPG Skilling System](../game-overview/5-rpg-skilling-system/)

* [ ] Skill UI surfacing:
  * [ ] Per-skill XP + level progress.
  * [ ] Level 60 unlock callouts (ability + branch).
  * [ ] Level 99 mastery moment (global broadcast + badge + theme shift).
* [ ] Total Level computation + gates in UI (even before permits exist).
* [ ] Archive Rebirth (explicitly post-V1, but still needs a spec-to-build plan if kept).

</details>

#### Documentation gaps (spec holes)

These are pages that exist in TOC but are missing usable spec content.

* [ ] Fill in [OSRS-Inspired Skilling Integration](../game-overview/4-the-mmo-and-economy-macro/osrs-inspired-skilling-integration.md) (page is currently empty).
* [ ] Fill in [3. "Anomaly Overload" (The Combo Meter)](../expansion-plan/micro-loop-expansion/3.-anomaly-overload-the-combo-meter.md) (page currently has no spec content).

#### Asset gaps (art checklist → tickets)

Source: [Sprite](../assets/sprite/)

* [ ] Create sprites marked as `none` (missing art) in the checklist.
* [ ] Create icons for new currencies/materials before Phase 4/5:
  * [ ] HI, Cursed Fragment, Stabilizer Charm, Master Relic Key, Blueprint.
* [ ] Create deck icons (Field/Lab/Vault/Bazaar/Archive) and core UI glyphs.

***

### 1) Micro-loop: “active play” edges

#### Field extraction (Excavation)

Spec anchors:

* Field rules: [The Dig Site (Main Screen)](../game-overview/2-the-mechanics/the-dig-site-main-screen.md)
* Skill expansion: [Active Skill Abilities (Tactile Commands)](../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)

Backlog:

* [x] **Seismic Surge** ([1. The "Seismic Surge" (Active Extraction)](../expansion-plan/micro-loop-expansion/1.-the-seismic-surge-active-extraction.md))
  * [x] Level 99 “Endless Vein”: second Sweet Spot + 15% double-loot logic.
* [x] **Focused Survey (Lv 60+)** (defined in [Active Skill Abilities (Tactile Commands)](../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md))
  * [x] UI scanner overlay.
  * [x] 60s countdown timer.
  * [x] Scrap-per-second drain.
* [x] **Vault Heatmaps** ([6. "Vault Heatmaps" (Zone Strategy)](../expansion-plan/micro-loop-expansion/6.-vault-heatmaps-zone-strategy.md))
  * [x] “Static Intensity” UI per zone.
  * [x] Example tuning: `+2%` Crate bonus vs `-5%` Lab stability penalty.
* [x] **Survey Action (Lv 70+)** (paired with [6. "Vault Heatmaps" (Zone Strategy)](../expansion-plan/micro-loop-expansion/6.-vault-heatmaps-zone-strategy.md))
  * [x] Temporary personal mitigation for Static penalty.

#### Lab sifting (Restoration)

Spec anchors:

* Lab rules: [The Refiner (The Gambling Hub)](../game-overview/2-the-mechanics/the-refiner-the-gambling-hub.md)
* Skill expansion: [Active Skill Abilities (Tactile Commands)](../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)

Backlog:

* [x] **Active Stabilization** ([2. "Active Stabilization" (Lab Triage)](../expansion-plan/micro-loop-expansion/2.-active-stabilization-lab-triage.md))
  * [x] Level 99 “Master Preserver”: 10% base reduction in needle movement speed.
* [x] **Shatter Salvage** ([5. "Shatter Salvage" (The Reaction Beat)](../expansion-plan/micro-loop-expansion/5.-shatter-salvage-the-reaction-beat.md))
  * [x] 1-second “panic window” UI.
  * [x] “Cursed Fragment” currency: recovery logic (Stage 3+).
  * [x] Fragment Alchemist bonus: higher recovery chance at high-level failures.
* [ ] **Emergency Glue (Lv 60+)** (defined in [Active Skill Abilities (Tactile Commands)](../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md))
  * [ ] 1-second “save” window on critical fails.
  * [ ] `STABILIZED` stamp result.

#### Crate intelligence (Appraisal)

Spec anchors:

* Skill rules: [Appraisal](../game-overview/5-rpg-skilling-system/appraisal.md)
* Feature spec: [4. "Pre-Sift Appraisal" (Crate Prep)](../expansion-plan/micro-loop-expansion/4.-pre-sift-appraisal-crate-prep.md)

Backlog:

* [ ] **Pre-Sift Appraisal** ([4. "Pre-Sift Appraisal" (Crate Prep)](../expansion-plan/micro-loop-expansion/4.-pre-sift-appraisal-crate-prep.md))
  * [ ] Level 60+: reveal hidden sub-stat **keys** before deeper sifting.
  * [ ] Level 99 “The Oracle”: zone trending catalog IDs.

#### Fever mode (combo system)

Spec anchor:

* Combo layer: [3. "Anomaly Overload" (The Combo Meter)](../expansion-plan/micro-loop-expansion/3.-anomaly-overload-the-combo-meter.md)

Backlog:

* [ ] **Anomaly Overload** ([3. "Anomaly Overload" (The Combo Meter)](../expansion-plan/micro-loop-expansion/3.-anomaly-overload-the-combo-meter.md))
  * [ ] Manual trigger at full meter.
  * [ ] `+50%` extraction speed buff.
  * [ ] Stage 0 “Junk → Common” upgrade chance (`5%`).

***

### 2) RPG systems: depth + identity

#### Skill sub-specializations (Lv 60 branches)

Spec anchor:

* Branch rules: [2. Skill Sub-Specializations (The Branching Path)](../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)

Backlog:

* [ ] Specialization dashboard UI.
* [ ] Excavation branches: Deep Seeker vs Area Specialist.
* [ ] Restoration branches: Master Preserver vs Swift Handler.
* [ ] Appraisal branches: Market Maker vs Authenticator.
* [ ] Smelting branches: Fragment Alchemist vs Scrap Tycoon.

#### Mastery + synergies

Spec anchor:

* Synergy rules: [3. Cross-Skill Masteries (Synergy Unlocks)](../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md)

Backlog:

* [ ] Cross-skill masteries (`80/80`): passive synergy perks.
* [ ] Total mastery (all skills `90+`): “Senior Researcher” + Research Notes panel.
* [ ] Mastery identity:
  * [ ] Level 99 “Founder’s Seal” (Obsidian Dust effect).
  * [ ] Skill-specific mastery badges on Bazaar / Museum rows.

#### Progression + blueprints

Spec anchors:

* Progression stitching: [6 - Progression, Quests, Achievements](../game-overview/6-progression-quests-achievements/)
* Workshop progression: [The Workshop (Progression)](../game-overview/2-the-mechanics/the-workshop-progression.md)

Backlog:

* [ ] Achievement system backend tracking ([Achievement System](../game-overview/6-progression-quests-achievements/achievement-system.md)).
* [ ] Quest system contract board ([Quest System](../game-overview/6-progression-quests-achievements/quest-system.md)).
* [ ] Blueprint system:
  * [ ] find “Blueprint Fragments”.
  * [ ] Workshop “Combine” logic for legacy tools.
* [ ] Certification (Appraisal 99) (`rpc_certify_item`) ([Appraisal](../game-overview/5-rpg-skilling-system/appraisal.md)).

***

### 3) Macro-loop: MMO + economy

#### Archive + social

Spec anchors:

* Macro layer: [4 - The MMO & Economy (Macro)](../game-overview/4-the-mmo-and-economy-macro.md)
* Currency rules: [Currency Systems](../game-overview/4-the-mmo-and-economy-macro/currency-systems.md)

Backlog:

* [ ] Archive expeditions / contracts ([6. Lore Keeper Requisitions (Archive Expeditions)](../expansion-plan/macro-loop-expansion/6.-lore-keeper-requisitions-archive-expeditions.md))
  * [ ] Type A: research requisitions (item turn-ins).
  * [ ] Type B: field orders (activity requirements).
  * [ ] Type C: dossiers (narrative chains).
  * [ ] “Archive Clearance” intel buff (probability bands).
* [ ] Museum endowments ([4. Museum Endowments (Permanent Prestige)](../expansion-plan/macro-loop-expansion/4.-museum-endowments-permanent-prestige.md))
* [ ] Artifact leasing ([3. Artifact Leasing (The Rental Economy)](../expansion-plan/macro-loop-expansion/3.-artifact-leasing-the-rental-economy.md))
* [ ] Status tiers / influence gates ([2. Influence-Gated Social Tiers (and Syndicate Excavations)](../expansion-plan/macro-loop-expansion/2.-influence-gated-social-tiers-and-syndicate-excavations.md))

#### Market systems

Spec anchors:

* Core market: [The Bazaar (Auction House)](../game-overview/4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)
* Risk lane: [1. The "Counter-Bazaar" (Black Market Trading)](../expansion-plan/macro-loop-expansion/1.-the-counter-bazaar-black-market-trading.md)

Backlog:

* [ ] Counter-Bazaar lane (confiscation risks) ([1. The "Counter-Bazaar" (Black Market Trading)](../expansion-plan/macro-loop-expansion/1.-the-counter-bazaar-black-market-trading.md))
* [ ] Hype Train (Appraisal 60+) (defined in [Appraisal](../game-overview/5-rpg-skilling-system/appraisal.md))

***

### 4) UI/UX, juice + sensory feedback

Spec anchor:

* Flow + surfaces: [6 - UI/UX Wireframe & Flow](../game-overview/6-ui-ux-wireframe-and-flow.md)

Backlog:

* [ ] OSRS-style level banners.
* [ ] Skill point notifications (Workshop unread state).
* [ ] UX polish:
  * [ ] Critical failure shake/vibration.
  * [ ] Aesthetic filters: “Wasteland” (Field/Lab) vs “Oasis” (Vault/Archive).
  * [ ] Sift “hum” and “glitch” sensory cues.
* [ ] Prismatic polish (Vault effects) ([The "Shiny" Mechanic](../game-overview/3-the-loot-and-collection-schema/the-shiny-mechanic.md))

***

### Implementation sequence (recommended)

This mirrors the roadmap pages:

1. Phase 1: [Phase 1: The "Clicker" Foundation (MVP)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/vXgJqkczaUUC4axkOsrA)
2. Phase 2: [Phase 2: The "Amateur Archaeologist" (Progression)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/9CdolvIw9isrCE0LzFzC)
3. Phase 3: [Phase 3: The "Connected World" (The MMO Layer)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/4rU38xhwZ4ktq4Txw2Ib)
4. Phase 4: [Phase 4: The "High Curator" (Meta-Game)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/3uQOaWYvcOgpxH24hlV2)
5. Phase 5: [Phase 5: V1 Polish](/broken/spaces/W0NXJBdtLzebirumENnw/pages/ZdcsomiEpbMvVDZ0OJsb)

### Full documentation index (all other docs)

#### Game overview

* [Game Overview](../)
* [0 - Game Loop](../game-overview/0-game-loop.md)
* [1. The Vision & World Bible](../game-overview/1.-the-vision-and-world-bible.md)
* [2: The Mechanics](../game-overview/2-the-mechanics.md)
  * [The Dig Site (Main Screen)](../game-overview/2-the-mechanics/the-dig-site-main-screen.md)
  * [The Refiner (The Gambling Hub)](../game-overview/2-the-mechanics/the-refiner-the-gambling-hub.md)
  * [The Workshop (Progression)](../game-overview/2-the-mechanics/the-workshop-progression.md)
* [3 - The Loot & Collection Schema](../game-overview/3-the-loot-and-collection-schema.md)
  * [Sample Collection Tiers](../game-overview/3-the-loot-and-collection-schema/sample-collection-tiers.md)
  * [The "Mint & Condition" System](../game-overview/3-the-loot-and-collection-schema/the-mint-and-condition-system.md)
  * [Flavor Text & World Building](../game-overview/3-the-loot-and-collection-schema/flavor-text-and-world-building.md)
  * [The "Shiny" Mechanic](../game-overview/3-the-loot-and-collection-schema/the-shiny-mechanic.md)
* [4 - The MMO & Economy (Macro)](../game-overview/4-the-mmo-and-economy-macro.md)
  * [The Bazaar (Auction House)](../game-overview/4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)
  * [The Global Museum (Social Leaderboard)](../game-overview/4-the-mmo-and-economy-macro/the-global-museum-social-leaderboard.md)
  * [Currency Systems](../game-overview/4-the-mmo-and-economy-macro/currency-systems.md)
  * [OSRS-Inspired Skilling Integration](../game-overview/4-the-mmo-and-economy-macro/osrs-inspired-skilling-integration.md)
* [5 - RPG Skilling System](../game-overview/5-rpg-skilling-system/)
  * [Excavation](../game-overview/5-rpg-skilling-system/excavation.md)
  * [Restoration](../game-overview/5-rpg-skilling-system/restoration.md)
  * [Appraisal](../game-overview/5-rpg-skilling-system/appraisal.md)
  * [Smelting](../game-overview/5-rpg-skilling-system/smelting.md)
* [6 - Progression, Quests, Achievements](../game-overview/6-progression-quests-achievements/)
  * [Progression Pillars](../game-overview/6-progression-quests-achievements/progression-pillars/)
    * [Collection progression (sets and identity)](../game-overview/6-progression-quests-achievements/progression-pillars/collection-progression-sets-and-identity.md)
    * [Power progression (Scrap → Workshop)](../game-overview/6-progression-quests-achievements/progression-pillars/power-progression-scrap-workshop.md)
    * [Mastery progression (skills 1–99)](../game-overview/6-progression-quests-achievements/progression-pillars/mastery-progression-skills-1-99.md)
    * [Prestige progression (Museum + HI)](../game-overview/6-progression-quests-achievements/progression-pillars/prestige-progression-museum-+-hi.md)
  * [Quest System](../game-overview/6-progression-quests-achievements/quest-system.md)
    * [Onboarding Quest List](../game-overview/6-progression-quests-achievements/quest-system/onboarding-quest-list.md)
    * [Unboarding Quest List](../game-overview/6-progression-quests-achievements/quest-system/unboarding-quest-list.md)
  * [Achievement System](../game-overview/6-progression-quests-achievements/achievement-system.md)
* [6 - UI/UX Wireframe & Flow](../game-overview/6-ui-ux-wireframe-and-flow.md)

#### Implementation plan

* [Summary](summary.md)
* [Technical Framework (Vue + Supabase)](technical-framework-vue-+-supabase.md)
* [Phase 1: The "Clicker" Foundation (MVP)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/vXgJqkczaUUC4axkOsrA)
  * [Phase 1 (MVP) requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/whZFSOeTpyhQynDJUqds)
* [Phase 2: The "Amateur Archaeologist" (Progression)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/9CdolvIw9isrCE0LzFzC)
  * [Phase 2 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/3UMkX37vTIwHL0uoayLS)
* [Phase 3: The "Connected World" (The MMO Layer)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/4rU38xhwZ4ktq4Txw2Ib)
  * [Phase 3 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/GcPUD3swAP8KbhaBt30Q)
* [Phase 4: The "High Curator" (Meta-Game)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/3uQOaWYvcOgpxH24hlV2)
  * [Phase 4 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/W0goIsLgTGnXgIRcgKtm)
* [Phase 5: V1 Polish](/broken/spaces/W0NXJBdtLzebirumENnw/pages/ZdcsomiEpbMvVDZ0OJsb)
  * [Phase 5 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/CuGFgLZMnJn3FCWcFAB7)

#### Expansion plan

* [Expansion Plan](../expansion-plan/)
* Micro loop expansion: [Micro Loop Expansion](../expansion-plan/micro-loop-expansion/)
  * [1. The "Seismic Surge" (Active Extraction)](../expansion-plan/micro-loop-expansion/1.-the-seismic-surge-active-extraction.md)
  * [2. "Active Stabilization" (Lab Triage)](../expansion-plan/micro-loop-expansion/2.-active-stabilization-lab-triage.md)
  * [3. "Anomaly Overload" (The Combo Meter)](../expansion-plan/micro-loop-expansion/3.-anomaly-overload-the-combo-meter.md)
  * [4. "Pre-Sift Appraisal" (Crate Prep)](../expansion-plan/micro-loop-expansion/4.-pre-sift-appraisal-crate-prep.md)
  * [5. "Shatter Salvage" (The Reaction Beat)](../expansion-plan/micro-loop-expansion/5.-shatter-salvage-the-reaction-beat.md)
  * [6. "Vault Heatmaps" (Zone Strategy)](../expansion-plan/micro-loop-expansion/6.-vault-heatmaps-zone-strategy.md)
* Macro loop expansion: [Macro Loop Expansion](../expansion-plan/macro-loop-expansion.md)
  * [1. The "Counter-Bazaar" (Black Market Trading)](../expansion-plan/macro-loop-expansion/1.-the-counter-bazaar-black-market-trading.md)
  * [2. Influence-Gated Social Tiers (and Syndicate Excavations)](../expansion-plan/macro-loop-expansion/2.-influence-gated-social-tiers-and-syndicate-excavations.md)
  * [3. Artifact Leasing (The Rental Economy)](../expansion-plan/macro-loop-expansion/3.-artifact-leasing-the-rental-economy.md)
  * [4. Museum Endowments (Permanent Prestige)](../expansion-plan/macro-loop-expansion/4.-museum-endowments-permanent-prestige.md)
  * [5. "The Great Static" Events (incl. Static Pulses)](../expansion-plan/macro-loop-expansion/5.-the-great-static-events-incl.-static-pulses.md)
  * [6. Lore Keeper Requisitions (Archive Expeditions)](../expansion-plan/macro-loop-expansion/6.-lore-keeper-requisitions-archive-expeditions.md)
* Skills expansion: [Skills Expansion](../expansion-plan/skills-expansion.md)
  * [1. Active Skill Abilities (Tactile Commands)](../expansion-plan/skills-expansion/1.-active-skill-abilities-tactile-commands.md)
  * [2. Skill Sub-Specializations (The Branching Path)](../expansion-plan/skills-expansion/2.-skill-sub-specializations-the-branching-path.md)
  * [3. Cross-Skill Masteries (Synergy Unlocks)](../expansion-plan/skills-expansion/3.-cross-skill-masteries-synergy-unlocks.md)
  * [4. Skill-Gated "Ancient Blueprints"](../expansion-plan/skills-expansion/4.-skill-gated-ancient-blueprints.md)

#### Assets

* [Sprite](../assets/sprite/)
* [Prompts](../assets/prompts.md)
