<script setup lang="ts">
import { computed, ref } from 'vue';
import { FocusTracker, FocusTrackerT, InteractionMenu } from './types/types';
import { subscribe, dev_run } from './util';
import ActionPromptIndicator from './views/ActionPromptIndicator.vue';
import MenuContentRenderer from './views/MenuContentRenderer.vue';
import eye from './views/Eye.vue';
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

const hide_menu = () => {
    setVisible('indicator', false);
    setVisible('menu', false);
};

const set_darl_mode = (value: boolean) => {
    darkMode.value = value;
};

const show_menu = (data: InteractionMenu) => {
    if (data && data.theme) theme.value = data.theme;
};

// Subscriptions
dev_run(() => (dev.value = true));
subscribe('interactionMenu:hideMenu', hide_menu);
subscribe('interactionMenu:darkMode', set_darl_mode);
subscribe('interactionMenu:menu:show', show_menu);
</script>

<template>
    <div class="interact-container" :data-theme="currentTheme" :data-dev="isDevVisible" :data-dark="isDarkMode">
        <DevTools :theme="currentTheme" v-if="isDevVisible" />
        <eye></eye>

        <div class="menu-wrapper">
            <ActionPromptIndicator :focus-tracker="focusTracker" @set-visible="setVisible" />
            <MenuContentRenderer :focus-tracker="focusTracker" @set-visible="setVisible" />
        </div>
    </div>
</template>
