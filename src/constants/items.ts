export interface Item {
  id: string;
  name: string;
  tier: 'common' | 'rare';
  flavorText: string;
}

export const ITEM_CATALOG: Item[] = [
  // Common Tier (12)
  { id: 'dull_kitchen_knife', name: 'Dull Kitchen Knife', tier: 'common', flavorText: 'A primitive steak-searing blade.' },
  { id: 'ceramic_mug', name: 'Ceramic Mug', tier: 'common', flavorText: 'A vessel for brown caffeinated rituals.' },
  { id: 'aa_battery', name: 'AA Battery', tier: 'common', flavorText: 'A dead ancient power cell.' },
  { id: 'plastic_comb', name: 'Plastic Comb', tier: 'common', flavorText: 'A scalp-scraping tool of the old elite.' },
  { id: 'steel_fork', name: 'Steel Fork', tier: 'common', flavorText: 'A three-pronged food-spear.' },
  { id: 'lightbulb', name: 'Lightbulb', tier: 'common', flavorText: 'A fragile glass orb that once held lightning.' },
  { id: 'ballpoint_pen', name: 'Ballpoint Pen', tier: 'common', flavorText: 'A manual data-entry stylus (no ink).' },
  { id: 'rusty_key', name: 'Rusty Key', tier: 'common', flavorText: 'Unlocks a door that no longer exists.' },
  { id: 'eyeglass_frame', name: 'Eyeglass Frame', tier: 'common', flavorText: 'A visual-enhancement harness.' },
  { id: 'soda_tab', name: 'Soda Tab', tier: 'common', flavorText: 'Small aluminum currency? Purpose unknown.' },
  { id: 'safety_pin', name: 'Safety Pin', tier: 'common', flavorText: 'A primitive emergency garment fastener.' },
  { id: 'rubber_band', name: 'Rubber Band', tier: 'common', flavorText: 'High-elasticity synthetic binding.' },
  { id: 'rusty_toaster', name: 'Rusty Toaster', tier: 'common', flavorText: 'A spring-loaded bread warmer.' },
  { id: 'spoon', name: 'Spoon', tier: 'common', flavorText: 'A shallow scoop for liquid consumption.' },

  // Rare Tier (8)
  { id: 'calculated_tablet', name: 'Calculated Tablet', tier: 'rare', flavorText: 'A solar-powered math-engine (Casio).' },
  { id: 'wrist_chronometer', name: 'Wrist Chronometer', tier: 'rare', flavorText: 'Tracks time via ticking gears.' },
  { id: 'compact_disc', name: 'Compact Disc', tier: 'rare', flavorText: 'A shimmering circle of lost music.' },
  { id: 'remote_control', name: 'Remote Control', tier: 'rare', flavorText: 'A long-range button-array for glowing boxes.' },
  { id: 'computer_mouse', name: 'Computer Mouse', tier: 'rare', flavorText: 'A handheld navigation \'rodent\'.' },
  { id: 'flashlight', name: 'Flashlight', tier: 'rare', flavorText: 'A portable photon-emitter.' },
  { id: 'headphone_set', name: 'Headphone Set', tier: 'rare', flavorText: 'Private ear-drums for personal audio.' },
  { id: 'digital_camera', name: 'Digital Camera', tier: 'rare', flavorText: 'A device that freezes light into memories.' },
];

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
