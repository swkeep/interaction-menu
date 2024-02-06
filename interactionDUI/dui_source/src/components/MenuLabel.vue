<template >
    <div class="label-update" :style="itemStyle(item)">
        <i v-if="item.icon" :class="[item.icon, 'icon']"></i>

        <span v-html="item.label"></span>
    </div>
</template>
<script lang="ts" setup>
import { Option } from '../types/types';
import { itemStyle } from "../util";

defineProps<{ item: Option }>()

</script>
