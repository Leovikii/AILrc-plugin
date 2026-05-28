<script setup lang="ts">
import { computed } from 'vue';
import { Settings, Lock, X, SkipBack, Play, Pause, SkipForward } from 'lucide-vue-next';
import { PlayPause, Previous, Next } from '../../wailsjs/go/main/App';
import ControlButton from './ControlButton.vue';

interface Props {
    fileName?: string;
    state?: number;
}

const props = defineProps<Props>();

const emit = defineEmits<{
    openSettings: [];
    lock: [];
    close: [];
}>();

const displayFileName = computed(() => {
    if (!props.fileName) return 'No File';
    const name = props.fileName.split(/[\\/]/).pop() || '';
    return name.replace(/\.[^/.]+$/, '');
});

const isPlaying = computed(() => props.state === 2);
</script>

<template>
    <div class="absolute top-0 left-0 right-0 p-2 flex justify-between items-start z-50 group pointer-events-auto">
        <!-- Title -->
        <div class="text-[12px] font-medium text-white/50 group-hover:text-white/90 bg-black/10 group-hover:bg-black/40 px-3 py-1.5 rounded-md transition-all truncate max-w-55 select-none backdrop-blur-sm flex items-center">
            {{ displayFileName }}
        </div>

        <!-- Central Playback Controls -->
        <div class="absolute left-1/2 -translate-x-1/2 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-300 ease-in-out">
            <ControlButton @click="Previous()" title="Previous">
                <SkipBack :size="16" :stroke-width="2.5" />
            </ControlButton>
            <ControlButton @click="PlayPause()" title="Play/Pause">
                <Pause v-if="isPlaying" :size="16" :stroke-width="2.5" />
                <Play v-else :size="16" :stroke-width="2.5" />
            </ControlButton>
            <ControlButton @click="Next()" title="Next">
                <SkipForward :size="16" :stroke-width="2.5" />
            </ControlButton>
        </div>

        <!-- Right Window Controls -->
        <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-300 ease-in-out">
            <ControlButton @click="emit('openSettings')" title="Settings">
                <Settings :size="16" :stroke-width="2.5" />
            </ControlButton>
            <ControlButton @click="emit('lock')" title="Lock Window">
                <Lock :size="16" :stroke-width="2.5" />
            </ControlButton>
            <ControlButton @click="emit('close')" title="Close App" :is-danger="true">
                <X :size="16" :stroke-width="2.5" />
            </ControlButton>
        </div>
    </div>
</template>
