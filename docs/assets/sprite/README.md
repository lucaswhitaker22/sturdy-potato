# Sprite

This is the sprite checklist for everything the game needs right now.

It pulls from the current design docs.

Use this as the source of truth for what art must exist.

For the base art style prompt, see [Prompts](../prompts.md).

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

### Checklist sections

Use these section pages as the working checklist:

* [UI sprites](ui-sprites.md)
* [Badges, frames, and overlays](badges-frames-and-overlays.md)
* [Currencies and materials](currencies-and-materials.md)
* [Crates, Lab actions, and failure states](crates-lab-actions-and-failure-states.md)
* [Skills and progression UI](skills-and-progression-ui.md)
* [Tools (Workshop equipment icons)](tools-workshop-equipment-icons.md)
* [Zones and dig sites](zones-and-dig-sites.md)
* [Relic item icons (catalog)](relic-item-icons-catalog.md)

If a design doc names a new sprite, add it to the right section. Keep the key stable once referenced anywhere.
