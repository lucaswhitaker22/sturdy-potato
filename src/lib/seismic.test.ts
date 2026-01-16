import { describe, it, expect } from 'vitest';
import { calculateSweetSpotWidth, generateSweetSpotStart, gradeStrike, type SeismicConfig } from './seismic';

describe('Seismic Surge Logic', () => {
    describe('calculateSweetSpotWidth', () => {
        it('calculates width for level 1', () => {
            // 6 + (1 * 0.14) = 6.14
            expect(calculateSweetSpotWidth(1)).toBeCloseTo(6.14);
        });

        it('calculates width for level 50', () => {
            // 6 + (50 * 0.14) = 6 + 7 = 13
            expect(calculateSweetSpotWidth(50)).toBeCloseTo(13.0);
        });

        it('calculates width for level 99', () => {
            // 6 + (99 * 0.14) = 6 + 13.86 = 19.86
            expect(calculateSweetSpotWidth(99)).toBeCloseTo(19.86);
        });
    });

    describe('gradeStrike', () => {
        const config: SeismicConfig = {
            sweetSpotWidth: 20,
            perfectZoneWidth: 30, // unused in gradeStrike? Logic re-calcs it as 30% of width
            sweetSpotStart: 40
        };
        // Sweet Spot: 40 to 60
        // Perfect Zone: 30% of 20 = 6. 
        // Start = 40 + (20 - 6)/2 = 40 + 7 = 47.
        // End = 47 + 6 = 53.
        // Perfect: 47 to 53.

        it('returns MISS when outside sweet spot', () => {
            expect(gradeStrike(0, config)).toBe('MISS');
            expect(gradeStrike(39.9, config)).toBe('MISS');
            expect(gradeStrike(60.1, config)).toBe('MISS');
            expect(gradeStrike(100, config)).toBe('MISS');
        });

        it('returns HIT when in sweet spot but not perfect', () => {
            expect(gradeStrike(40, config)).toBe('HIT');
            expect(gradeStrike(46, config)).toBe('HIT');
            expect(gradeStrike(54, config)).toBe('HIT');
            expect(gradeStrike(60, config)).toBe('HIT');
        });

        it('returns PERFECT when in perfect core', () => {
            expect(gradeStrike(47, config)).toBe('PERFECT');
            expect(gradeStrike(50, config)).toBe('PERFECT');
            expect(gradeStrike(53, config)).toBe('PERFECT');
        });
    });
});
