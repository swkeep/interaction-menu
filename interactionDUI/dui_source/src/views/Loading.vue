<template >
    <Transition>
        <div class="spinner-box" v-if="focusTracker.loading">
            <!-- <span class="spinner-wave-out"></span> -->
            <span class="spinner-double-section-far"></span>
        </div>
    </Transition>
</template>
<script lang="ts" setup>
import { subscribe } from '../util';
import { FocusTracker } from '../types/types';

defineProps<{ focusTracker: FocusTracker }>()

const emit = defineEmits<{
    (event: 'setVisible', name: string, value: boolean): void
}>()

const setVisible = (val: boolean) => emit('setVisible', 'loading', val)

subscribe('interactionMenu:loading:show', async () => setVisible(true))
subscribe('interactionMenu:loading:hide', async () => setVisible(false))

</script>
<style lang="scss">
@use 'sass:math';
// source: https://codepen.io/zessx/pen/RNPKKK CodePen CSS spinners by zessx
// #TODO: add more loading types from https://codepen.io/vineethtrv/pen/NWxZqMM or anywhere else!

$inactive: #ff9900;
$active: tomato;
$speed: 1.2s;
$size: 100px;
$unit: math.div($size, 16);
$unit_half: math.div($unit, 2);

.spinner-box {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
}

%spinner {
    display: block;
    float: left;
    width: $size;
    height: $size;
    border-radius: 50%;
    border: $unit solid $inactive;
    animation: spinner $speed linear infinite;
}

@keyframes spinner {
    0% {
        transform: rotate(0);
        opacity: 0.5;
    }

    50% {
        opacity: 1;
    }

    100% {
        transform: rotate(360deg);
        opacity: 0.5;
    }
}

%spinner-wave-out,
.spinner-wave-out {
    @extend %spinner;
    box-shadow: (-$unit_half) (-$unit_half) 0 ($unit_half) $active;
}

/* Sections */
%spinner-double-section,
.spinner-double-section {
    @extend %spinner;
    position: relative;

    &:before,
    &:after {
        content: '';
        position: absolute;
        border-radius: 50%;
        border: $unit solid transparent;
        border-top-color: $active;
    }

    &:after {
        border-top-color: transparent;
        border-bottom-color: $active;
    }
}

%spinner-double-section-far,
.spinner-double-section-far {
    @extend %spinner-double-section;

    &:before,
    &:after {
        top: ($unit*-3);
        left: ($unit*-3);
        width: ($size + $unit*4);
        height: ($size + $unit*4);
    }
}
</style>