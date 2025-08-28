<template>
    <Transition name="fade" mode="out-in">
        <div
            class="menus-container"
            id="menus-container"
            :class="{ 'menus-container--glow': interaction_menu.glow }"
            :style="{ width: interaction_menu.width || 'fit-content', maxHeight: '1400px' }"
            v-if="focusTracker.menu"
        >
            <TransitionGroup name="list-delete">
                <div
                    class="menu"
                    v-for="menu in Array.from(interaction_menu.menus.values())"
                    :key="menu.id"
                    :data-menu-id="menu.id"
                    :data-hide="menu.flags.hide"
                    :data-invoking-resource="menu?.metadata?.invokingResource"
                    :class="{
                        'menu--hidden': menu.flags.hide,
                    }"
                >
                    <template v-if="!menu.flags.hide">
                        <TransitionGroup :name="menu.flags.skip_animation ? '' : 'list'">
                            <template v-for="item in Array.from(menu.options.values())" :key="item.vid">
                                <div v-if="!item.flags?.hide" class="menu__option" :data-vid="item.vid">
                                    <Component
                                        :is="getFieldComponent(item)"
                                        :item="item"
                                        :selected="interaction_menu.selected"
                                    />
                                </div>
                            </template>
                        </TransitionGroup>
                    </template>
                </div>
            </TransitionGroup>
        </div>
    </Transition>
</template>

<script lang="ts" setup>
import { subscribe } from '../util';
import { computed, defineAsyncComponent, ref, provide } from 'vue';
import { FocusTracker, FocusTrackerT, InteractionMenu, Option } from '../types/types';

const menuComponents = {
    audioPlayer: defineAsyncComponent(() => import('../components/AudioPlayer.vue')),
    videoPlayer: defineAsyncComponent(() => import('../components/VideoRenderer.vue')),
    pictureViewer: defineAsyncComponent(() => import('../components/ImageRenderer.vue')),
    menuOption: defineAsyncComponent(() => import('../components/MenuOption.vue')),
    progressbar: defineAsyncComponent(() => import('../components/MenuProgressbar.vue')),
    templateRenderer: defineAsyncComponent(() => import('../components/TemplateRenderer.vue')),
};

defineProps<{ focusTracker: FocusTracker }>();

const emit = defineEmits<{
    (event: 'setVisible', name: FocusTrackerT, value: boolean): void;
}>();

const getFieldComponent = computed(() => (item: Option) => {
    if (item.flags?.hide) return;
    if (item.video) return menuComponents.videoPlayer;
    if (item.audio) return menuComponents.audioPlayer;
    if (item.picture) return menuComponents.pictureViewer;
    if (item.progress) return menuComponents.progressbar;
    if (item.template) return menuComponents.templateRenderer;
    return menuComponents.menuOption;
});

const default_menu_state = (): InteractionMenu => ({
    indicator: undefined,
    menus: new Map(),
    selected: [],
    theme: 'default',
    glow: false,
    width: 'fit-content',
});

const interaction_menu = ref<InteractionMenu>(default_menu_state());
const first_selected = ref(null);
provide('first_selected', first_selected);

const reset_state = () => {
    interaction_menu.value = default_menu_state();
};

const emit_visibility = (visible: boolean) => {
    emit('setVisible', 'menu', visible);
};

const hide_menu = () => {
    emit_visibility(false);
    reset_state();
};

const show_menu = (data: InteractionMenu) => {
    if (!data || !data.menus) return;
    reset_state();

    interaction_menu.value.glow = data.glow ?? false;
    interaction_menu.value.selected = data.selected ?? [];
    interaction_menu.value.width = data.width ?? 'fit-content';

    interaction_menu.value.menus = new Map(
        Array.from(data.menus.values()).map((menu) => [
            menu.id,
            {
                ...menu,
                options: new Map(Array.from(menu.options.values()).map((opt) => [opt.vid, opt])),
            },
        ]),
    );

    emit_visibility(true);
};

const update_selected = (data: any) => {
    interaction_menu.value.selected = data;
    if (first_selected.value == null) first_selected.value = data;

    if (first_selected.value && first_selected.value === data) {
        document.getElementById('menus-container')?.scrollTo(0, 0);
    }
};

const set_menu_visibility = ({ id, visibility }: { id: string | number; visibility: boolean }) => {
    const menu = interaction_menu.value.menus.get(id);
    if (menu) menu.flags.hide = !visibility;
};

const mark_menu_deleted = (ids: (number | string)[]) => {
    for (let i = 0; i < ids.length; i++) {
        interaction_menu.value.menus.delete(ids[i]);
    }
};

type OptionUpdate = {
    menuId: string | number;
    option: Partial<Option> & { vid: string | number; update_type?: string };
};

const batch_update_options = (updates: { [key: string]: OptionUpdate }) => {
    for (const { menuId, option } of Object.values(updates)) {
        const menu = interaction_menu.value.menus.get(menuId);
        if (!menu) continue;

        const existing_option = menu.options.get(option.vid);
        if (!existing_option) continue;

        const update_type = option.update_type ?? 'partial_update';
        Object.entries(option).forEach(([key, value]) => {
            if (key === 'vid' || key === 'update_type') return;

            if (key === 'template_data' && existing_option.template) {
                // Merge template_data changes instead of overwriting
                existing_option.template_data = {
                    ...existing_option.template_data,
                    ...(value as object),
                };
            } else {
                (existing_option as any)[key] = value;
            }
        });

        menu.options.set(option.vid, existing_option);
        // console.debug(`${menuId} | [${update_type}] updated option`, option.vid, option);
    }
};
subscribe('interactionMenu:hideMenu', hide_menu);
subscribe('interactionMenu:menu:show', show_menu);
subscribe('interactionMenu:menu:selectedUpdate', update_selected);
subscribe('interactionMenu:menu:setVisibility', set_menu_visibility);
subscribe('interactionMenu:menu:delete', mark_menu_deleted);
subscribe('interactionMenu:menu:batchUpdate', batch_update_options);
</script>
