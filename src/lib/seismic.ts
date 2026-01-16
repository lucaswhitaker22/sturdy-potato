export type SeismicGrade = 'MISS' | 'HIT' | 'PERFECT';

export interface SweetSpot {
    start: number;
    width: number;
}

export interface SeismicConfig {
    sweetSpots: SweetSpot[];
    perfectZoneWidth: number; // 30% of Sweet Spot width (relative)
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
    return 6 + (level * 0.14);
}

/**
 * Generates random non-overlapping sweet spots.
 */
export function generateSweetSpots(level: number): SweetSpot[] {
    const width = calculateSweetSpotWidth(level);
    const count = level >= 99 ? 2 : 1;
    const spots: SweetSpot[] = [];

    for (let i = 0; i < count; i++) {
        let start: number;
        let overlap = false;
        let attempts = 0;

        do {
            start = 10 + Math.random() * (75 - width);
            overlap = spots.some(s =>
                (start >= s.start && start <= s.start + s.width) ||
                (start + width >= s.start && start + width <= s.start + s.width)
            );
            attempts++;
        } while (overlap && attempts < 10);

        spots.push({ start, width });
    }

    return spots;
}

/**
 * Grades a strike based on the impact position and all configured sweet spots.
 */
export function gradeStrike(impactPos: number, config: SeismicConfig): SeismicGrade {
    let bestGrade: SeismicGrade = 'MISS';

    for (const spot of config.sweetSpots) {
        const { start: sweetSpotStart, width: sweetSpotWidth } = spot;
        const sweetSpotEnd = sweetSpotStart + sweetSpotWidth;

        // Perfect Zone: Middle 30% of the sweet spot
        const perfectWidth = sweetSpotWidth * 0.3;
        const perfectStart = sweetSpotStart + (sweetSpotWidth - perfectWidth) / 2;
        const perfectEnd = perfectStart + perfectWidth;

        if (impactPos >= perfectStart && impactPos <= perfectEnd) {
            return 'PERFECT'; // Return immediately on perfect
        }

        if (impactPos >= sweetSpotStart && impactPos <= sweetSpotEnd) {
            bestGrade = 'HIT';
        }
    }

    return bestGrade;
}
