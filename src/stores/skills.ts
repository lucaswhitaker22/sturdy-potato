import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase';
import { getToolLevel } from '@/lib/tools';

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

    // Specializations
    const specializations = ref<{
        excavation?: string;
        restoration?: string;
        appraisal?: string;
        smelting?: string;
    }>({});

    async function chooseSpecialization(skill: string, branch: string) {
        const { data, error } = await supabase.rpc('rpc_choose_specialization', {
            p_skill: skill,
            p_branch: branch
        });
        if (data?.success) {
            specializations.value[skill as keyof typeof specializations.value] = branch;
            return true;
        }
        return false;
    }

    async function respec(skill: string) {
        const { data, error } = await supabase.rpc('rpc_respec_specialization', {
            p_skill: skill
        });
        if (data?.success) {
            delete specializations.value[skill as keyof typeof specializations.value];
            return true;
        }
        return false;
    }

    return {
        excavationXP,
        restorationXP,
        appraisalXP,
        smeltingXP,
        excavationLevel,
        restorationLevel,
        appraisalLevel,
        smeltingLevel,
        specializations,
        chooseSpecialization,
        respec
    };
});

