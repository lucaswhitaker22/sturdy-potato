import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { getToolLevel } from '@/lib/tools'; // Assuming this utility exists or need to move it

export const useSkillsStore = defineStore('skills', () => {
    // State
    const excavationXP = ref(0);
    const restorationXP = ref(0);
    const appraisalXP = ref(0);
    const smeltingXP = ref(0);

    // Getters (Computed)
    const excavationLevel = computed(() => getToolLevel(excavationXP.value));
    const restorationLevel = computed(() => getToolLevel(restorationXP.value));
    const appraisalLevel = computed(() => getToolLevel(appraisalXP.value));
    const smeltingLevel = computed(() => getToolLevel(smeltingXP.value));

    return {
        excavationXP,
        restorationXP,
        appraisalXP,
        smeltingXP,
        excavationLevel,
        restorationLevel,
        appraisalLevel,
        smeltingLevel
    };
});
