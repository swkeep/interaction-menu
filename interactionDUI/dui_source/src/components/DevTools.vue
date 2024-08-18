<template>
    <div v-if="show" class="dev-element">
        <div class="controls">
            <p class="count">
                {{ count }}
            </p>
            <button @click="moveDown">Down</button>
            <button @click="moveUp">Up</button>
        </div>
        <button @click="toggleDarkMode">Dark Mode: {{ darkMode }}</button>
        <button @click="cycleTheme">Theme: {{ currentTheme }}</button>
    </div>
</template>

<script lang="ts" setup>
import { ref, computed } from 'vue';
import { debug, dev_run } from '../util';

const props = defineProps<{
    theme: string;
}>();

const count = ref(1);
const themes = ['default', 'cyan', 'red', 'green', 'yellow'];
const darkMode = ref(false);
const show = ref(false);
const currentTheme = computed(() => props.theme);

dev_run(() => (show.value = true));

const toggleDarkMode = () => {
    darkMode.value = !darkMode.value;
    debug([{ action: 'interactionMenu:darkMode', data: darkMode.value }], 0);
};

const cycleTheme = () => {
    const nextIndex = (themes.indexOf(currentTheme.value) + 1) % themes.length;
    debug([{ action: 'interactionMenu:menu:show', data: { theme: themes[nextIndex] } }], 0);
};

const updateCount = (delta: number) => {
    count.value += delta;
    if (count.value <= 1) count.value = 1;

    debug([{ action: 'interactionMenu:menu:selectedUpdate', data: count.value }], 0);
};

const moveUp = () => updateCount(-1);
const moveDown = () => updateCount(1);

const mockData = {
    selected: 1,
    theme: 'default',
    // indicator: {
    //     prompt: 'Enter',
    //     glow: true,
    //     active: true
    // },
    menus: [
        {
            id: 'test',
            flags: {
                hide: false,
            },
            options: [
                {
                    vid: 1,
                    label: 'Center No Action',
                    flags: {
                        hide: false,
                    },
                },
                {
                    vid: 2,
                    label: 'Sand',
                    flags: {
                        action: true,
                        hide: false,
                    },
                },
                {
                    vid: 3,
                    label: 'State: Locked',
                    flags: {
                        update: true,
                        hide: false,
                    },
                },
            ],
        },
        {
            id: 'test2',
            flags: {
                hide: false,
            },
            options: [
                {
                    vid: 4,
                    picture: {
                        height: '15em',
                        url: [
                            'http://127.0.0.1:8080/thumb-1920-1013065.jpg',
                            'http://127.0.0.1:8080/thumb-1920-1014054.png',
                            'http://127.0.0.1:8080/warframe1.jpg',
                            'http://127.0.0.1:8080/warframe2.jpg',
                        ],
                    },
                    flags: {
                        hide: false,
                    },
                },
                {
                    vid: 4,
                    picture: {
                        url: 'http://127.0.0.1:8080/00235-990749447.png',
                    },
                    flags: {
                        hide: false,
                    },
                },
                {
                    vid: 5,
                    id: 5,
                    label: 'Test Title',
                    description: 'Test Subtitle',
                    video: {
                        url: 'http://127.0.0.1:8080/2.mp4',
                        volume: 0.0,
                        progress: true,
                        // percent: true,
                        // loop: true,
                        timecycle: true,
                    },
                    flags: {
                        hide: false,
                    },
                },
                {
                    vid: 6,
                    label: 'Progress',
                    progress: {
                        type: 'info',
                        percent: true,
                        value: 69,
                    },
                    flags: {
                        hide: false,
                    },
                },
            ],
        },
    ],
};

debug(
    [
        {
            action: 'interactionMenu:menu:show',
            data: mockData,
        },
    ],
    1000,
);
</script>

<style scoped lang="scss">
.dev-element {
    padding: 1rem;
    margin-right: 1rem;
    background-color: #ffffff31;
    border-radius: 4px;
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
}
</style>
