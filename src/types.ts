// Core Realm Item Types

export type ItemTier = 'junk' | 'common' | 'uncommon' | 'rare' | 'epic' | 'mythic' | 'unique';

export type ItemCondition = 'wrecked' | 'weathered' | 'preserved' | 'mint';

export interface ItemDefinition {
    id: string;
    name: string;
    tier: ItemTier;
    base_hv: number;
    flavor_text: string;
}

export interface VaultItem {
    id: string; // UUID of the ownership record
    item_id: string; // ID of the definition
    mint_number: number;
    condition: ItemCondition;
    is_prismatic: boolean;
    historical_value: number;
    discovered_at: string; // ISO Date
    
    // Joined fields (if we fetch with join, or we map them)
    item?: ItemDefinition; 
    
    // For legacy support until migration is fully run
    name?: string; 
    flavorText?: string;
    tier?: ItemTier;
}

export interface CollectionSet {
    id: string;
    name: string;
    description: string;
    required_item_ids: string[];
    bonus_type: string;
    bonus_value: number;
}
