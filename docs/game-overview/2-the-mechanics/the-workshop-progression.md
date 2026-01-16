# The Workshop (Progression)

## The Workshop (Progression)

The Workshop is the primary **Scrap sink**.

It converts short-term Scrap into long-term efficiency.

This page is the canonical spec for tools, automation, and overclocking.

Related:

* Loop context: [0 - Game Loop](../0-game-loop.md)
* Field output this powers: [The Dig Site (Main Screen)](the-dig-site-main-screen.md)
* AA system spec: [Archive Authorization (AA) System Spec](../archive-authorization-aa-system-spec.md)
* Skill gates and scaling: [Excavation](../5-rpg-skilling-system/excavation.md)
* Currency rules: [Currency Systems](../4-the-mmo-and-economy-macro/currency-systems.md)

***

### Goals

This screen must:

* Give players a clear “next upgrade.”
* Scale power smoothly for months.
* Create meaningful choices (speed vs capacity vs risk support).
* Keep progression grindable without premium spend.

***

### What the Workshop controls

#### Permanent-ish progression (account power)

* Tool tiers and upgrades (core).
* Scanner Battery Capacity (AA cap + offline buffer cap).
* Extraction Power (passive throughput).

#### What it must NOT control

* The Field’s immutable `5%` Anomaly roll.
* The Lab’s stage table.\n It may only apply explicit, documented modifiers.

Spec anchors:

* Field odds: [The Dig Site (Main Screen)](the-dig-site-main-screen.md)
* Lab odds: [The Refiner (The Gambling Hub)](the-refiner-the-gambling-hub.md)

***

### Tool tiers (baseline table)

Tools define:

* Manual feel (survey speed / cooldown).
* Passive output (Scrap/sec via ticks).
* Crate find rates.

Baseline examples (tuning knobs):

| Tool name        | Type   | Crate find rate | Automation (Scrap/sec) | Level req | Scrap cost  |
| ---------------- | ------ | --------------- | ---------------------- | --------- | ----------- |
| Rusty Shovel     | Manual | 5%              | 0                      | 1         | 0 (Starter) |
| Pneumatic Pick   | Hybrid | 8%              | 5                      | 5         | 2,500       |
| Ground Radar     | Auto   | 12%             | 25                     | 15        | 15,000      |
| Industrial Drill | Auto   | 18%             | 100                    | 30        | 80,000      |
| Seismic Array    | Auto   | 25%             | 500                    | 50        | 500,000     |
| Satellite Uplink | Global | 40%             | 2,500                  | 80        | 2,500,000   |

Definitions:

* **Manual**: only affects manual extracts.
* **Hybrid**: boosts manual and enables some passive ticks.
* **Auto**: main passive engine.
* **Global**: unlocks deeper zones and advanced modifiers.

{% hint style="info" %}
Treat the table as “design intent,” not final balance.\n The important part is the curve and gating.\n Costs must grow exponentially.
{% endhint %}

***

### Automation model (canonical)

Workshop upgrades drive passive extraction.

Automation runs on the same tick rules described in the Field spec.

Baseline:

* Tick length: `10s`
* Each tick:
  * awards Scrap based on Extraction Power,
  * rolls Crate chance using passive stats.
* Offline gains are capped by Scanner Battery Capacity (offline buffer).

See: [The Dig Site (Main Screen)](the-dig-site-main-screen.md).

***

### Upgrade curve (cost scaling)

Tool upgrades must scale exponentially.

Suggested formula:

$$Cost = Base\\_Cost \\times 1.5^{Level}$$

Rules:

* Costs must be deterministic.
* Costs must be visible before purchase.
* Purchases are server-authoritative.

***

### Overclocking (tool-based “soft prestige”)

Overclocking is a late-game sink.

It trades short-term efficiency for permanent advantage.

#### When it becomes available

* Only after a tool reaches “Max Efficiency.”
* “Max Efficiency” is a tuning knob.\n It can be a tool-level cap.

#### The trade

* Overclocking resets that tool’s upgrade level back to `1`.
* The player must re-invest Scrap to rebuild it.

#### The reward (baseline)

* Grants a permanent `+5%` multiplier to Lab **Sift** success rate.

Recommended stacking rule:

* Apply as a multiplier to computed Stability:\n `finalStability = baseStability * (1 + 0.05 * overclocks)`
* Clamp to a sane ceiling (e.g., `≤ 95%`), if needed.

{% hint style="warning" %}
Overclocking must not make Stage 5 feel “solved.”\n Preserve risk at the top.\n Use clamps if required.
{% endhint %}

This is separate from the optional skilling prestige (“Archive Rebirth”).

See: [Skills Expansion](../../expansion-plan/skills-expansion.md).

***

### UI layout (recommended)

#### Primary components

* Tool list with locked tiers.
* Selected tool detail panel:
  * current level,
  * next upgrade effect,
  * cost,
  * requirements.
* Scanner Battery panel:
  * current AA cap,
  * current offline buffer cap,
  * next cap upgrade cost.
* Overclock panel (late-game):
  * warning copy,
  * reset preview,
  * permanent reward preview.

#### UX rules

* “Buy” buttons stay disabled until:
  * Scrap cost is met, and
  * level requirement is met.
* Purchases must have heavy feedback:
  * thunk sound,
  * screen shake (light),
  * clear delta display.

***

### Balance and sinks

The Workshop is the main place Scrap leaves the economy.

It must scale with player wealth.

Recommended sinks:

* New tool tiers (big spikes).
* Tool upgrade levels (steady drain).
* Scanner Battery upgrades (mid-game friction).\n This scales AA cap and offline buffer together.
* Overclocking (late-game drain).

If Scrap inflation rises, adjust:

* upgrade cost multipliers,
* overclock reset depth,
* battery pricing curve.

Avoid:

* stealth nerfs to drop odds,
* hidden taxes in the Workshop UI.

***

### System integrity notes

Keep these rules aligned everywhere:

* The Field’s `5%` Anomaly roll never changes.
* Workshop may increase Crate chance.\n It must still obey the Field clamp rules.
* Overclocking affects Lab stability only via an explicit multiplier.

See:

* Field invariants: [The Dig Site (Main Screen)](the-dig-site-main-screen.md)
* Lab invariants: [The Refiner (The Gambling Hub)](the-refiner-the-gambling-hub.md)

***

### Telemetry (for tuning)

Track:

* Scrap spent per category:
  * tool purchases,
  * tool upgrades,
  * scanner battery upgrades,
  * overclocks.
* Time-to-next-tier per cohort (D1/D7/D30).
* Automation share:
  * % Scrap from passive ticks vs manual extracts.
* Battery pressure:
  * % of players hitting the offline buffer cap per day.
* Overclock adoption:
  * overclocks per player,
  * stability multiplier distribution.
