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
];
