<script setup lang="ts">
import { Ref, ref } from 'vue';
import { FocusTracker, InteractionMenu } from './types/types';
import { subscribe, dev_run } from './util';
import Indicator from './views/Indicator.vue';
import Menu from './views/Menu.vue';
import DevTools from './components/DevTools.vue';

const dev = ref(false);
const darkMode = ref(false);
const theme = ref('default');
const focusTracker: Ref<FocusTracker> = ref({
    indicator: false,
    menu: false,
});

const setVisible = (name: string, value: boolean) => (focusTracker.value[name] = value);
dev_run(() => (dev.value = true));

subscribe('interactionMenu:hideMenu', () => {
    setVisible('indicator', false);
    setVisible('menu', false);
});

subscribe('interactionMenu:darkMode', (value: boolean) => {
    darkMode.value = value;
});

subscribe('interactionMenu:menu:show', (data: InteractionMenu) => {
    if (!data) return;

    theme.value = data.theme || 'default';
});
</script>

<template>
    <Transition>
        <div class="interact-container" :class="{ dev: dev, dark: darkMode }" :data-theme="theme">
            <DevTools :theme="theme" v-if="dev" />

            <Indicator :focus-tracker="focusTracker" @set-visible="setVisible"></Indicator>
            <Menu :focus-tracker="focusTracker" @set-visible="setVisible"></Menu>
        </div>
    </Transition>
</template>
