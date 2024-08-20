<script lang="ts" setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { Option } from '../types/types';

const currentIndex = ref(0);
const slideInterval = ref<NodeJS.Timeout | null>(null);
const props = defineProps<{ item: Option }>();
const hasMultiplePictures = computed(() => Array.isArray(props.item.picture?.url));

const filterStyles = computed(() => {
    const {
        brightness = 100,
        contrast = 100,
        saturation = 100,
        hue = 0,
        blur = 0,
        grayscale = 0,
        sepia = 0,
        invert = 0,
    } = props.item.picture?.filters || {};

    // now we construct filter string
    return {
        filter: `brightness(${brightness}%) 
                 contrast(${contrast}%) 
                 saturate(${saturation}%) 
                 hue-rotate(${hue}deg) 
                 blur(${blur}px) 
                 grayscale(${grayscale}%) 
                 sepia(${sepia}%) 
                 invert(${invert}%)`,
    };
});

const pictureStyle = computed(() => ({
    ...filterStyles.value,
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

enum TransitionType {
    LEFT = 'slide-left',
    UP = 'slide-up',
    RIGHT = 'slide-right',
    DOWN = 'slide-down',
}

const transitionTypeIndex: { [key: string]: number } = {
    [TransitionType.LEFT]: 0,
    [TransitionType.UP]: 1,
    [TransitionType.RIGHT]: 2,
    [TransitionType.DOWN]: 3,
};

const getTransitionTypeIndex = (): number => {
    const transition = props.item.picture?.transition;
    if (!transition) return transitionTypeIndex['slide-down'];

    return transitionTypeIndex[transition] ?? transitionTypeIndex['slide-down'];
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
        <div v-if="hasMultiplePictures">
            <Transition :name="`slide-${getTransitionTypeIndex()}`" mode="out-in">
                <img
                    class="picture-container__image-source"
                    :key="generateKey(currentIndex)"
                    :src="item.picture?.url[currentIndex]"
                    :style="pictureStyle"
                />
            </Transition>
        </div>
        <img
            v-else
            class="picture-container__image-source"
            :id="`picture-${item.id}`"
            :src="item.picture?.url"
            :style="pictureStyle"
            :class="borderClass"
        />
    </div>
</template>
<style scoped lang="scss">
.picture-container {
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
}

.slide-0-enter-active,
.slide-0-leave-active,
.slide-1-enter-active,
.slide-1-leave-active,
.slide-2-enter-active,
.slide-2-leave-active,
.slide-3-enter-active,
.slide-3-leave-active {
    transition:
        transform 0.5s ease,
        opacity 0.5s ease;
}

/* Slide from Left */
.slide-0-enter-from,
.slide-0-leave-to {
    opacity: 0;
    transform: translateX(-200px);
}

/* Slide from Up */
.slide-1-enter-from,
.slide-1-leave-to {
    opacity: 0;
    transform: translateY(-200px);
}

/* Slide from Right */
.slide-2-enter-from,
.slide-2-leave-to {
    opacity: 0;
    transform: translateX(200px);
}

/* Slide from Down */
.slide-3-enter-from,
.slide-3-leave-to {
    opacity: 0;
    transform: translateY(200px);
}
</style>
