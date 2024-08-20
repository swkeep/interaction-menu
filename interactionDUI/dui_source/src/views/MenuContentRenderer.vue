<template>
    <Transition @after-leave="resetData">
        <div v-if="focusTracker.menu" class="menu-container" :class="{ 'menu-container--glow': Data.glow }">
            <div v-for="(menu, i) in Data.menus" class="menu" :data-menuId="menu.id" :key="i">
                <TransitionGroup v-if="menu.flags.hide === false" name="slide" appear>
                    <template v-for="(item, index) in menu.options" :key="index">
                        <div
                            class="menu-option"
                            :class="{ 'menu-option--no-margin': item.flags?.hide }"
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
import { FocusTracker, FocusTrackerT, InteractionMenu, Option } from '../types/types';

const menuComponents = {
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
subscribe('interactionMenu:menu:batchUpdate', handleBatchUpdate);
</script>
