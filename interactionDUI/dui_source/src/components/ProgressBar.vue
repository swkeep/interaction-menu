<script lang="ts" setup>
import { computed } from 'vue';

const props = defineProps<{
    value: number;
    label?: string;
    percent?: boolean;
    type?: string;
}>();

const progressValue = (value: number) => {
    if (!value) return 0;
    const clampedProgress = Math.min(Math.max(value || 0, 0), 100);
    return Number.isFinite(clampedProgress) ? clampedProgress : 0;
};

const bar_width = computed(() => {
    return `width: ${progressValue(props.value)}%;`;
});

const progress_type = computed(() => {
    return props.type || 'info';
});
</script>

<template>
    <div class="container">
        <div v-if="label !== null" class="container__label">
            {{ label }}
        </div>

        <div class="progress">
            <div class="progress__container">
                <div class="progress__bar" :class="progress_type" :style="bar_width"></div>
            </div>
            <div v-if="percent" class="progress__percent">{{ progressValue(value).toFixed(2) }}%</div>
        </div>
    </div>
</template>

<style lang="scss" scoped>
.container {
    width: 100%;

    &__label {
        display: flex;
        justify-content: center;
        height: 3rem; // text goes out side of container
    }
}

.progress {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    min-width: 30rem;

    &__container {
        width: 100%;
    }

    &__percent {
        margin-left: 0.5rem;
    }

    &__bar {
        width: 0;
        height: 0.6rem;
        border-radius: 0.5rem;
        background: var(--primary-color);
        transition: width 0.2s ease;

        &.info {
            background: rgb(47, 123, 223);
        }

        &.success {
            background: rgb(0, 190, 0);
        }

        &.warning {
            background: orange;
        }

        &.error {
            background: rgb(255, 38, 0);
        }
    }
}
</style>
