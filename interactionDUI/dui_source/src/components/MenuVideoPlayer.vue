<template >
    <div class="video-container" v-if="item.video">
        <video :id="`video-${item.id}`" :src="item.video.url" :onloadstart="onLoadStart"
            :style="{ 'opacity': item.video.opacity }"></video>
        <div class="video-metadata">
            <div class="video-metadata__label" v-if="item.label">
                {{ item.label }}
            </div>
            <div class="video-metadata__description" v-if="item.description">
                {{ item.description }}
            </div>
            <div class="video-metadata__timecycle" :id="`video-timecycle-${item.id}`">

            </div>
            <div class="progress-container " v-if="item.video.progress">
                <div class="progressbar ">
                    <div :id="`video-${item.id}-progress`" class="progress video-offset" style="width: 0%;"> </div>
                </div>
            </div>
        </div>
    </div>
</template>
<script lang="ts" setup>
import { Option } from '../types/types';

const props = defineProps<{ item: Option }>()

function formatTime(seconds: number) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const remainingSeconds = Math.floor(seconds % 60);

    const formattedTime = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(remainingSeconds).padStart(2, '0')}`;

    return formattedTime;
}

const updateProgressBar = () => {
    const id = `video-${props.item.id}`;
    const videoElement = document.getElementById(id) as HTMLVideoElement | null;
    const videoTimecycle = document.getElementById(`video-timecycle-${props.item.id}`) as HTMLElement | null;

    if (!videoElement || !props.item.video || !videoTimecycle) return;

    const currentTime = videoElement.currentTime;
    const totalDuration = videoElement.duration;

    if (totalDuration === 0) return;

    const percentageCompleted = (currentTime / totalDuration) * 100;
    const progressBar = document.getElementById(`${id}-progress`) as HTMLElement | null;

    if (props.item.video.percent) {
        videoTimecycle.innerText = `${percentageCompleted.toFixed(2)}%`;
    } else if (props.item.video.timecycle) {
        videoTimecycle.innerText = formatTime(Math.floor(currentTime));
    }

    if (progressBar) {
        progressBar.style.width = `${Math.min(Math.max(percentageCompleted, 0), 100)}%`;
    }
};

const onLoadStart = async () => {
    const id = `video-${props.item.id}`;
    const videoElement = document.getElementById(id) as HTMLVideoElement;

    videoElement.currentTime = props.item.video?.currentTime || 0;
    videoElement.autoplay = props.item.video?.autoplay || true;
    videoElement.loop = props.item.video?.loop || false;

    if (typeof (props.item.video?.volume) === 'number')
        videoElement.volume = props.item.video?.volume;
    if (props.item.video?.progress)
        videoElement.ontimeupdate = updateProgressBar;
}

</script>
