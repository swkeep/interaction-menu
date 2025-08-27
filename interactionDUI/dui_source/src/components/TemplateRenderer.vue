<template>
    <div ref="host" class="label label--center"></div>
</template>

<script lang="ts" setup>
import { ref, watch, onMounted, type Ref } from 'vue';
import DOMPurify from 'dompurify';
import type { Option } from '../types/types';
import { useHandlebarsHelpers } from '../composables/useHandlebarsHelpers';

const props = defineProps<{ item: Option }>();
const host: Ref<HTMLElement | null> = ref(null);
const shadowRootRef: Ref<ShadowRoot | null> = ref(null);
const style_el: Ref<HTMLStyleElement | null> = ref(null);
const content_container: Ref<HTMLDivElement | null> = ref(null);

// initialize helpers once
const Handlebars = useHandlebarsHelpers();

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

function compileTemplate(template: string, data: any): string {
    try {
        const compiledTemplate = Handlebars.compile(template);
        return compiledTemplate(data || {});
    } catch (error) {
        console.error('Handlebars compilation error:', error);
        return '';
    }
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
    contentNode.style.cssText = 'width:100%;height:100%;display:flex;justify-content:center;align-items:center;';
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

        const out = compileTemplate(template, data);
        const { styles, content } = separate_style_from_html(out);

        if (styleNode.textContent !== styles) styleNode.textContent = styles;
        container.innerHTML = sanitize_html(content);
    },
    { immediate: true },
);
</script>
