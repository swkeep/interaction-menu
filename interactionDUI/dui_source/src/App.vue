<script setup lang="ts">
import { computed, ref } from 'vue';
import { FocusTracker, FocusTrackerT, InteractionMenu } from './types/types';
import { subscribe, dev_run } from './util';
import ActionPromptIndicator from './views/ActionPromptIndicator.vue';
import MenuContentRenderer from './views/MenuContentRenderer.vue';
import DevTools from './components/DevTools.vue';

// Reactive
const dev = ref(false);
const darkMode = ref(false);
const theme = ref('default');
const focusTracker = ref<FocusTracker>({
    indicator: false,
    menu: false,
});

// Computed
const isDevVisible = computed(() => dev.value);
const isDarkMode = computed(() => darkMode.value);
const currentTheme = computed(() => theme.value);

// Methods
const setVisible = (name: FocusTrackerT, value: boolean) => {
    focusTracker.value[name] = value;
};

const handleHideMenu = () => {
    setVisible('indicator', false);
    setVisible('menu', false);
};

const handleDarkModeChange = (value: boolean) => {
    darkMode.value = value;
};

const handleMenuShow = (data: InteractionMenu) => {
    if (data && data.theme) {
        theme.value = data.theme;
    }
};

// Subscriptions
dev_run(() => (dev.value = true));
subscribe('interactionMenu:hideMenu', handleHideMenu);
subscribe('interactionMenu:darkMode', handleDarkModeChange);
subscribe('interactionMenu:menu:show', handleMenuShow);
</script>

<template>
    <div class="interact-container" :data-theme="currentTheme" :data-dev="isDevVisible" :data-dark="isDarkMode">
        <DevTools :theme="currentTheme" v-if="isDevVisible" />

        <ActionPromptIndicator :focus-tracker="focusTracker" @set-visible="setVisible" />
        <MenuContentRenderer :focus-tracker="focusTracker" @set-visible="setVisible" />
    </div>
</template>
