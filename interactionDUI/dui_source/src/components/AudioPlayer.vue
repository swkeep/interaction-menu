<template>
    <div v-if="item.audio" class="audio-container">
        <audio ref="audioRef" class="audio-container__audio" :src="item.audio.url" @loadstart="onLoadStart"></audio>
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
<script lang="ts" setup>
import { ref } from 'vue';
import Progressbar from './ProgressBar.vue';
import { Option } from '../types/types';
import { formatTime } from '../util';

const props = defineProps<{ item: Option }>();

const percentage = ref(0);
const timecycle = ref('');
const audioRef = ref<HTMLAudioElement | null>(null);

function updateProgressBar() {
    const audio_element = audioRef.value;
    const audio_data = props.item.audio;
    if (!audio_element || !audio_data) return;
    const { currentTime, duration } = audio_element;
    if (duration === 0) return;

    const percentageCompleted = (currentTime / duration) * 100;
    percentage.value = percentageCompleted;

    if (audio_data.percent) {
        timecycle.value = `${percentageCompleted.toFixed(2)}%`;
    } else {
        timecycle.value = formatTime(Math.floor(currentTime));
    }
}

function onLoadStart() {
    const audio_element = audioRef.value;
    if (!audio_element || !props.item.audio) return;

    audio_element.currentTime = props.item.audio.currentTime || 0;
    audio_element.autoplay = props.item.audio.autoplay ?? true;
    audio_element.loop = props.item.audio.loop ?? false;

    if (typeof props.item.audio.volume === 'number') {
        audio_element.volume = props.item.audio.volume;
    }

    if (props.item.audio.progress) {
        audio_element.ontimeupdate = updateProgressBar;
    }

    setTimeout(() => {
        audio_element.play();
    }, 150);
}
</script>
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
