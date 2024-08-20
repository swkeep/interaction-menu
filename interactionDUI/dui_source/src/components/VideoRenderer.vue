<template>
    <div v-if="item.video" class="video-container">
        <video
            ref="videoRef"
            class="video-container__video"
            :src="item.video.url"
            :style="{ opacity: item.video.opacity }"
            @loadstart="onLoadStart"
        />
        <div class="video-container__metadata">
            <div v-if="item.label" class="video-container__label">
                {{ item.label }}
            </div>
            <div v-if="item.description" class="video-container__description">
                {{ item.description }}
            </div>
            <div v-if="timecycle" class="video-container__timecycle">
                {{ timecycle }}
            </div>
            <div v-if="item.video.progress" class="progress-container">
                <div class="progress">
                    <Progressbar :value="percentage" />
                </div>
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { ref } from 'vue';
import Progressbar from './ProgressBar.vue';
import { Option } from '../types/types';
import { formatTime } from '../util';

const props = defineProps<{ item: Option }>();

const percentage = ref(0);
const timecycle = ref('');
const videoRef = ref<HTMLVideoElement | null>(null);

function updateProgressBar() {
    const video_element = videoRef.value;
    const video_data = props.item.video;
    if (!video_element || !video_data) return;
    const { currentTime, duration } = video_element;
    if (duration === 0) return;

    const percentageCompleted = (currentTime / duration) * 100;
    percentage.value = percentageCompleted;

    if (video_data.percent) {
        timecycle.value = `${percentageCompleted.toFixed(2)}%`;
    } else if (video_data.timecycle) {
        timecycle.value = formatTime(Math.floor(currentTime));
    }
}

function onLoadStart() {
    const video_element = videoRef.value;
    if (!video_element || !props.item.video) return;

    video_element.currentTime = props.item.video.currentTime || 0;
    video_element.autoplay = props.item.video.autoplay ?? true;
    video_element.loop = props.item.video.loop ?? false;

    if (typeof props.item.video.volume === 'number') {
        video_element.volume = props.item.video.volume;
    }

    if (props.item.video.progress) {
        video_element.ontimeupdate = updateProgressBar;
    }

    setTimeout(() => {
        video_element.play();
    }, 50);
}
</script>

<style lang="scss">
.video-container {
    &__metadata {
        position: absolute;
        width: 100%;
        height: 5.5rem;
        bottom: 0;
        left: 0.1rem;

        .progress-container {
            position: absolute;
            bottom: inherit;
            left: inherit;
            width: 100%;
        }
    }

    &__label {
        position: relative;
        font-size: 2.5rem;
        left: 0.5rem;
    }

    &__description {
        position: relative;
        left: 0.75rem;
        font-size: 1.5rem;
        color: rgba(245, 245, 220, 0.6);
    }

    &__timecycle {
        position: absolute;
        right: 0.75rem;
        bottom: 1rem;
        font-size: 1.5rem;
        text-align: center;
    }
}
</style>
