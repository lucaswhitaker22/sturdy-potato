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

        // Push grade
        if (seismicState.value.grades.length < seismicState.value.maxStrikes) {
            seismicState.value.grades.push(grade);
        }

        seismicState.value.impactPos = impactPos;

        // Audio Hooks (Conceptual - assuming an audio manager or window events)
        if (grade === 'PERFECT') {
            window.dispatchEvent(new CustomEvent('game-sfx', { detail: 'clink' }));
        } else if (grade === 'HIT') {
            window.dispatchEvent(new CustomEvent('game-sfx', { detail: 'click' }));
        } else {
            window.dispatchEvent(new CustomEvent('game-sfx', { detail: 'thud' }));
        }

        return grade;
    }

    return {
        seismicState,
        strike
    };
});
