# Summary

This plan breaks the game into buildable phases.

Use these docs as canon:

* [1. The Vision & World Bible](../game-overview/1.-the-vision-and-world-bible.md) (terms, vibe, pillars)
* [2: The Mechanics](../game-overview/2-the-mechanics.md) (loops, odds, stage names)
* [3 - The Loot & Collection Schema](../game-overview/3-the-loot-and-collection-schema.md) (tiers, identity, HV/mint/condition)
* [4 - The MMO & Economy (Macro)](../game-overview/4-the-mmo-and-economy-macro.md) (Bazaar, tax, tri-currency)
* [5 - RPG Skilling System](../game-overview/5-rpg-skilling-system.md) (OSRS XP curve, mastery perks, Total Level gates)

### Phase 1 — Clicker Foundation (MVP)

Goal: ship the Field → Lab → Vault loop.

* Manual `[EXTRACT]` with a progress bar and cooldown.
* Extract outcomes align to Mechanics: Scrap / Crate / Anomaly.
* Lab supports `[CLAIM]` vs `[SIFT]`, with Shatter failures.
* A tiny starter catalog (20 items) with Archive-style flavor text.

Plan: [Phase 1: The "Clicker" Foundation (MVP)](phase-1-the-clicker-foundation-mvp/)\
Build contract: [Phase 1 (MVP) requirements](phase-1-the-clicker-foundation-mvp/phase-1-mvp-requirements.md)

### Phase 2 — Progression

Goal: turn the loop into a grind with persistence.

* Skills: Excavation + Restoration.
* Workshop tools unlock passive extraction (10s tick).
* Collections (sets) grant permanent buffs.
* Supabase persistence, autosave, and offline gains (Battery Capacity cap).

Plan: [Phase 2: The "Amateur Archaeologist" (Progression)](phase-2-the-amateur-archaeologist-progression/)\
Build contract: [Phase 2 requirements](phase-2-the-amateur-archaeologist-progression/phase-2-requirements.md)

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

Plan: [Phase 3: The "Connected World" (The MMO Layer)](phase-3-the-connected-world-the-mmo-layer/)\
Build contract: [Phase 3 requirements](phase-3-the-connected-world-the-mmo-layer/phase-3-requirements.md)

### Phase 4 — Meta-game

Goal: ship the Archive loops.

* Museum, Historical Influence, world events.
* Advanced skills (Appraisal + Smelting).

Plan: [Phase 4: The "High Curator" (Meta-Game)](phase-4-the-high-curator-meta-game/)\
Build contract: [Phase 4 requirements](phase-4-the-high-curator-meta-game/phase-4-requirements.md)

### Phase 5 — V1 polish

Goal: polish the feel, add retention + monetization basics, and ship.

Plan: [Phase 5: V1 Polish](phase-5-v1-polish/)
