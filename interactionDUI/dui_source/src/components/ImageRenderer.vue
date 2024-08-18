<script lang="ts" setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { Option } from '../types/types';

const currentIndex = ref(0);
const slideInterval = ref<NodeJS.Timeout | null>(null);
const props = defineProps<{ item: Option }>();
const hasMultiplePictures = computed(() => Array.isArray(props.item.picture?.url));

const pictureStyle = computed(() => ({
    opacity: props.item.picture?.opacity,
    width: props.item.picture?.width,
    height: props.item.picture?.height,
}));

const borderClass = computed(() => ({
    'border-dashed': props.item.picture?.border === 'dash',
    'border-solid': props.item.picture?.border === 'solid',
}));

const generateKey = (index: number) => `picture-${props.item.id}-${index}`;

const startSliding = () => {
    const interval = props.item?.picture?.interval ?? 3000;

    slideInterval.value = setInterval(() => {
        if (props.item.picture?.url && hasMultiplePictures.value) {
            currentIndex.value = (currentIndex.value + 1) % props.item.picture.url.length;
        }
    }, interval);
};

const stopSliding = () => {
    if (slideInterval.value === null) return;
    clearInterval(slideInterval.value);
};

onMounted(() => {
    if (!hasMultiplePictures.value) return;
    startSliding();
});

onUnmounted(() => {
    stopSliding();
});
</script>
<template>
    <div class="picture-container">
        <TransitionGroup name="slide" tag="div" class="picture-container__slide-group">
            <img
                v-if="hasMultiplePictures"
                class="picture-container__image-source"
                :key="generateKey(currentIndex)"
                :src="item.picture.url[currentIndex]"
                :style="pictureStyle"
            />
            <img
                v-else
                class="picture-container__image-source"
                :id="`picture-${item.id}`"
                :src="item.picture?.url"
                :style="pictureStyle"
                :class="borderClass"
            />
        </TransitionGroup>
    </div>
</template>

<style scoped lang="scss">
.picture-container {
    // need it for list animation
    width: var(--max-width);
    display: flex;
    justify-content: space-evenly;
    user-select: none;
    pointer-events: none;
    padding: 0.2rem;

    &__image-source {
        width: 100%;
        border-radius: 1rem;

        &.border-dashed {
            border: #faebd712 5px dashed;
        }

        &.border-solid {
            border: #faebd712 5px solid;
        }
    }

    &__slide-group {
        position: relative;
        overflow: hidden;
        transition: height 0.5s ease;
    }
}

.slide-enter-active,
.slide-leave-active {
    transition:
        transform 0.5s ease,
        opacity 0.5s ease;
}

.slide-enter-from,
.slide-leave-to {
    opacity: 0;
    transform: translateY(200px);
}

.slide-leave-active {
    position: absolute;
}
</style>
