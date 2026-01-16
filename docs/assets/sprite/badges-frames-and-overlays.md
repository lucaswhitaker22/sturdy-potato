# Badges, frames, and overlays

Loot identity and item-card decoration.

### Badges, frames, and overlays (loot identity)

| Key                         | Sprite                             | Variants / states | Used in                    | Phase | Notes                          |
| --------------------------- | ---------------------------------- | ----------------- | -------------------------- | ----- | ------------------------------ |
| `badge-rarity-junk`         | Rarity badge: Junk                 | flat              | Item cards                 | 1+    | Grey.                          |
| `badge-rarity-common`       | Rarity badge: Common               | flat              | Item cards                 | 1+    | White.                         |
| `badge-rarity-uncommon`     | Rarity badge: Uncommon             | flat              | Item cards                 | 2+    | Green.                         |
| `badge-rarity-rare`         | Rarity badge: Rare                 | flat / glow       | Item cards + feed gates    | 1+    | Blue.                          |
| `badge-rarity-epic`         | Rarity badge: Epic                 | flat / glow       | Item cards + feed gates    | 2+    | Purple.                        |
| `badge-rarity-mythic`       | Rarity badge: Mythic               | flat / glow       | Item cards                 | 2+    | Orange.                        |
| `badge-rarity-unique`       | Rarity badge: Unique               | flat / glow       | Item cards + announcements | 3+    | Red/glow.                      |
| `badge-condition-wrecked`   | Condition stamp: Wasteland Wrecked | stamp             | Item cards                 | 2+    | `0.5x`.                        |
| `badge-condition-weathered` | Condition stamp: Weathered         | stamp             | Item cards                 | 2+    | `1.0x`.                        |
| `badge-condition-preserved` | Condition stamp: Preserved         | stamp             | Item cards                 | 2+    | `1.5x`.                        |
| `badge-condition-mint`      | Condition stamp: Mint Condition    | stamp / foil      | Item cards                 | 2+    | `2.5x`.                        |
| `badge-mint-low`            | “Low Mint” badge                   | `#001–#010`       | Item cards + Bazaar        | 3+    | Shows `+50%` prestige.         |
| `badge-certified`           | Certified badge                    | default           | Bazaar listings            | 4+    | Appraisal skill tie-in.        |
| `overlay-prismatic`         | Prismatic overlay                  | animated gradient | Item frame                 | 5+    | Rainbow border + reveal burst. |
| `frame-item-card`           | Item card frame                    | by rarity tier    | Vault / Bazaar / Museum    | 1+    | Can be one sprite + tint.      |
