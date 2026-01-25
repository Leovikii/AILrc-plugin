<script setup lang="ts">
import { ref, computed } from 'vue';
import { hexToRgba } from "../utils/color";
import type { AppConfig } from "../types";

interface Props {
    mainText: string;
    subText: string;
    config: AppConfig;
}

const props = defineProps<Props>();

const lyricRef = ref<HTMLDivElement>();

const textColor = computed(() => hexToRgba(props.config.fontColor, props.config.textOpacity));
const glowColor = computed(() => hexToRgba(props.config.strokeColor, props.config.textOpacity * 0.6));
const deepShadow = computed(() => hexToRgba(props.config.strokeColor, props.config.textOpacity * 0.9));

const mainTextStyle = computed(() => ({
    fontSize: `${props.config.fontSize}px`,
    fontWeight: 800,
    color: textColor.value,
    textShadow: `0 0 1px ${deepShadow.value}, 0 2px 4px ${glowColor.value}, 0 0 10px ${glowColor.value}`,
    fontFamily: '"Microsoft YaHei", sans-serif',
    lineHeight: '1.2',
    width: '100%'
}));

const subTextStyle = computed(() => ({
    fontSize: `${Math.max(14, props.config.fontSize * 0.55)}px`,
    fontWeight: 500,
    color: textColor.value,
    textShadow: `0 1px 2px ${deepShadow.value}`,
    fontFamily: '"Microsoft YaHei", sans-serif',
    lineHeight: '1.3',
    width: '100%',
    opacity: 0.85
}));

defineExpose({ lyricRef });
</script>

<template>
    <div
        ref="lyricRef"
        class="pointer-events-none flex flex-col items-center justify-center p-2 w-full h-auto"
    >
        <div
            v-memo="[mainText, mainTextStyle]"
            class="leading-tight tracking-wide wrap-break-word whitespace-pre-wrap text-center"
            :style="mainTextStyle"
        >
            {{ mainText }}
        </div>

        <div
            v-if="subText"
            v-memo="[subText, subTextStyle]"
            class="leading-tight tracking-wide wrap-break-word whitespace-pre-wrap text-center mt-1.5"
            :style="subTextStyle"
        >
            {{ subText }}
        </div>
    </div>
</template>
