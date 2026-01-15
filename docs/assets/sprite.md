# Sprite

This is the sprite checklist for everything the game needs right now.

It pulls from the current design docs.

Use this as the source of truth for what art must exist.

For the base art style prompt, see [Prompts](prompts.md).

### Conventions

Keep keys stable. Treat them like API.

Use `kebab-case` and a prefix:

* `ui-*` for interface
* `badge-*` for small overlays
* `currency-*` / `material-*`
* `tool-*`
* `zone-*`
* `item-*` for relic catalog icons

Variants go in `Variants / states`.

Example: `badge-rarity-rare` + `badge-rarity-rare--glow`.

***

### UI sprites (core navigation + common controls)

| Key                    | Sprite                | Variants / states                | Used in              | Phase | Notes                              |
| ---------------------- | --------------------- | -------------------------------- | -------------------- | ----- | ---------------------------------- |
| `ui-deck-field`        | Deck icon: Field      | default / active                 | Command bar          | 1+    | `[01] THE FIELD` tab icon.         |
| `ui-deck-lab`          | Deck icon: Lab        | default / active                 | Command bar          | 1+    | `[02] THE LAB` tab icon.           |
| `ui-deck-vault`        | Deck icon: Vault      | default / active                 | Command bar          | 1+    | `[03] THE VAULT` tab icon.         |
| `ui-deck-bazaar`       | Deck icon: Bazaar     | default / active                 | Command bar          | 3+    | `[04] THE BAZAAR` tab icon.        |
| `ui-deck-archive`      | Deck icon: Archive    | default / active                 | Command bar          | 4+    | `[05] ARCHIVE` tab icon.           |
| `ui-button-extract`    | Button glyph: EXTRACT | ready / cooldown / disabled      | Field primary action | 1+    | Large “weathered” button feel.     |
| `ui-button-claim`      | Button glyph: CLAIM   | ready / disabled                 | Lab                  | 1+    | Safe action. Green/amber state.    |
| `ui-button-sift`       | Button glyph: SIFT    | stage-1…stage-5 risk intensities | Lab                  | 1+    | Deep red. Stronger glow per stage. |
| `ui-icon-settings`     | Settings icon         | default                          | Header / menu        | 1+    | Optional but expected.             |
| `ui-icon-close`        | Close icon            | default                          | Modals               | 1+    | Used across the game.              |
| `ui-icon-info`         | Info icon             | default / hover                  | Tooltips             | 1+    | For score breakdowns, odds, etc.   |
| `ui-icon-lock`         | Lock icon             | default                          | Museum item lock     | 4+    | Indicates “Locked for Museum”.     |
| `ui-icon-notification` | Notification bell/dot | dot / ping                       | Feed + alerts        | 3+    | Outbid, sold, mastery, etc.        |
| `ui-icon-feed`         | Global feed icon      | default                          | Global ticker        | 3+    | Single-line ticker marker.         |

***

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

***

### Currencies and materials

| Key                             | Sprite                      | Variants / states | Used in                      | Phase | Notes                      |
| ------------------------------- | --------------------------- | ----------------- | ---------------------------- | ----- | -------------------------- |
| `currency-scrap`                | Scrap icon                  | small / large     | HUD, rewards, costs          | 1+    | Soft currency.             |
| `currency-vault-credits`        | Vault Credits icon          | small / large     | Bazaar + premium systems     | 3+    | Premium currency.          |
| `currency-historical-influence` | HI icon                     | small / large     | Archive + Influence shop     | 4+    | Non-tradable.              |
| `material-fine-dust`            | Fine Dust icon              | default           | Shatter rewards              | 2+    | Common shatter output.     |
| `material-cursed-fragment`      | Cursed Fragment icon        | default           | High-tier shatter / crafting | 4+    | Rare. 1% hook.             |
| `material-stabilizer-charm`     | Stabilizer Charm icon       | default           | Lab safety consumable        | 4+    | Craft or shop later.       |
| `item-master-relic-key`         | Master Relic Key icon       | default           | Museum rewards               | 4+    | Unique reward token.       |
| `item-unidentified-blueprint`   | Unidentified Blueprint icon | default           | Excavation mastery drops     | 4+    | Mentioned as economy hook. |

***

### Crates, Lab actions, and failure states

| Key                         | Sprite                           | Variants / states  | Used in           | Phase | Notes                                 |
| --------------------------- | -------------------------------- | ------------------ | ----------------- | ----- | ------------------------------------- |
| `ui-crate-encapsulated`     | Encapsulated Crate icon          | default / selected | Tray + Lab        | 1+    | Core inventory object.                |
| `ui-crate-golden`           | Golden Crate icon                | default / glow     | Daily rewards     | 5+    | Guaranteed Rare+ per roadmap.         |
| `ui-action-raw-open`        | Lab action icon: Raw Open        | default            | Lab stage 0       | 1+    | Optional, but helps readability.      |
| `ui-action-surface-brush`   | Lab action icon: Surface Brush   | default            | Lab stage 1       | 1+    |                                       |
| `ui-action-chemical-wash`   | Lab action icon: Chemical Wash   | default            | Lab stage 2       | 1+    |                                       |
| `ui-action-sonic-vibration` | Lab action icon: Sonic Vibration | default            | Lab stage 3       | 1+    |                                       |
| `ui-action-molecular-scan`  | Lab action icon: Molecular Scan  | default            | Lab stage 4       | 1+    |                                       |
| `ui-action-quantum-reveal`  | Lab action icon: Quantum Reveal  | default            | Lab stage 5       | 1+    |                                       |
| `ui-state-shatter`          | Shatter icon                     | default            | Lab failure + log | 1+    | Pairs with glitch beat + glass break. |
| `ui-gauge-stability-needle` | Stability gauge needle           | default            | Lab               | 1+    | Can be vector, but track as asset.    |
| `ui-gauge-stability-face`   | Stability gauge face             | default            | Lab               | 1+    | Dial background.                      |

***

### Skills and progression UI

| Key                  | Sprite                  | Variants / states        | Used in           | Phase | Notes                          |
| -------------------- | ----------------------- | ------------------------ | ----------------- | ----- | ------------------------------ |
| `skill-excavation`   | Skill icon: Excavation  | default / glow / mastery | Vault skill hub   | 2+    | OSRS-like.                     |
| `skill-restoration`  | Skill icon: Restoration | default / glow / mastery | Vault skill hub   | 2+    |                                |
| `skill-appraisal`    | Skill icon: Appraisal   | default / glow / mastery | Vault skill hub   | 4+    | Unlocks certification.         |
| `skill-smelting`     | Skill icon: Smelting    | default / glow / mastery | Vault skill hub   | 4+    | Auto-smelt.                    |
| `badge-mastery-99`   | Level 99 mastery badge  | per skill                | HUD + leaderboard | 4+    | Shows in Bazaar + Museum rows. |
| `ui-banner-level-up` | Level-up banner motif   | default                  | Level-up beat     | 2+    | “LEVEL 40 … REACHED.”          |

***

### Tools (Workshop equipment icons)

| Key                     | Sprite                      | Variants / states      | Used in             | Phase | Notes                   |
| ----------------------- | --------------------------- | ---------------------- | ------------------- | ----- | ----------------------- |
| `tool-rusty-shovel`     | Tool icon: Rusty Shovel     | default                | Workshop + equipped | 2+    | Starter tool.           |
| `tool-pneumatic-pick`   | Tool icon: Pneumatic Pick   | default                | Workshop + equipped | 2+    | Hybrid.                 |
| `tool-ground-radar`     | Tool icon: Ground Radar     | default                | Workshop + equipped | 2+    | Auto.                   |
| `tool-industrial-drill` | Tool icon: Industrial Drill | default                | Workshop + equipped | 2+    | Auto.                   |
| `tool-seismic-array`    | Tool icon: Seismic Array    | default                | Workshop + equipped | 2+    | Auto.                   |
| `tool-satellite-uplink` | Tool icon: Satellite Uplink | default                | Workshop + equipped | 2+    | Global.                 |
| `ui-icon-battery`       | Battery capacity icon       | empty / partial / full | Offline gains       | 2+    | Mentioned in mechanics. |

***

### Zones / dig sites

| Key                       | Sprite                            | Variants / states | Used in              | Phase | Notes                                            |
| ------------------------- | --------------------------------- | ----------------- | -------------------- | ----- | ------------------------------------------------ |
| `zone-rusty-suburbs`      | Zone icon: Rusty Suburbs          | default           | Field zone selector  | 2+    | Named in UI example (“Found in: Rusty Suburbs”). |
| `zone-dusty-suburbs`      | Zone icon: Dusty Suburbs          | default           | Field backgrounds    | 5+    | Mentioned as vibe example.                       |
| `zone-sunken-mall`        | Zone icon: The Sunken Mall        | default           | Field (permit gated) | 4+    | HI permit zone.                                  |
| `zone-corporate-archive`  | Zone icon: The Corporate Archive  | default           | Field (permit gated) | 4+    | HI permit zone.                                  |
| `zone-sovereign-vault`    | Zone icon: The Sovereign Vault    | default           | Field (permit gated) | 4+    | HI permit zone.                                  |
| `zone-sunken-data-center` | Zone icon: The Sunken Data Center | default           | Expansion / macro    | 4+    | Mentioned in macro doc.                          |

***

### Relic item icons (catalog)

These are the current named relics across the docs.

Treat this list as “must have an icon” once the item is in a drop table.

#### MVP “Starter 20” (Phase 1)

| Key                       | Item name          | Tier (current) | Variants / states                        |
| ------------------------- | ------------------ | -------------- | ---------------------------------------- |
| `item-dull-kitchen-knife` | Dull Kitchen Knife | Common         | ![](<../.gitbook/assets/image (9).png>)  |
| `item-ceramic-mug`        | Ceramic Mug        | Common         | ![](<../.gitbook/assets/image (8).png>)  |
| `item-aa-battery`         | AA Battery         | Common         | ![](<../.gitbook/assets/image (10).png>) |
| `item-plastic-comb`       | Plastic Comb       | Common         | ![](<../.gitbook/assets/image (11).png>) |
| `item-steel-fork`         | Steel Fork         | Common         | ![](<../.gitbook/assets/image (12).png>) |
| `item-lightbulb`          | Lightbulb          | Common         | ![](<../.gitbook/assets/image (13).png>) |
| `item-ballpoint-pen`      | Ballpoint Pen      | Common         | ![](<../.gitbook/assets/image (14).png>) |
| `item-rusty-key`          | Rusty Key          | Common         | ![](<../.gitbook/assets/image (15).png>) |
| `item-eyeglass-frame`     | Eyeglass Frame     | Common         | ![](<../.gitbook/assets/image (16).png>) |
| `item-soda-tab`           | Soda Tab           | Common         | ![](<../.gitbook/assets/image (17).png>) |
| `item-safety-pin`         | Safety Pin         | Common         | ![](<../.gitbook/assets/image (18).png>) |
| `item-rubber-band`        | Rubber Band        | Common         | ![](<../.gitbook/assets/image (19).png>) |
| `item-calculated-tablet`  | Calculated Tablet  | Rare           | ![](<../.gitbook/assets/image (21).png>) |
| `item-wrist-chronometer`  | Wrist Chronometer  | Rare           | ![](<../.gitbook/assets/image (23).png>) |
| `item-compact-disc`       | Compact Disc       | Rare           | none                                     |
| `item-remote-control`     | Remote Control     | Rare           | none                                     |
| `item-computer-mouse`     | Computer Mouse     | Rare           | none                                     |
| `item-flashlight`         | Flashlight         | Rare           | none                                     |
| `item-headphone-set`      | Headphone Set      | Rare           | none                                     |
| `item-digital-camera`     | Digital Camera     | Rare           | none                                     |

#### Additional named relics (sets, examples, and economy beats)

| Key                            | Item name                    | Tier (current) | Variants / states | Notes                                                   |
| ------------------------------ | ---------------------------- | -------------- | ----------------- | ------------------------------------------------------- |
| `item-rusty-toaster`           | Rusty Toaster                | Common         | none              | ![](<../.gitbook/assets/image (6).png>)                 |
| `item-silicone-spatula`        | Silicone Spatula             | Common         | none              | Collection set example.                                 |
| `item-manual-can-opener`       | Manual Can Opener            | Common         | none              | Collection set example.                                 |
| `item-spoon`                   | Spoon                        | Common         | none              | Collection set example.                                 |
| `item-crt-monitor`             | CRT Monitor                  | Rare+          | none              | “Digital Dark Age” set.                                 |
| `item-mechanical-keyboard`     | Mechanical Keyboard          | Rare+          | none              | “Digital Dark Age” set.                                 |
| `item-floppy-disk-3-5`         | Floppy Disk (3.5")           | Rare+          | none              | “Digital Dark Age” set.                                 |
| `item-wired-mouse`             | Wired Mouse                  | Rare+          | none              | “Digital Dark Age” set. Distinct from Starter 20 mouse. |
| `item-diamond-tennis-bracelet` | Diamond Tennis Bracelet      | Mythic         | none              | Luxury set example.                                     |
| `item-silk-necktie`            | Silk Necktie                 | Epic+          | none              | Luxury set example.                                     |
| `item-gold-plated-lighter`     | Gold-Plated Lighter          | Epic+          | none              | Luxury set example.                                     |
| `item-designer-perfume-bottle` | Designer Perfume Bottle      | Epic+          | none              | Luxury set example.                                     |
| `item-paper-coffee-cup`        | Paper Coffee Cup (Starbucks) | Common         | none              | Flavor example.                                         |
| `item-usb-flash-drive-2gb`     | USB Flash Drive (2GB)        | Rare+          | none              | Flavor example.                                         |
| `item-plastic-fidget-spinner`  | Plastic Fidget Spinner       | Uncommon+      | none              | Flavor example.                                         |
| `item-standard-fork`           | Standard Fork                | Common         | none              | Flavor example.                                         |
| `item-walkman`                 | Walkman                      | Rare+          | none              | Minting example.                                        |
| `item-old-world-smartphone`    | Old World Smartphone         | Epic+          | none              | Prismatic + feed example.                               |
| `item-vintage-gameboy`         | Vintage GameBoy              | Epic+          | none              | Bazaar sale example.                                    |
| `item-designer-bag`            | Designer Bag                 | Epic           | none              | Rarity example (“Designer bags”).                       |

{% hint style="info" %}
If you add a new named relic anywhere in the docs, add a row here too. This is how we avoid “design says it exists” but art has no ticket.
{% endhint %}
