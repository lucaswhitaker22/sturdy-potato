
import { calculateSweetSpotWidth, gradeStrike, type SeismicConfig } from './seismic';

console.log('Verifying Seismic Logic...');

// 1. Calculate Sweet Spot Width
console.log('Test 1: calculateSweetSpotWidth');
const w1 = calculateSweetSpotWidth(1);
console.log(`Lvl 1 Width: ${w1} (Expected ~6.14) -> ${Math.abs(w1 - 6.14) < 0.01 ? 'PASS' : 'FAIL'}`);

const w50 = calculateSweetSpotWidth(50);
console.log(`Lvl 50 Width: ${w50} (Expected ~13.0) -> ${Math.abs(w50 - 13.0) < 0.01 ? 'PASS' : 'FAIL'}`);

const w99 = calculateSweetSpotWidth(99);
console.log(`Lvl 99 Width: ${w99} (Expected ~19.86) -> ${Math.abs(w99 - 19.86) < 0.01 ? 'PASS' : 'FAIL'}`);

// 2. Grade Strike
console.log('\nTest 2: gradeStrike');
const config: SeismicConfig = {
    sweetSpotWidth: 20,
    perfectZoneWidth: 30,
    sweetSpotStart: 40
};
// Perfect: 40 + (20-6)/2 = 47. Length 6. range 47-53.
// Hit: 40-60.

const t1 = gradeStrike(0, config);
console.log(`Pos 0: ${t1} (Expected MISS) -> ${t1 === 'MISS' ? 'PASS' : 'FAIL'}`);

const t2 = gradeStrike(45, config);
console.log(`Pos 45: ${t2} (Expected HIT) -> ${t2 === 'HIT' ? 'PASS' : 'FAIL'}`);

const t3 = gradeStrike(50, config);
console.log(`Pos 50: ${t3} (Expected PERFECT) -> ${t3 === 'PERFECT' ? 'PASS' : 'FAIL'}`);

const t4 = gradeStrike(55, config);
console.log(`Pos 55: ${t4} (Expected HIT) -> ${t4 === 'HIT' ? 'PASS' : 'FAIL'}`);

const t5 = gradeStrike(80, config);
console.log(`Pos 80: ${t5} (Expected MISS) -> ${t5 === 'MISS' ? 'PASS' : 'FAIL'}`);
