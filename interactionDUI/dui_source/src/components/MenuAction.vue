<template>
    <input type="radio" name="radio" :checked="item.vid == selected" />
    <div class="label" :style="itemStyle(item)">
        <i v-if="item.icon" :class="[item.icon, 'icon']" />
        <div>
            {{ item.label }}
        </div>
    </div>
</template>
<script lang="ts" setup>
import { Option } from '../types/types';
import { itemStyle } from '../util';

defineProps<{ item: Option; selected: number }>();
</script>
