<script lang="ts" setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import Progressbar from './ProgressBar.vue';
import { Option } from '../types/types';
import { formatTime } from '../util';

const props = defineProps<{ item: Option }>();
const audioId = `audio-${Math.random().toString(36).substr(2, 9)}`;

let audioElement: HTMLAudioElement | null = null;

const percentage = ref(0);
const timecycle = ref('');

function updateProgressBar() {
    if (!audioElement || !props.item.audio) return;
    const { currentTime, duration } = audioElement;
    if (duration === 0) return;

    const percentageCompleted = (currentTime / duration) * 100;
    percentage.value = percentageCompleted;

    if (props.item.audio.percent) {
        timecycle.value = `${percentageCompleted.toFixed(2)}%`;
    } else {
        timecycle.value = formatTime(Math.floor(currentTime));
    }
}

function onLoadStart() {
    if (!audioElement || !props.item.audio) return;

    audioElement.currentTime = props.item.audio.currentTime || 0;
    audioElement.autoplay = props.item.audio.autoplay ?? true;
    audioElement.loop = props.item.audio.loop ?? false;

    if (typeof props.item.audio.volume === 'number') {
        audioElement.volume = props.item.audio.volume;
    }

    if (props.item.audio.progress) {
        audioElement.ontimeupdate = updateProgressBar;
    }

    setTimeout(() => {
        audioElement?.play();
    }, 150);
}

const isActive = computed(() => {
    if (!props.item.audio) return false;
    if (props.item.flags?.hide) return false;

    return props.item.flags?.canInteract ?? true;
});

onMounted(() => {
    audioElement = document.getElementById(audioId) as HTMLAudioElement;
    if (audioElement) {
        audioElement.addEventListener('loadstart', onLoadStart);
    }
});

onUnmounted(() => {
    if (audioElement) {
        audioElement.pause();
        audioElement.ontimeupdate = null;
        audioElement.onended = null;
        audioElement.removeEventListener('loadstart', onLoadStart);
        audioElement = null;
    }
});
</script>

<template>
    <div v-if="item.audio && isActive" class="audio-container">
        <audio :id="audioId" class="audio-container__audio" :src="item.audio.url"></audio>
        <div class="audio-container__metadata">
            <div v-if="item.label" class="audio-container__label">
                {{ item.label }}
            </div>
            <div v-if="item.audio.progress" class="progress-container">
                <Progressbar :value="percentage" :label="timecycle" />
            </div>
        </div>
    </div>
</template>

<style lang="scss">
.audio-container {
    padding: 0.3em 0.7em 0.3em 0.3em;

    &__metadata {
        position: relative;
        width: 100%;

        .progress-container {
            width: 100%;
        }
    }

    &__label {
        font-size: 1.5rem;
        margin-bottom: 0.5rem;
    }

    &__description {
        font-size: 1.2rem;
        color: rgba(245, 245, 220, 0.6);
        margin-bottom: 0.5rem;
    }

    &__timecycle {
        font-size: 1rem;
        text-align: right;
    }
}
</style>
