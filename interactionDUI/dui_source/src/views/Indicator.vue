<template>
    <Transition>
        <div v-if="focusTracker.indicator" class="indicator" :class="{ glow: state.glow }">
            <div class="text">
                {{ state.content }}
            </div>
        </div>
    </Transition>
</template>

<script lang="ts" setup>
import { reactive, defineEmits } from 'vue';
import { subscribe } from '../util';
import { FocusTracker, InteractionMenu } from '../types/types';

defineProps<{ focusTracker: FocusTracker }>();

const state = reactive({
    content: 'E',
    glow: false,
});

const emit = defineEmits<{
    (event: 'setVisible', name: string, value: boolean): void;
}>();

const setVisible = (val: boolean) => emit('setVisible', 'indicator', val);

subscribe('interactionMenu:menu:show', function (data: InteractionMenu) {
    const { indicator } = data;

    if (indicator && indicator.active) {
        state.content = indicator.prompt || 'E';
        state.glow = indicator.glow || false;
        setVisible(true);
    }
});

subscribe('interactionMenu:hideMenu', () => setVisible(false));
</script>
