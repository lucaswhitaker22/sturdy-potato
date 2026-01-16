import { defineStore } from 'pinia';
import { ref } from 'vue';
import {
    type SeismicState,
    type SeismicGrade,
    gradeStrike
} from '@/lib/seismic';

// Note: Config, isActive, etc are defined in lib but state holds the runtime values.
// We initialize with defaults matching the type.

export const useSeismicStore = defineStore('seismic', () => {
    const seismicState = ref<SeismicState>({
        isActive: false,
        config: { sweetSpotWidth: 10, perfectZoneWidth: 30, sweetSpotStart: 50 },
        impactPos: 0,
        grades: [],
        maxStrikes: 3
    });

    function strike(impactPos: number) {
        if (!seismicState.value.isActive) return null;

        const grade = gradeStrike(impactPos, seismicState.value.config);
        // Ensure we don't exceed maxStrikes if that logic is needed, or just push.
        // The type definition says grades is generic array, so this is fine.
        seismicState.value.grades.push(grade);
        seismicState.value.impactPos = impactPos;

        return grade;
    }

    return {
        seismicState,
        strike
    };
});
