<script setup lang="ts">
import { computed } from 'vue';
import { Settings, Lock, X, SkipBack, Play, Pause, SkipForward } from 'lucide-vue-next';
import { PlayPause, Previous, Next } from '../../wailsjs/go/main/App';
import ControlButton from './ControlButton.vue';
import { useUpdate } from '../composables/useUpdate';

interface Props {
    fileName?: string;
    state?: number; // 0 = stopped, 1 = playing, 2 = paused
}

const props = defineProps<Props>();

const emit = defineEmits<{
    'open-settings': [];
    'lock': [];
    'close': [];
}>();

const { hasUpdate } = useUpdate();
const isPlaying = computed(() => props.state === 2);

const displayFileName = computed(() => {
    if (!props.fileName) return 'No File';
    const name = props.fileName.split(/[\\/]/).pop() || '';
    return name.replace(/\.[^/.]+$/, '');
});
</script>

<template>
    <div class="absolute top-0 left-0 right-0 p-2 z-50 flex items-center justify-between group pointer-events-auto" :style="{ '--wails-draggable': 'drag' }">
        <!-- Title -->
        <div class="text-[12px] font-medium text-white/50 group-hover:text-white/90 bg-black/10 group-hover:bg-black/40 px-3 py-1.5 rounded-md transition-all truncate max-w-55 select-none backdrop-blur-sm flex items-center">
            {{ displayFileName }}
        </div>

        <!-- Center Controls (Play/Pause, Prev, Next) -->
        <div class="absolute left-1/2 -translate-x-1/2 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-300 ease-in-out">
            <ControlButton @click="Previous" title="Previous">
                <SkipBack :size="16" :stroke-width="2.5" />
            </ControlButton>
            
            <ControlButton @click="PlayPause" :title="isPlaying ? 'Pause' : 'Play'">
                <Pause v-if="isPlaying" :size="16" :stroke-width="2.5" />
                <Play v-else :size="16" :stroke-width="2.5" class="ml-0.5" />
            </ControlButton>
            
            <ControlButton @click="Next" title="Next">
                <SkipForward :size="16" :stroke-width="2.5" />
            </ControlButton>
        </div>

        <!-- Right Window Controls -->
        <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-300 ease-in-out">
            <div class="relative flex items-center justify-center">
                <ControlButton @click="emit('open-settings')" title="Settings">
                    <Settings :size="16" :stroke-width="2.5" />
                </ControlButton>
                <div v-if="hasUpdate" class="absolute top-[3px] right-[3px] w-[5px] h-[5px] bg-red-500 rounded-full shadow-[0_0_8px_rgba(239,68,68,1)] animate-pulse pointer-events-none"></div>
            </div>
            <ControlButton @click="emit('lock')" title="Lock Window">
                <Lock :size="16" :stroke-width="2.5" />
            </ControlButton>
            <ControlButton @click="emit('close')" isDanger title="Close">
                <X :size="16" :stroke-width="2.5" />
            </ControlButton>
        </div>
    </div>
</template>
