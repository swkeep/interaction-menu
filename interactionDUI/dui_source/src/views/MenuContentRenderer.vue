<template>
    <Transition name="fade" mode="out-in">
        <div class="menus-container" :class="{ 'menus-container--glow': Data.glow }" v-if="focusTracker.menu">
            <div
                class="menu"
                v-for="(menu, i) in Data.menus"
                :key="i"
                :data-menuId="menu.id"
                :data-hide="menu.flags.hide"
                :data-deleted="menu.flags.deleted"
                :data-invoking-resource="menu?.metadata?.invokingResource"
                :class="{
                    'menu--hidden': menu.flags.hide || menu.flags?.deleted,
                }"
            >
                <TransitionGroup name="slide" appear v-if="!menu.flags.hide && !menu.flags?.deleted">
                    <template v-for="(item, index) in menu.options" :key="index">
                        <div
                            class="menu__option"
                            :class="{ 'menu__option--no-margin': item.flags?.hide }"
                            :data-id="index"
                            :data-vid="item.vid"
                        >
                            <Component :is="getFieldComponent(item)" :item="item" :selected="Data.selected" />
                        </div>
                    </template>
                </TransitionGroup>
            </div>
        </div>
    </Transition>
</template>
<script lang="ts" setup>
import { subscribe } from '../util';
import { computed, defineAsyncComponent, ref } from 'vue';
import { FocusTracker, FocusTrackerT, InteractionMenu, Menu, Option } from '../types/types';

const menuComponents = {
    // @ts-ignore
    audioPlayer: defineAsyncComponent(() => import('../components/AudioPlayer.vue')),
    // @ts-ignore
    videoPlayer: defineAsyncComponent(() => import('../components/VideoRenderer.vue')),
    // @ts-ignore
    pictureViewer: defineAsyncComponent(() => import('../components/ImageRenderer.vue')),
    // @ts-ignore
    menuOption: defineAsyncComponent(() => import('../components/MenuOption.vue')),
    // @ts-ignore
    progressbar: defineAsyncComponent(() => import('../components/MenuProgressbar.vue')),
};

defineProps<{ focusTracker: FocusTracker }>();

const emit = defineEmits<{
    (event: 'setVisible', name: FocusTrackerT, value: boolean): void;
}>();

const setVisible = (val: boolean) => emit('setVisible', 'menu', val);

const getFieldComponent = computed(() => (item: Option) => {
    if (item.flags.hide) return;

    if (item.video) return menuComponents.videoPlayer;
    if (item.audio) return menuComponents.audioPlayer;
    if (item.picture) return menuComponents.pictureViewer;
    if (item.progress) return menuComponents.progressbar;

    return menuComponents.menuOption;
});

const defaultInteractionMenu = (): InteractionMenu => ({
    id: 0,
    indicator: undefined,
    loading: false,
    menus: [],
    selected: [],
    theme: 'default',
    glow: false,
});

const Data = ref(defaultInteractionMenu());

const resetData = function () {
    Data.value = defaultInteractionMenu();
};

const hideMenu = () => {
    setVisible(false);
    resetData();
};

const showMenu = (data: InteractionMenu) => {
    if (!data.menus) return;
    resetData();

    Data.value.glow = data.glow;
    Data.value.menus = data.menus;
    Data.value.selected = data.selected;

    setVisible(true);
};

const updateSelectedMenu = (data: any) => {
    Data.value.selected = data;
};

const setMenuVisibility = (data: any) => {
    for (const key in Data.value.menus) {
        const menu = Data.value.menus[key];

        if (menu.id === data.id) {
            menu.flags.hide = !data.visibility;
            break;
        }
    }
};

const deleteMenu = (ids: (number | string)[]) => {
    for (const key in Data.value.menus) {
        const menu = Data.value.menus[key];
        const menuId = menu.id as number | string;

        if (ids.includes(menuId)) {
            menu.flags.deleted = true;
        }
    }
};

const handleBatchUpdate = (data: { [key: string]: { menuId: string | number; option: Option } }): void => {
    const menus = Data.value.menus;
    const updatedOptions = new Map<string | number, Option>();

    for (const [_, updatedElement] of Object.entries(data)) {
        updatedOptions.set(updatedElement.option.vid, updatedElement.option);
    }

    const updatedMenus = menus.slice();
    for (const menu of updatedMenus) {
        for (const [key, option] of Object.entries(menu.options)) {
            const updatedOption = updatedOptions.get(option.vid);
            if (updatedOption) {
                menu.options[key] = updatedOption;
            }
        }
    }

    Data.value.menus = updatedMenus;
};

// Subscriptions
subscribe('interactionMenu:hideMenu', hideMenu);
subscribe('interactionMenu:menu:show', showMenu);
subscribe('interactionMenu:menu:selectedUpdate', updateSelectedMenu);
subscribe('interactionMenu:menu:setVisibility', setMenuVisibility);
subscribe('interactionMenu:menu:delete', deleteMenu);
subscribe('interactionMenu:menu:batchUpdate', handleBatchUpdate);
</script>
