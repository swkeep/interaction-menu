<template>
    <input v-if="isRadio" class="menu-option__radio" type="radio" :name="radioName" :checked="isSelected" />
    <div class="label" :class="labelClass" :style="computedItemStyle">
        <i v-if="item.icon" :class="[item.icon, 'label__icon']"></i>
        <span v-if="!isRadio" v-html="item.label"></span>
        <div v-if="isRadio">
            {{ item.label }}
        </div>
    </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue';
import { Option } from '../types/types';
import { itemStyle } from '../util';

const props = defineProps<{
    item: Option;
    selected?: number; // when it's radio
}>();

const isRadio = computed(
    () => (props.item.flags?.update || props.item.flags?.action || props.item.flags?.event) ?? false,
);

const radioName = computed(() => (isRadio.value ? `radio-${props.item.vid}` : ''));
const isSelected = computed(() => isRadio.value && props.selected === props.item.vid);
const computedItemStyle = computed(() => itemStyle(props.item));

const labelClass = computed(() => ({
    'label--center': !isRadio.value,
    'label--radio': isRadio.value,
}));
</script>
