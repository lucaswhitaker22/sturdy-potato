/**
 * @deprecated Use `store.catalog` which is sourced from the `item_definitions` database table.
 * This file is kept only for type reference during migration.
 */
export interface Item {
  id: string;
  name: string;
  tier: 'common' | 'rare' | 'mythic' | 'unique' | 'epic' | 'junk';
  flavorText: string;
}

/**
 * @deprecated Use database source.
 */
export const ITEM_CATALOG: Item[] = [];
export interface Tool {
  id: string;
  name: string;
  cost: number;
  automationRate: number; // Scrap per second
  findRateBonus: number; // Percentage increase in crate drops
  flavorText: string;
}

export const TOOL_CATALOG: Tool[] = [
  { id: 'rusty_shovel', name: 'Rusty Shovel', cost: 250, automationRate: 0, findRateBonus: 0, flavorText: 'Better than using your hands (barely).' },
  { id: 'pneumatic_pick', name: 'Pneumatic Pick', cost: 2500, automationRate: 5, findRateBonus: 0.05, flavorText: 'High-frequency vibration to shake loose the past.' },
  { id: 'ground_radar', name: 'Ground Radar', cost: 15000, automationRate: 25, findRateBonus: 0.12, flavorText: 'See through the silt with ultrasound.' },
  { id: 'industrial_drill', name: 'Industrial Drill', cost: 80000, automationRate: 100, findRateBonus: 0.18, flavorText: 'Pure mechanical force for deep extraction.' },
];

export interface CollectionSet {
  id: string;
  name: string;
  itemIds: string[];
  rewardScrap: number;
}

export const COLLECTION_SETS: CollectionSet[] = [
  {
    id: 'morning_ritual',
    name: 'The Morning Ritual',
    itemIds: ['ceramic_mug', 'rusty_toaster', 'spoon'],
    rewardScrap: 0, // Incentive is buff (Caffeine Rush)
  },
  {
    id: 'basic_electronics',
    name: 'Dead Tech',
    itemIds: ['aa_battery', 'lightbulb', 'calculated_tablet'],
    rewardScrap: 100,
  },
  {
    id: 'ancient_dining',
    name: 'Ancient Dining',
    itemIds: ['ceramic_mug', 'steel_fork', 'soda_tab'],
    rewardScrap: 150,
  },
  {
    id: 'analog_tech',
    name: 'Analog Survivors',
    itemIds: ['broken_watch', 'wrist_chronometer', 'compact_disc'],
    rewardScrap: 500,
  }
];
