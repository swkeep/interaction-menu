<template>
    <div ref="host_el" class="label label--center"></div>
</template>

<script lang="ts" setup>
import { ref, watch, onMounted, onUnmounted, nextTick } from 'vue';
import DOMPurify from 'dompurify';
import type { Option } from '../types/types';
import { useHandlebarsHelpers } from '../composables/useHandlebarsHelpers';

interface TemplateCache {
    last_template_hash: string;
    last_data_hash: string;
    last_styles: string | null;
    last_content: string | null;
    compiled_template?: ((data: any) => string) | null;
}

const props = defineProps<{ item: Option }>();
const host_el = ref<HTMLElement | null>(null);
const shadow_root_ref = ref<ShadowRoot | null>(null);
const style_el = ref<HTMLStyleElement | null>(null);
const content_container = ref<HTMLDivElement | null>(null);
const handlebars = useHandlebarsHelpers();
const template_cache: TemplateCache = {
    last_template_hash: '',
    last_data_hash: '',
    last_styles: null,
    last_content: null,
    compiled_template: null,
};

const create_hash = (str: string): string => {
    let hash = 0;
    if (str.length === 0) return '0';
    for (let i = 0; i < str.length; i++) {
        const chr = str.charCodeAt(i);
        hash = (hash << 5) - hash + chr;
        hash |= 0;
    }
    return (hash >>> 0).toString(16);
};

const sanitize_html = (raw: string): string => {
    return DOMPurify.sanitize(raw, { FORCE_BODY: true });
};

/**
 * Extracts <style>...</style> blocks and returns remaining HTML content
 */
const separate_style_from_html = (html: string): { styles: string; content: string } => {
    const style_regex = /<style[^>]*>([\s\S]*?)<\/style>/gi;
    let styles_acc: string[] = [];
    const content = html.replace(style_regex, (_match, p1) => {
        if (p1) styles_acc.push(p1.trim());
        return '';
    });
    const styles = styles_acc.join('\n').trim();
    return { styles, content: content.trim() };
};

/** Compile template and cache compiled function per template */
const compile_template = (template: string): ((data: any) => string) | null => {
    if (!template) return null;
    try {
        return handlebars.compile(template);
    } catch (err) {
        console.error('handlebars compilation error:', err);
        return null;
    }
};

/**
 * Update the template output in the shadow DOM
 */
const update_template_content = (template: string, data: any) => {
    const shadow = shadow_root_ref.value;
    const style_node = style_el.value;
    const container = content_container.value;

    if (!shadow || !style_node || !container) return;

    if (!template) {
        if (container.innerHTML !== '') container.innerHTML = '';
        template_cache.last_template_hash = '';
        template_cache.last_data_hash = '';
        template_cache.last_styles = null;
        template_cache.last_content = null;
        template_cache.compiled_template = null;
        return;
    }

    const template_hash = create_hash(template);
    const data_string = JSON.stringify(data || {});
    const data_hash = create_hash(data_string);

    if (template_hash === template_cache.last_template_hash && data_hash === template_cache.last_data_hash) return;
    if (template_hash !== template_cache.last_template_hash)
        template_cache.compiled_template = compile_template(template);

    const compiled_fn = template_cache.compiled_template;
    if (!compiled_fn) return;

    let compiled_output = '';
    try {
        compiled_output = compiled_fn(data || {});
    } catch (err) {
        console.error('handlebars render error:', err);
        return;
    }

    const { styles, content } = separate_style_from_html(compiled_output);
    if (style_node.textContent !== styles) style_node.textContent = styles;

    const sanitized_content = sanitize_html(content);
    if (container.innerHTML !== sanitized_content) container.innerHTML = sanitized_content;

    template_cache.last_template_hash = template_hash;
    template_cache.last_data_hash = data_hash;
    template_cache.last_styles = styles;
    template_cache.last_content = sanitized_content;
};

onMounted(() => {
    const host = host_el.value;
    if (!host) return;

    const shadow = host.attachShadow({ mode: 'open' });
    shadow_root_ref.value = shadow;

    const style_node = document.createElement('style');
    shadow.appendChild(style_node);
    style_el.value = style_node;

    const content_node = document.createElement('div');
    content_node.className = 'template-content';
    Object.assign(content_node.style, {
        width: '100%',
        height: '100%',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
    });

    shadow.appendChild(content_node);
    content_container.value = content_node;

    nextTick(() => {
        update_template_content(props.item.template, props.item.template_data);
    });
});

onUnmounted(() => {
    // if (content_container.value) content_container.value.innerHTML = '';
    // if (style_el.value) style_el.value.textContent = '';
    shadow_root_ref.value = null;
    style_el.value = null;
    content_container.value = null;
    template_cache.compiled_template = null;
});

watch(
    () => [props.item.template, props.item.template_data] as const,
    ([template, data]) => {
        update_template_content(template, data);
    },
    { immediate: true, deep: true },
);
</script>
