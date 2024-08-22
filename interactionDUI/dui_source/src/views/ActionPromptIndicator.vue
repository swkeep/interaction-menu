<script lang="ts" setup>
import { onUnmounted, ref } from 'vue';
import { dev_run, subscribe } from '../util';
import { FocusTracker, FocusTrackerT, InteractionMenu } from '../types/types';

defineProps<{ focusTracker: FocusTracker }>();
const defaultState = {
    content: 'E',
    glow: false,
    onHold: false,
    status: '',
    fill: 0,
};

const state = ref(defaultState);
const timeoutRef = ref<NodeJS.Timeout | null>(null);

const emit = defineEmits<{
    (event: 'setVisible', name: FocusTrackerT, value: boolean): void;
}>();

const setVisible = (val: boolean) => emit('setVisible', 'indicator', val);

const handleMenuShow = (data: InteractionMenu): void => {
    const { indicator } = data;

    if (indicator) {
        state.value.content = indicator.prompt || 'E';
        state.value.glow = !!indicator.glow;
        state.value.onHold = indicator.hold ? true : false;
        setVisible(true);
    } else {
        setVisible(false);
        state.value = defaultState;
    }
};

const handleStatusChange = (status: string) => {
    const state_ref = state.value;

    if (timeoutRef.value !== null) clearTimeout(timeoutRef.value);
    state_ref.status = status;

    timeoutRef.value = setTimeout(() => {
        state_ref.status = '';
        timeoutRef.value = null;
    }, 350);
};

subscribe('interactionMenu:indicatorFill', async (params: any) => {
    state.value.fill = params;
});
subscribe('interactionMenu:menu:show', handleMenuShow);
subscribe('interactionMenu:hideMenu', () => setVisible(false));
subscribe('interactionMenu:indicatorStatus', handleStatusChange);

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
    if (timeoutRef.value !== null) clearTimeout(timeoutRef.value);
});
</script>

<template>
    <Transition name="fade">
        <div
            v-if="focusTracker.indicator"
            class="indicator"
            :class="{
                'indicator--glow': state.glow,
                'indicator--success': state.status === 'success',
                'indicator--fail': state.status === 'fail',
            }"
        >
            <div class="indicator__text" :class="{ 'indicator__text--mix-blend-mode': state.onHold }">
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
    transition:
        background-color 0.4s ease,
        border-color 350ms ease;
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

    &--success {
        border-color: rgb(214, 237, 159) !important;
    }

    &--fail {
        border-color: rgb(199, 37, 61) !important;
    }

    &--glow {
        box-shadow:
            0 10px 10px var(--primary-color-glow),
            0 0 30px var(--primary-color-glow);
    }
}
</style>
