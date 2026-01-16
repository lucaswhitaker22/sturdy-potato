# Power progression (Scrap → Workshop)

## Power progression (Scrap → Workshop)

Power progression is the “numbers go up” track.

It converts Scrap into permanent throughput.

Canon anchors:

* The sink itself: [The Workshop (Progression)](../../2-the-mechanics/the-workshop-progression.md)
* Scrap rules: [Currency Systems](../../4-the-mmo-and-economy-macro/currency-systems.md)
* Field output rules: [The Dig Site (Main Screen)](../../2-the-mechanics/the-dig-site-main-screen.md)

### What “power” means in Relic Vault

Power is mostly **throughput**.

It is not combat DPS.

Power shows up as:

* more Scrap per minute,
* more Crates per hour,
* more offline progress stored,
* more consistent Lab attempts via explicit modifiers.

### Scrap: sources and sinks (the loop)

Sources:

* Field extraction outcomes.\n Manual and passive.\n Canon: [The Dig Site (Main Screen)](../../2-the-mechanics/the-dig-site-main-screen.md)
* Smelting items into Scrap.\n Canon: [Smelting](../../5-rpg-skilling-system/smelting.md)
* Bazaar sales, minus tax.\n Canon: [The Bazaar (Auction House)](../../4-the-mmo-and-economy-macro/the-bazaar-auction-house.md)

Sinks:

* Workshop tool tiers and upgrades.\n Primary sink.
* Scanner Battery upgrades.\n AA cap + offline buffer sink.
* Bazaar fees.\n Deposits and tax.
* Appraisal actions.\n Certification and intel.
* Late-game sinks.\n Overclocking, endgame upgrades.

### Workshop controls (canonical)

The Workshop is the only place that should scale “account output.”

It controls:

* Tool tiers.\n Speed and crate rate surfaces.
* Automation throughput.\n Tick-based Scrap engine.
* Scanner Battery Capacity.\n AA cap + offline buffer cap.
* Overclocking.\n Late-game, reset-for-perk sink.

Full spec: [The Workshop (Progression)](../../2-the-mechanics/the-workshop-progression.md)

### Automation (the mid-game inflection)

Automation changes pacing.

It must stay readable and deterministic.

Canonical automation rules:

* Tick length is `10s`.
* Each tick awards Scrap.
* Each tick can roll a Crate drop.
* Offline time is capped by Scanner Battery Capacity.

Canon: [The Dig Site (Main Screen)](../../2-the-mechanics/the-dig-site-main-screen.md)

### Power vs RNG (hard integrity rules)

Power progression must not rewrite core RNG surfaces.

Hard rules:

* The Field’s `5%` Anomaly outcome never changes.
* The Lab stage table never changes here.
* If you add stability bonuses, show them as explicit lines.

Canon:

* Field: [The Dig Site (Main Screen)](../../2-the-mechanics/the-dig-site-main-screen.md)
* Lab: [The Refiner (The Gambling Hub)](../../2-the-mechanics/the-refiner-the-gambling-hub.md)

### Recommended pacing targets (milestones)

These are design targets, not balance promises.

#### Early (D0)

* Buy at least one Workshop upgrade.
* Unlock basic automation soon.\n It makes the game “stick.”
* Learn the tray cap rhythm.\n Extract → Lab → Vault.

#### Mid (D1–D7)

* Automation becomes the majority of Scrap.
* Scanner Battery becomes meaningful friction.\n It gates offline buffer and AA cap.
* Tool gates start referencing skill levels.\n Keeps builds relevant.

#### Late (D30+)

* Overclocking becomes the “I’m rich” sink.
* Players choose between:\n deeper Lab viability vs raw throughput.

### Telemetry (for tuning)

Track:

* Scrap earned vs spent per cohort.
* Spend split:\n tools vs upgrades vs battery vs fees vs overclocks.
* Manual vs passive Scrap share over time.
* Offline cap pressure:\n % hitting cap weekly.
* Time-to-next-tier distribution.
