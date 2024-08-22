<template>
    <div class="label--center" :style="itemStyle(item)">
        <ProgressBar
            v-if="item.progress && item.progress.value"
            :value="item.progress.value"
            :label="item.label"
            :type="item.progress?.type"
            :percent="item.progress?.percent"
        />
    </div>
</template>
<script lang="ts" setup>
import { Option } from '../types/types';
import { itemStyle } from '../util';
import ProgressBar from './ProgressBar.vue';

defineProps<{ item: Option }>();
</script>
