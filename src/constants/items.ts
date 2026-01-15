export interface Item {
  id: string;
  name: string;
  tier: 'common' | 'rare';
  flavorText: string;
}

export const ITEM_CATALOG: Item[] = [
  // Common Tier (12)
  { id: 'rusty_key', name: 'Rusty Key', tier: 'common', flavorText: 'Unlocks a door that no longer exists.' },
  { id: 'ceramic_mug', name: 'Ceramic Mug', tier: 'common', flavorText: 'A vessel for brown caffeinated rituals.' },
  { id: 'aa_battery', name: 'AA Battery', tier: 'common', flavorText: 'A dead ancient power cell.' },
  { id: 'plastic_comb', name: 'Plastic Comb', tier: 'common', flavorText: 'A scalp-scraping tool of the old elite.' },
  { id: 'steel_fork', name: 'Steel Fork', tier: 'common', flavorText: 'A three-pronged food-spear.' },
  { id: 'lightbulb', name: 'Lightbulb', tier: 'common', flavorText: 'A fragile glass orb that once held lightning.' },
  { id: 'ballpoint_pen', name: 'Ballpoint Pen', tier: 'common', flavorText: 'A manual data-entry stylus (no ink).' },
  { id: 'eyeglass_frame', name: 'Eyeglass Frame', tier: 'common', flavorText: 'A visual-enhancement harness.' },
  { id: 'soda_tab', name: 'Soda Tab', tier: 'common', flavorText: 'Small aluminum currency? Purpose unknown.' },
  { id: 'safety_pin', name: 'Safety Pin', tier: 'common', flavorText: 'A primitive emergency garment fastener.' },
  { id: 'rubber_band', name: 'Rubber Band', tier: 'common', flavorText: 'High-elasticity synthetic binding.' },
  { id: 'broken_watch', name: 'Broken Watch', tier: 'common', flavorText: 'A frozen moment in a circular frame.' },

  // Rare Tier (8)
  { id: 'calculated_tablet', name: 'Calculated Tablet', tier: 'rare', flavorText: 'A solar-powered math-engine (Casio).' },
  { id: 'wrist_chronometer', name: 'Wrist Chronometer', tier: 'rare', flavorText: 'Tracks time via ticking gears.' },
  { id: 'compact_disc', name: 'Compact Disc', tier: 'rare', flavorText: 'A shimmering circle of lost music.' },
  { id: 'remote_control', name: 'Remote Control', tier: 'rare', flavorText: 'A long-range button-array for glowing boxes.' },
  { id: 'computer_mouse', name: 'Computer Mouse', tier: 'rare', flavorText: 'A handheld navigation \'rodent\'.' },
  { id: 'flashlight', name: 'Flashlight', tier: 'rare', flavorText: 'A portable photon-emitter.' },
  { id: 'headphone_set', name: 'Headphone Set', tier: 'rare', flavorText: 'Private ear-drums for personal audio.' },
  { id: 'digital_camera', name: 'Digital Camera', tier: 'rare', flavorText: 'A device that freezes light into memories.' },
  { id: 'cursed_fragment', name: 'Cursed Fragment', tier: 'rare', flavorText: 'A pulsing obsidian sliver. It feels... heavy.' },
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
  { id: 'rusty_shovel', name: 'Rusty Shovel', cost: 0, automationRate: 0, findRateBonus: 0, flavorText: 'Better than using your hands (barely).' },
  { id: 'pneumatic_pick', name: 'Pneumatic Pick', cost: 2500, automationRate: 5, findRateBonus: 0.05, flavorText: 'High-frequency vibration to shake loose the past.' },
  { id: 'ground_radar', name: 'Ground Radar', cost: 15000, automationRate: 25, findRateBonus: 0.12, flavorText: 'See through the silt with ultrasound.' },
  { id: 'industrial_drill', name: 'Industrial Drill', cost: 80000, automationRate: 100, findRateBonus: 0.18, flavorText: 'Pure mechanical force for deep extraction.' },
  { id: 'seismic_array', name: 'Seismic Array', cost: 500000, automationRate: 500, findRateBonus: 0.25, flavorText: 'Mapping the entire sector via resonance.' },
  { id: 'satellite_uplink', name: 'Satellite Uplink', cost: 2500000, automationRate: 2500, findRateBonus: 0.40, flavorText: 'Orbital scanning for tectonic-scale finds.' },
];

export interface CollectionSet {
  id: string;
  name: string;
  itemIds: string[];
  rewardScrap: number;
}

export const COLLECTION_SETS: CollectionSet[] = [
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
