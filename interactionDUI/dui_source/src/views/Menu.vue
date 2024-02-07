<template >
    <Transition @after-leave="resetData">
        <div class="menu-container" :class="{ 'glow': Data.glow }" v-if="focusTracker.menu">
            <div class="menu" v-for="(menu, i) in Data.menus" :data-menuId="menu.id">

                <TransitionGroup name="slide" v-if="menu.flags.hide === false" appear>
                    <template v-for="(item, index) in menu.options" :key="index">
                        <div :class="{ 'menu-wrapper': true, 'no-margin': item.flags?.hide }" :data-id="index"
                            :data-vid="item.vid">
                            <Component :is="getFieldComponent(item)" :item="item" :selected="Data.selected" />
                        </div>
                    </template>
                </TransitionGroup>
            </div>
        </div>
    </Transition>
</template>
<script lang="ts" setup>
import { debug, subscribe } from '../util';
import { defineAsyncComponent, ref } from 'vue';
import { FocusTracker, InteractionMenu, Option } from '../types/types';

const menuComponents = {
    // @ts-ignore
    videoPlayer: defineAsyncComponent(() => import('../components/MenuVideoPlayer.vue')),
    // @ts-ignore
    pictureViewer: defineAsyncComponent(() => import('../components/MenuPictureViewer.vue')),
    // @ts-ignore
    menuLabel: defineAsyncComponent(() => import('../components/MenuLabel.vue')),
    // @ts-ignore
    progressbar: defineAsyncComponent(() => import('../components/MenuProgressbar.vue')),
    // @ts-ignore
    menuAction: defineAsyncComponent(() => import('../components/MenuAction.vue')),
};

defineProps<{ focusTracker: FocusTracker }>()

const emit = defineEmits<{
    (event: 'setVisible', name: string, value: boolean): void
}>()

const setVisible = (val: boolean) => emit('setVisible', 'menu', val)

const getFieldComponent = (item: Option) => {
    if (item.flags.hide) return;

    if (item.video) return menuComponents.videoPlayer;
    if (item.picture) return menuComponents.pictureViewer;
    if (item.progress) return menuComponents.progressbar;

    if (item.flags?.update || item.flags?.action || item.flags?.event) {
        return menuComponents.menuAction;
    }

    // Default case
    return menuComponents.menuLabel;
};

const defaultInteractionMenu = (): InteractionMenu => ({
    id: 0,
    indicator: undefined,
    loading: false,
    menus: [],
    selected: [],
    theme: 'default',
    glow: false
});

const Data = ref(defaultInteractionMenu());

const resetData = function () {
    Data.value = defaultInteractionMenu();
};

subscribe('interactionMenu:hideMenu', function () {
    setVisible(false)
    resetData()
})

subscribe('interactionMenu:menu:show', (data: InteractionMenu) => {
    if (!data.menus) return;
    resetData()

    Data.value.glow = data.glow
    Data.value.menus = data.menus
    Data.value.selected = data.selected

    setVisible(true)
})

subscribe('interactionMenu:menu:selectedUpdate', (data) => {
    Data.value.selected = data
});

subscribe('interactionMenu:menu:setVisibility', (data: any) => {
    // const menuMap = new Map(Data.value.menus.map(menu => [menu.id, menu]));
    // const menu = menuMap.get(data.id);

    // if (menu) {
    //     menu.flags.hide = data.hide;
    // }

    // #TODO: which one is better?
    for (const key in Data.value.menus) {
        const menu = Data.value.menus[key];

        if (menu.id == data.id) {
            menu.flags.hide = data.hide;
            break;
        }
    }
});

subscribe('interactionMenu:menu:batchUpdate', (data: { [key: string]: { menuId: string | number; option: Option } }) => {
    const menus = Data.value.menus;
    const updatedOptions = new Map<string | number, Option>();

    for (const [key, updatedElement] of Object.entries(data)) {
        updatedOptions.set(updatedElement.option.vid, updatedElement.option);
    }

    // copy of menus to avoid unnecessary updates
    const updatedMenus = menus.slice();

    for (const menu of updatedMenus) {
        for (const [key, option] of Object.entries(menu.options)) {
            const updatedOption = updatedOptions.get(option.vid);
            if (updatedOption) {
                menu.options[key] = updatedOption;
            }
        }
    }

    Data.value.menus = updatedMenus; // Assign the updated menus
});

</script>

<style>
.slide-enter-from {
    opacity: 0;
    transform: translateY(160px)
}

.slide-enter-active {
    transition: transform 1.4s ease,
        opacity 1.8s ease
}

.slide-move {
    transition: transform .4s
}
</style>