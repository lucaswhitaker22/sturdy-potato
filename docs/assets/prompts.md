# Prompts

## Prompts (Art + Icon Style)

This page is the shared prompt library for generating consistent art assets.

It’s referenced by the sprite checklist.

Spec anchor: [Sprite](sprite/).

***

### Base style (canonical)

Use this baseline style for **all icons and sprites**:

* Thin black ink outlines
* Watercolor fill
* Pastel colors
* White background

Avoid:

* heavy gradients
* glossy highlights
* 3D lighting
* drop shadows (unless explicitly requested)

***

### Icon prompt template (copy/paste)

Use this when generating a single icon:

> **Subject:** `<WHAT>`\n **Style:** thin black ink outlines, watercolor fill, pastel colors, white background\n **Composition:** centered, simple silhouette, readable at small size\n **Constraints:** no text, no watermark, no border, no drop shadow\n **Output:** clean PNG with transparent background (if available)

Examples:

* Subject: `rusty shovel icon`
* Subject: `encapsulated crate icon`
* Subject: `static glitch anomaly icon`

***

### Badge prompt template (small overlays)

Badges must read at tiny sizes.

> **Subject:** `<BADGE>`\n **Style:** thin black ink outlines, watercolor fill, pastel accents\n **Composition:** high-contrast simple shape, centered, minimal detail\n **Constraints:** no text, no border, no background pattern

Examples:

* Subject: `rarity badge - mythic (orange accent)`
* Subject: `certified badge (archive seal vibe)`
* Subject: `lock badge`

***

### “Wasteland” vs “Oasis” palette guidance

Keep palette consistent with the UI decks:

* **Wasteland (Field/Lab)**: dusty, muted, dirty pastels
* **Oasis (Vault/Archive)**: cleaner, brighter pastels

UI anchor: [6 - UI/UX Wireframe & Flow](../game-overview/6-ui-ux-wireframe-and-flow.md).
