<template >
    <div class="label-update progress-container" :style="itemStyle(item)">
        <div v-if="item.label !== null"> {{ item.label }} </div>

        <div class="progressbar" v-if="item.progress">
            <div class="progress" :class="item.progress?.type" :style="`width: ${progressValue(item)}%;`"> </div>
            <div class="percent" v-if="item.progress?.percent"> {{ progressValue(item).toFixed(2) }}% </div>
        </div>
    </div>
</template>
<script lang="ts" setup>
import { Option } from '../types/types';
import { itemStyle } from "../util";

defineProps<{ item: Option }>()

const progressValue = (item: Option) => {
    if (!item.progress) return 0;
    const clampedProgress = Math.min(Math.max(item.progress.value || 0, 0), 100);
    return Number.isFinite(clampedProgress) ? clampedProgress : 0;
};
</script>
