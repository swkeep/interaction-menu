<template>
    <div ref="host" class="label label--center"></div>
</template>

<script lang="ts" setup>
import { ref, watch, onMounted, onBeforeUnmount, type Ref } from 'vue';
import DOMPurify from 'dompurify';
import type { Option } from '../types/types';

const props = defineProps<{ item: Option }>();
const host: Ref<HTMLElement | null> = ref(null);
const shadowRootRef: Ref<ShadowRoot | null> = ref(null);
const style_el: Ref<HTMLStyleElement | null> = ref(null);
const content_container: Ref<HTMLDivElement | null> = ref(null);

function sanitize_html(raw: string): string {
    return DOMPurify.sanitize(raw, { FORCE_BODY: true });
}

/** pull <style> blocks out of a string of HTML */
function separate_style_from_html(html: string): { styles: string; content: string } {
    const tmp = document.createElement('div');
    tmp.innerHTML = html;

    const styleEls = Array.from(tmp.querySelectorAll('style'));
    const styles = styleEls.map((el) => el.innerHTML).join('\n');
    styleEls.forEach((el) => el.remove());

    return { styles, content: tmp.innerHTML };
}

onMounted(() => {
    const hostEl = host.value;
    if (!hostEl) return;

    const shadow = hostEl.attachShadow({ mode: 'open' });
    shadowRootRef.value = shadow;

    const styleNode = document.createElement('style');
    shadow.appendChild(styleNode);
    style_el.value = styleNode;

    const contentNode = document.createElement('div');
    contentNode.style.width = '100%';
    contentNode.style.height = '100%';
    contentNode.style.display = 'flex';
    contentNode.style.justifyContent = 'center';
    contentNode.style.alignItems = 'center';
    shadow.appendChild(contentNode);
    content_container.value = contentNode;
});

watch(
    () => [props.item.template, props.item.template_data] as const,
    ([template, data]) => {
        const shadow = shadowRootRef.value;
        const styleNode = style_el.value;
        const container = content_container.value;

        if (!shadow || !styleNode || !container) return;
        if (!template) {
            container.innerHTML = '';
            return;
        }

        // interpolate {{ key }} tokens
        let filled = template;
        if (data) {
            for (const [key, val] of Object.entries(data)) {
                const token = new RegExp(`{{\\s*${key}\\s*}}`, 'g');
                filled = filled.replace(token, String(val));
            }
        }

        const { styles, content } = separate_style_from_html(filled);
        if (styleNode.textContent !== styles) styleNode.textContent = styles;
        container.innerHTML = sanitize_html(content);
    },
    { immediate: true },
);
</script>
