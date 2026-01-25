<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from 'vue';
import { SetWindowClickThrough, QuitApp, ResizeWindow } from "../wailsjs/go/main/App";
import { EventsOn } from "../wailsjs/runtime/runtime";
import { useAimp } from './composables/useAimp';
import { useLyrics } from './composables/useLyrics';
import { useConfig } from './composables/useConfig';
import ControlBar from './components/ControlBar.vue';
import LyricRenderer from './components/LyricRenderer.vue';
import SettingsPanel from './components/SettingsPanel.vue';

const isLocked = ref(false);
const isSettingsOpen = ref(false);

const { config, setConfig, save: saveConfig, isLoaded } = useConfig();
const { musicInfo, playerState } = useAimp();
const { mainText, subText } = useLyrics(
    computed(() => musicInfo.value?.FileName),
    computed(() => playerState.value?.Position)
);

const lyricRef = ref<InstanceType<typeof LyricRenderer>>();
const resizeTimeoutRef = ref<number | null>(null);
const isResizingRef = ref(false);

onMounted(() => {
    if (!config.value.windowWidth) {
        setConfig({ ...config.value, windowWidth: window.innerWidth });
    }

    const cancel = EventsOn('lock_state_change', (locked: boolean) => {
        isLocked.value = locked;
    });

    onUnmounted(() => cancel());
});

watch(isLocked, (locked) => {
    SetWindowClickThrough(locked);
});

const standardHeight = computed(() => {
    const safeMultiplier = 3.5;
    const basePadding = 40;
    return Math.ceil((config.value.fontSize * safeMultiplier) + basePadding);
});

const calculateTargetHeight = (contentHeight: number) => {
    const padding = 20;
    return Math.ceil(Math.max(contentHeight + padding, standardHeight.value));
};

onMounted(() => {
    const handleResize = () => {
        if (isSettingsOpen.value) return;
        
        isResizingRef.value = true;
        const currentW = window.innerWidth;
        const currentH = window.innerHeight;

        let targetH = standardHeight.value;
        if (lyricRef.value?.lyricRef) {
            targetH = calculateTargetHeight(lyricRef.value.lyricRef.offsetHeight);
        }

        if (isLoaded.value && Math.abs(currentW - config.value.windowWidth) > 5) {
            if (resizeTimeoutRef.value) clearTimeout(resizeTimeoutRef.value);
            resizeTimeoutRef.value = window.setTimeout(() => {
                const newConfig = { ...config.value, windowWidth: currentW };
                setConfig(newConfig);
                saveConfig(newConfig);
                isResizingRef.value = false;
            }, 200);
        }

        if (Math.abs(currentH - targetH) > 5) {
            ResizeWindow(currentW, targetH);
        }
    };

    window.addEventListener('resize', handleResize);
    onUnmounted(() => window.removeEventListener('resize', handleResize));
});

watch(
    [isSettingsOpen, mainText, subText, () => config.value.fontSize, () => config.value.windowWidth],
    async () => {
        await nextTick();
        
        if (isSettingsOpen.value) {
            ResizeWindow(400, 520);
        } else {
            if (lyricRef.value?.lyricRef) {
                const targetH = calculateTargetHeight(lyricRef.value.lyricRef.offsetHeight);
                const targetW = config.value.windowWidth || window.innerWidth;
                ResizeWindow(Math.ceil(targetW), Math.ceil(targetH));
            }
        }
    },
    { flush: 'post' }
);

const handleOpenSettings = () => {
    setConfig({ ...config.value, windowWidth: window.innerWidth });
    isSettingsOpen.value = true;
};

const handleCloseSettings = () => {
    saveConfig(config.value);
    isSettingsOpen.value = false;
};

const currentBgOpacity = computed(() => 
    isSettingsOpen.value ? 0.95 : config.value.bgOpacity
);
</script>

<template>
    <div 
        class="anim-basic w-screen h-screen overflow-hidden flex flex-col relative border border-white/10 rounded-xl shadow-2xl"
        :style="{ 
            '--wails-draggable': isLocked ? 'none' : 'drag',
            backgroundColor: `rgba(0, 0, 0, ${currentBgOpacity})`
        }"
    >
        <div :class="['flex-1 flex flex-col w-full h-full opacity-100 anim-fade']">
            <SettingsPanel 
                v-if="isSettingsOpen"
                :config="config"
                @change="setConfig"
                @close="handleCloseSettings"
            />
            <template v-else>
                <ControlBar 
                    v-if="!isLocked"
                    :file-name="musicInfo?.FileName"
                    @open-settings="handleOpenSettings"
                    @lock="isLocked = true"
                    @close="QuitApp"
                />
                <div class="flex-1 flex items-center justify-center w-full min-h-0 px-4">
                    <LyricRenderer 
                        ref="lyricRef"
                        :main-text="mainText"
                        :sub-text="subText"
                        :config="config"
                    />
                </div>
            </template>
        </div>
    </div>
</template>
