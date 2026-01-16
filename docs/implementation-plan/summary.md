# Summary

This plan breaks the game into buildable phases.

Use these docs as canon:

* [1. The Vision & World Bible](../game-overview/1.-the-vision-and-world-bible.md) (terms, vibe, pillars)
* [2: The Mechanics](../game-overview/2-the-mechanics.md) (loops, odds, stage names)
* [3 - The Loot & Collection Schema](../game-overview/3-the-loot-and-collection-schema.md) (tiers, identity, HV/mint/condition)
* [4 - The MMO & Economy (Macro)](../game-overview/4-the-mmo-and-economy-macro.md) (Bazaar, tax, tri-currency)
* [5 - RPG Skilling System](../game-overview/5-rpg-skilling-system/) (OSRS XP curve, mastery perks, Total Level gates)
* [Skills Expansion](../expansion-plan/skills-expansion.md) (active abilities, specializations, cross-skill masteries, blueprints, prestige)

### Skilling gates (shared language across phases)

Use these thresholds consistently:

* Level `60+`: “advanced skilling starts” (active abilities + specialization branch pick).
* `80/80`: pair cross-skill masteries (always-on synergy perks).
* All skills `90+`: total mastery (e.g., **Senior Researcher**).
* Level `90 -> 99` for Appraisal/Smelting may be HI-gated (Phase 4).

### Phase 1 — Clicker Foundation (MVP)

Goal: ship the Field → Lab → Vault loop.

* Manual `[EXTRACT]` with a progress bar and cooldown.
* Extract outcomes align to Mechanics: Scrap / Crate / Anomaly.
* Lab supports `[CLAIM]` vs `[SIFT]`, with Shatter failures.
* A tiny starter catalog (20 items) with Archive-style flavor text.

Plan: [Phase 1: The "Clicker" Foundation (MVP)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/vXgJqkczaUUC4axkOsrA)\
Build contract: [Phase 1 (MVP) requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/whZFSOeTpyhQynDJUqds)

### Phase 2 — Progression

Goal: turn the loop into a grind with persistence.

* Skills: Excavation + Restoration.
* Workshop tools unlock passive extraction (10s tick).
* Collections (sets) grant permanent buffs.
* Supabase persistence, autosave, and offline gains (Scanner Battery cap).\n This cap also becomes the player’s AA cap once Archive Authorization ships.

Plan: [Phase 2: The "Amateur Archaeologist" (Progression)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/9CdolvIw9isrCE0LzFzC)\
Build contract: [Phase 2 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/3UMkX37vTIwHL0uoayLS)

### Phase 3 — MMO layer

Goal: make it connected and server-authoritative.

* Global Activity Feed (Supabase Realtime).
* Bazaar auctions.
* Minting (global serial numbers per catalog item).
* Server authority for RNG and currency writes.

Economy canon:

* Scrap is the Phase 1–3 economy currency.
* Historical Influence (HI) becomes relevant in Phase 4.
* Vault Credits (premium) is Phase 5+.

Plan: [Phase 3: The "Connected World" (The MMO Layer)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/4rU38xhwZ4ktq4Txw2Ib)\
Build contract: [Phase 3 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/GcPUD3swAP8KbhaBt30Q)

### Phase 4 — Meta-game

Goal: ship the Archive loops.

* Museum, Historical Influence, world events.
* Advanced skills (Appraisal + Smelting).
* Advanced skilling layer:\n active abilities + specialization branches + cross-skill masteries.

Plan: [Phase 4: The "High Curator" (Meta-Game)](/broken/spaces/W0NXJBdtLzebirumENnw/pages/3uQOaWYvcOgpxH24hlV2)\
Build contract: [Phase 4 requirements](/broken/spaces/W0NXJBdtLzebirumENnw/pages/W0goIsLgTGnXgIRcgKtm)

### Phase 5 — V1 polish

Goal: polish the feel, add retention + monetization basics, and ship.

Plan: [Phase 5: V1 Polish](/broken/spaces/W0NXJBdtLzebirumENnw/pages/ZdcsomiEpbMvVDZ0OJsb)

### Post-V1 (future): Archive Rebirth

Archive Rebirth is optional prestige.\n It resets a skill for ribbons + tiny permanent perks.\n It is intentionally not required for V1 scope.
