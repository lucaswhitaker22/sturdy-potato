
import { calculateSweetSpotWidth, gradeStrike, type SeismicConfig } from './seismic';

console.log('Verifying Seismic Logic...');

let passed = 0;
let failed = 0;

function assert(description: string, condition: boolean) {
    if (condition) {
        console.log(`[PASS] ${description}`);
        passed++;
    } else {
        console.error(`[FAIL] ${description}`);
        failed++;
    }
}

// 1. Calculate Sweet Spot Width
console.log('\n--- Sweet Spot Calculation ---');
const w1 = calculateSweetSpotWidth(1);
assert('Level 1 Width ~6.14', Math.abs(w1 - 6.14) < 0.01);

const w50 = calculateSweetSpotWidth(50);
assert('Level 50 Width ~13.0', Math.abs(w50 - 13.0) < 0.01);

const w99 = calculateSweetSpotWidth(99);
assert('Level 99 Width ~19.86', Math.abs(w99 - 19.86) < 0.01);

// 2. Grade Strike
console.log('\n--- Strike Grading ---');
const config: SeismicConfig = {
    sweetSpotWidth: 20,
    perfectZoneWidth: 30,
    sweetSpotStart: 40
};
// Range: 40 to 60.
// Perfect: 30% of 20 = 6. Center of 40-60 is 50.
// Perfect Range: 47 to 53.

assert('0 is MISS', gradeStrike(0, config) === 'MISS');
assert('45 is HIT', gradeStrike(45, config) === 'HIT');
assert('50 is PERFECT', gradeStrike(50, config) === 'PERFECT');
assert('55 is HIT', gradeStrike(55, config) === 'HIT');
assert('80 is MISS', gradeStrike(80, config) === 'MISS');

console.log(`\nResults: ${passed} Passed, ${failed} Failed`);
if (failed > 0) process.exit(1);
