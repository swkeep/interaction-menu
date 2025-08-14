<template>
    <input v-if="isRadio" class="menu__option__radio" type="radio" :name="radioName" :checked="isSelected" />
    <div class="label" :class="labelClass" :style="computedItemStyle">
        <i v-if="item.icon" :class="[item.icon, 'label__icon']"></i>
        <span v-if="!isRadio" v-html="sanitized_label"></span>
        <div v-if="isRadio" class="label__container">
            <div class="label__text" v-html="sanitized_label"></div>
        </div>
        <span
            v-if="props.item.badge !== undefined"
            class="label__badge"
            :data-badge-type="props.item.badge.type || 'default'"
            v-html="sanitized_badge"
        ></span>
    </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue';
import { Option } from '../types/types';
import { itemStyle } from '../util';
import DOMPurify from 'dompurify';

const props = defineProps<{
    item: Option;
    selected?: number; // when it's radio
}>();

const sanitized_label = computed(() => {
    const html = String(props.item.label);
    if (html === undefined) return '';

    return DOMPurify.sanitize(html);
});

const sanitized_badge = computed(() => {
    if (!props.item.badge) return '';

    const html = String(props.item.badge.label);
    if (html === undefined) return '';

    return DOMPurify.sanitize(html);
});

const isRadio = computed(
    () => (props.item.flags?.update || props.item.flags?.action || props.item.flags?.event) ?? false,
);

const radioName = computed(() => (isRadio.value ? `radio-${props.item.vid}` : ''));
const isSelected = computed(() => isRadio.value && props.selected === props.item.vid);
const computedItemStyle = computed(() => itemStyle(props.item));

const labelClass = computed(() => ({
    'label--center': !isRadio.value,
    'label--radio': isRadio.value,
    'label--sub-menu': props.item.flags.subMenu,
    'label--action': props.item.flags.action === true,
}));
</script>
