# UI sprites

Core navigation icons and common controls.

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
