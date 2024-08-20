<script lang="ts" setup>
import { ref } from 'vue';
import { subscribe } from '../util';
import { FocusTracker, FocusTrackerT, InteractionMenu } from '../types/types';

defineProps<{ focusTracker: FocusTracker }>();

const state = ref({
    content: 'E',
    glow: false,
});

const emit = defineEmits<{
    (event: 'setVisible', name: FocusTrackerT, value: boolean): void;
}>();

const setVisible = (val: boolean) => emit('setVisible', 'indicator', val);

// handles the menu show event
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

subscribe('interactionMenu:menu:show', handleMenuShow);
subscribe('interactionMenu:hideMenu', () => setVisible(false));
</script>

<template>
    <Transition name="fade">
        <div v-if="focusTracker.indicator" class="indicator" :class="{ 'indicator--glow': state.glow }">
            <div class="indicator__text">
                {{ state.content }}
            </div>
        </div>
    </Transition>
</template>

<style lang="scss">
.indicator {
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

    &__text {
        padding: 1rem;
    }

    &--glow {
        box-shadow:
            0 10px 10px var(--primary-color-glow),
            0 0 30px var(--primary-color-glow);
    }
}
</style>
