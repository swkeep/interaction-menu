<script setup lang="ts">
import { Ref, ref } from 'vue'
import { FocusTracker, InteractionMenu } from './types/types';
// @ts-ignore
import { subscribe, debug, dev_run } from './util'
// @ts-ignore
import Indicator from './views/Indicator.vue';
// @ts-ignore
import Menu from './views/Menu.vue';
// @ts-ignore
import Loading from './views/Loading.vue';

const themes = ['default', 'cyan', 'red', 'green', 'yellow']
const darkMode = ref(false)
const theme = ref('default')
const focusTracker: Ref<FocusTracker> = ref({
  indicator: false,
  menu: false,
  loading: false
})

const setVisible = (name: string, value: boolean) => focusTracker.value[name] = value

subscribe('interactionMenu:hideMenu', function () {
  setVisible('indicator', false)
  setVisible('menu', false)
});

subscribe('interactionMenu:darkMode', function (value: boolean) {
  darkMode.value = value
});

const toggleDarkMode = () => {
  darkMode.value = !darkMode.value
};

const cycleTheme = () => {
  const currentIndex = themes.indexOf(theme.value);
  const nextIndex = (currentIndex + 1) % themes.length;
  theme.value = themes[nextIndex];
};

debug([{
  action: 'interactionMenu:menu:show',
  data: {
    theme: 'default',
    indicator: {
      prompt: 'Enter',
      glow: true,
      active: true
    },
    menus: [
      {
        id: 'test',
        flags: {
          hide: false
        },
        options: [
          {
            vid: 1,
            label: "Sand",
            flags: {
              action: true,
              hide: false
            },
          },
          {
            vid: 2,
            label: "Center No Action",
            flags: {
              hide: false
            },
          },
          {
            vid: 3,
            label: "State: Locked",
            flags: {
              update: true,
              hide: false
            },
          },
        ]
      },
      {
        id: 'test2',
        flags: {
          hide: false
        },
        options: [
          {
            vid: 4,
            picture: {
              url: 'http://127.0.0.1:8080/00235-990749447.png',
            },
            flags: {
              hide: false
            },
          },
          {
            vid: 5,
            label: 'Test Title',
            description: 'Test Subtitle',
            video: {
              url: 'http://127.0.0.1:8080/2.mp4',
              volume: 0.0,
              progress: true,
              percent: true,
              timecycle: true,
            },
            flags: {
              hide: false
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
              hide: false
            },
          },
        ]
      },
    ],
    selected: 1
  }
}], 1000)

debug([{
  action: 'interactionMenu:menu:selectedUpdate',
  data: 3
}], 2000)


let dev = false
dev_run(() => dev = true)

subscribe('interactionMenu:menu:show', (data: InteractionMenu) => {
  if (!data) return;

  theme.value = data.theme || 'default'
})

</script>

<template>
  <Transition>
    <div class="intract-container" :class="{ 'dev': dev, 'dark': darkMode }" :data-theme="theme">
      <div class="dev-element" v-if="dev">
        <button @click="toggleDarkMode"> DarkMode: {{ darkMode }}</button>
        <button @click="cycleTheme"> Theme: {{ theme }}</button>
      </div>

      <Indicator :focusTracker="focusTracker" @set-visible="setVisible"></Indicator>
      <Menu :focusTracker="focusTracker" @set-visible="setVisible"></Menu>
      <Loading :focusTracker="focusTracker" @set-visible="setVisible"></Loading>
    </div>
  </Transition>
</template>
