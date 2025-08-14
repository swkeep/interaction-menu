<script lang="ts" setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { debug, dev_run } from '../util';
import { menuMockData } from '../types/mockData';

const props = defineProps<{
    theme: string;
}>();

const count = ref(1);
const themes = [
    'default',
    'box',
    'theme-1',
    'theme-2',
    'theme-3',
    'theme-4',
    'theme-5',
    'theme-6',
    'theme-7',
    'theme-8',
    'theme-9',
];
const darkMode = ref(false);
const show = ref(false);
const currentTheme = computed(() => props.theme);
const currentMenu = ref(0);
const selectOptions = reactive([
    {
        name: 'Action and Indicator',
    },
    {
        name: 'Text and Action',
    },
    {
        name: 'Image and Video',
    },
    {
        name: 'Actions and Icons',
    },
]);

const toggleDarkMode = () => {
    darkMode.value = !darkMode.value;
    debug([{ action: 'interactionMenu:darkMode', data: darkMode.value }], 0);
};

const cycleTheme = () => {
    const nextIndex = (themes.indexOf(currentTheme.value) + 1) % themes.length;
    debug(
        [
            {
                action: 'interactionMenu:menu:show',
                data: {
                    ...menuMockData[currentMenu.value],
                    theme: themes[nextIndex],
                },
            },
        ],
        0,
    );
};

const updateCount = (delta: number) => {
    count.value += delta;
    if (count.value <= 1) count.value = 1;

    debug([{ action: 'interactionMenu:menu:selectedUpdate', data: count.value }], 0);
};

const moveUp = () => updateCount(-1);
const moveDown = () => updateCount(1);

const syncMenu = async () => {
    const evnt = [
        {
            action: 'interactionMenu:menu:show',
            data: menuMockData[currentMenu.value],
        },
    ];
    debug(evnt, 100);
};

const hideMenu = async () => {
    const event = [
        {
            action: 'interactionMenu:hideMenu',
            data: {},
        },
    ];
    debug(event, 10);
};
dev_run(() => (show.value = true));

onMounted(() => {
    setTimeout(syncMenu, 500);
});
</script>

<template>
    <div v-if="show" class="dev-element">
        <div class="controls">
            <select v-model="currentMenu" class="select-input" @change="syncMenu">
                <option v-for="(item, index) in selectOptions" :key="index" :value="index">{{ item.name }}</option>
            </select>
        </div>
        <div class="controls">
            <p class="count">
                {{ count }}
            </p>
            <button @click="moveDown">Down</button>
            <button @click="moveUp">Up</button>
        </div>
        <button @click="toggleDarkMode">Dark Mode: {{ darkMode }}</button>
        <button @click="cycleTheme">Theme: {{ currentTheme }}</button>
        <div style="display: flex; justify-content: space-between; gap: 1rem">
            <button @click="syncMenu">Show current</button>
            <button @click="hideMenu">Hide</button>
        </div>
    </div>
</template>

<style lang="scss">
[data-dev='true'] {
    &.interact-container {
        background-color: rgba(0, 0, 0, 0.8);
    }
}

.dev-element {
    padding: 1rem;
    margin-right: 1rem;
    background-color: #ffffff31;
    display: flex;
    flex-direction: column;
    justify-content: center;
    gap: 0.5rem;

    button {
        align-items: center;
        appearance: none;
        background-color: #fcfcfd;
        border-radius: 4px;
        border-width: 0;
        box-shadow:
            rgba(45, 35, 66, 0.2) 0 2px 4px,
            rgba(45, 35, 66, 0.15) 0 7px 13px -3px,
            #d6d6e7 0 -3px 0 inset;
        box-sizing: border-box;
        color: #36395a;
        cursor: pointer;
        display: inline-flex;
        font-family: 'JetBrains Mono', monospace;
        height: 48px;
        justify-content: center;
        line-height: 1;
        list-style: none;
        overflow: hidden;
        padding-left: 16px;
        padding-right: 16px;
        position: relative;
        text-align: left;
        text-decoration: none;
        transition:
            box-shadow 0.15s,
            transform 0.15s;
        user-select: none;
        -webkit-user-select: none;
        touch-action: manipulation;
        white-space: nowrap;
        will-change: box-shadow, transform;
        font-size: 18px;
    }

    button:focus {
        box-shadow:
            #d6d6e7 0 0 0 1.5px inset,
            rgba(45, 35, 66, 0.4) 0 2px 4px,
            rgba(45, 35, 66, 0.3) 0 7px 13px -3px,
            #d6d6e7 0 -3px 0 inset;
    }

    button:hover {
        box-shadow:
            rgba(45, 35, 66, 0.3) 0 4px 8px,
            rgba(45, 35, 66, 0.2) 0 7px 13px -3px,
            #d6d6e7 0 -3px 0 inset;
        transform: translateY(-2px);
    }

    button:active {
        box-shadow: #d6d6e7 0 3px 7px inset;
        transform: translateY(2px);
    }
}

.controls {
    display: flex;
    gap: 1rem;
    background-color: rgb(165, 213, 255);
    border-radius: 0.5rem;
    padding: 0.5rem;

    .count {
        width: 50px;
        height: 50px;
        background-color: aliceblue;
        display: flex;
        justify-content: center;
        align-items: center;
        border-radius: 0.5rem;
    }

    .select-input {
        border: none;
        text-align: center;
        width: 100%;
        height: 3rem;
        background-color: #303030;
        color: #fff;
        font-size: inherit;
        border-radius: 0.5rem;
        font-family: 'Jura', Arial, sans-serif;
    }
}
</style>
