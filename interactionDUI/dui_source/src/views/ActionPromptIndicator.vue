<script lang="ts" setup>
import { onUnmounted, ref } from 'vue';
import { dev_run, subscribe } from '../util';
import { FocusTracker, FocusTrackerT, InteractionMenu } from '../types/types';

defineProps<{ focusTracker: FocusTracker }>();

const state = ref({
    content: 'E',
    glow: false,
    fill: 0,
});

const emit = defineEmits<{
    (event: 'setVisible', name: FocusTrackerT, value: boolean): void;
}>();

const setVisible = (val: boolean) => emit('setVisible', 'indicator', val);

const handleMenuShow = (data: InteractionMenu): void => {
    const { indicator } = data;

    if (indicator?.active) {
        state.value.content = indicator.prompt || 'E';
        state.value.glow = !!indicator.glow;
        setVisible(true);
    } else {
        setVisible(false);
    }
};

subscribe('interactionMenu:indicatorFill', async (params: any) => {
    state.value.fill = params;
});
subscribe('interactionMenu:menu:show', handleMenuShow);
subscribe('interactionMenu:hideMenu', () => setVisible(false));

// dev stuff
let intervalId: NodeJS.Timeout | null = null;
dev_run(() => {
    intervalId = setInterval(() => {
        state.value.fill += 2;
        if (state.value.fill >= 100) {
            state.value.fill = 0;
        }
    }, 100);
});

onUnmounted(() => {
    if (intervalId !== null) clearInterval(intervalId);
});
</script>

<template>
    <Transition name="fade">
        <div v-if="focusTracker.indicator" class="indicator" :class="{ 'indicator--glow': state.glow }">
            <div class="indicator__text indicator__text--mix-blend-mode">
                {{ state.content }}
            </div>
            <div class="indicator__fill" :style="{ width: state.fill + '%' }"></div>
        </div>
    </Transition>
</template>

<style lang="scss">
.indicator {
    position: relative;
    min-width: 5rem;
    height: 5rem;
    border: 6px solid var(--primary-color-border);
    border-radius: 1rem;
    color: var(--text-color);
    font-size: 2.5rem;
    background-color: var(--primary-color-background);
    display: flex;
    justify-content: center;
    align-content: center;
    flex-wrap: wrap;
    transition: background-color 0.5s ease;
    overflow: hidden;

    &__text {
        padding: 1rem;
        z-index: 1;
        color: var(--text-color);

        &--mix-blend-mode {
            mix-blend-mode: overlay;
        }
    }

    &__fill {
        position: absolute;
        left: 0;
        bottom: 0;
        height: 100%;
        background-color: var(--primary-color-glow);
        z-index: 0;
        transition: width 0.1s linear;
    }

    &--glow {
        box-shadow:
            0 10px 10px var(--primary-color-glow),
            0 0 30px var(--primary-color-glow);
    }
}
</style>
