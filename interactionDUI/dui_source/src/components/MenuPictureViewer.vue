<template >
    <div class="picture-container">
        <img v-if="item.picture && Array.isArray(item.picture.url)" v-for="(url, index) in item.picture.url"
            :key="`picture-${item.id}-${index}`" :src="url"
            :style="{ 'opacity': item.picture.opacity, 'width': item.picture.width, 'height': item.picture.height }" />

        <img v-else-if="item.picture && !Array.isArray(item.picture.url)" :id="`picture-${item.id}`" :src="item.picture.url"
            :style="{ 'opacity': item.picture.opacity, 'width': item.picture.width, 'height': item.picture.height }"
            :class="{ 'border-dashed': item.picture.border == 'dash', 'border-solid': item.picture.border == 'solid' }" />
    </div>
</template>
<script lang="ts" setup>
import { Option } from '../types/types';

defineProps<{ item: Option }>()

</script>
