<template>
    <input
        v-if="isRadio"
        class="menu__option__radio"
        type="radio"
        :name="radioName"
        :checked="isSelected"
        :class="{
            'menu__option--selected': isSelected,
        }"
    />
    <div class="label" :class="labelClass" :style="computedItemStyle" ref="optionElement">
        <i v-if="item.icon" :class="[item.icon, 'label__icon']"></i>

        <template v-if="!isRadio">
            <span v-html="sanitized_label"></span>
        </template>

        <template v-else>
            <div class="label__container">
                <div class="label__text" v-html="sanitized_label"></div>
                <div
                    v-if="item.description !== undefined && isSelected"
                    class="label__description"
                    v-html="sanitized_description"
                ></div>
            </div>
        </template>

        <transition name="fade-reverse">
            <span
                v-if="props.item.badge !== undefined && !isSelected"
                class="label__badge"
                :data-badge-type="props.item.badge.type || 'default'"
                v-html="sanitized_badge"
            ></span>
        </transition>
    </div>
</template>

<script lang="ts" setup>
import { computed, watch, onUnmounted, nextTick, ref, inject, Ref } from 'vue';
import { Option } from '../types/types';
import { itemStyle } from '../util';
import DOMPurify from 'dompurify';

const props = defineProps<{
    item: Option;
    selected?: number; // when it's radio
}>();

let currentAudio: HTMLAudioElement | null = null;
const first_selected = inject('first_selected') as Ref<number>;
const optionElement = ref<HTMLElement | null>(null);
const sanitizeHtml = (html: unknown) => {
    if (html === undefined || html === null) return '';
    return DOMPurify.sanitize(String(html));
};

const sanitized_label = computed(() => sanitizeHtml(props.item.label));
const sanitized_badge = computed(() => sanitizeHtml(props.item.badge?.label));
const sanitized_description = computed(() => sanitizeHtml(props.item.description));

const itemFlags = computed(() => props.item.flags || {});
const isRadio = computed(() => !!(itemFlags.value.update || itemFlags.value.action || itemFlags.value.event));

const radioName = computed(() => (isRadio.value ? `radio-${props.item.vid}` : ''));
const isSelected = computed(() => isRadio.value && props.selected === props.item.vid);
const computedItemStyle = computed(() => itemStyle(props.item));

const labelClass = computed(() => ({
    'label--center': !isRadio.value,
    'label--radio': isRadio.value,
    'label--sub-menu': itemFlags.value.subMenu,
    'label--action': itemFlags.value.action === true,
}));

const readLabel = (text: string) => {
    if (!text) return;

    if (currentAudio) {
        currentAudio.pause();
        currentAudio.currentTime = 0;
        currentAudio = null;
    }

    const api = props.item.tts_api || 'streamelements';
    const tts_voice = props.item.tts_voice || 'Amy';
    const textToSpeak = encodeURIComponent(text);

    let ttsUrl;

    if (api === 'streamelements') {
        ttsUrl = `https://api.streamelements.com/kappa/v2/speech?voice=${tts_voice}&text=${textToSpeak}`;
    }

    currentAudio = new Audio(ttsUrl);
    currentAudio.play().catch((e) => console.error('Error playing TTS:', e));
};

watch(isSelected, (newValue) => {
    if (newValue && optionElement.value && first_selected.value !== props.selected) {
        nextTick(() => {
            optionElement.value?.scrollIntoView({
                behavior: 'smooth',
                block: 'center',
                inline: 'nearest',
            });
        });
    }
});

watch(
    () => props.item.label,
    (newLabel, oldLabel) => {
        if (newLabel === 'placeholder') return;
        if (props.item.flags?.dialogue && newLabel !== oldLabel) {
            readLabel(newLabel);
        }
    },
);

onUnmounted(() => {
    if (currentAudio) {
        currentAudio.pause();
        currentAudio.currentTime = 0;
        currentAudio = null;
    }
});
</script>
