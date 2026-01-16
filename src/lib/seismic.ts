export type SeismicGrade = 'MISS' | 'HIT' | 'PERFECT';

export interface SeismicConfig {
    sweetSpotWidth: number; // Percentage 0-100
    perfectZoneWidth: number; // Percentage 0-100 relative to sweet spot? Or absolute? Docs say "30% of Sweet Spot width"
    sweetSpotStart: number; // Percentage 0-100
}

export interface SeismicState {
    isActive: boolean;
    config: SeismicConfig;
    impactPos: number; // 0-100
    grades: SeismicGrade[]; // Allow multiple strikes for lvl 99
    maxStrikes: number;
}

/**
 * Calculates the sweet spot width based on Excavation Level.
 * Rule: 6% + (Level * 0.14%)
 */
export function calculateSweetSpotWidth(level: number): number {
    // Level 1: ~6.1%
    // Level 50: ~13.0%
    // Level 99: ~19.9%
    return 6 + (level * 0.14);
}

/**
 * Generates a random start position for the sweet spot.
 * Ensures it doesn't clip off the edges too much.
 * Margin of 5% on each side.
 */
export function generateSweetSpotStart(width: number): number {
    const min = 10;
    const max = 90 - width;
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * Grades a strike based on the impact position and configuration.
 */
export function gradeStrike(impactPos: number, config: SeismicConfig): SeismicGrade {
    const { sweetSpotStart, sweetSpotWidth } = config;
    const sweetSpotEnd = sweetSpotStart + sweetSpotWidth;

    // Perfect Zone: Middle 30% of the sweet spot
    const perfectWidth = sweetSpotWidth * 0.3;
    const perfectStart = sweetSpotStart + (sweetSpotWidth - perfectWidth) / 2;
    const perfectEnd = perfectStart + perfectWidth;

    if (impactPos >= perfectStart && impactPos <= perfectEnd) {
        return 'PERFECT';
    }

    if (impactPos >= sweetSpotStart && impactPos <= sweetSpotEnd) {
        return 'HIT';
    }

    return 'MISS';
}
