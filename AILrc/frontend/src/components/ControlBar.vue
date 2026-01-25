<script setup lang="ts">
import { computed } from 'vue';
import { Settings, Lock, X } from 'lucide-vue-next';

interface Props {
    fileName?: string;
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
</script>

<template>
    <div class="absolute top-0 left-0 right-0 p-2 flex justify-between items-start z-50 group pointer-events-auto">
        <div class="text-[11px] font-medium text-white/50 group-hover:text-white/90 bg-black/10 group-hover:bg-black/40 px-2 py-1 rounded-md transition-all truncate max-w-55 select-none backdrop-blur-sm">
            {{ displayFileName }}
        </div>

        <div class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-300 ease-in-out">
            <button
                @click="emit('openSettings')"
                class="p-1.5 hover:bg-white/10 rounded-md text-white/50 hover:text-white transition-colors cursor-pointer"
                title="Settings"
                :style="{ '--wails-draggable': 'none' }"
            >
                <Settings :size="14" :stroke-width="2.5" />
            </button>
            <button
                @click="emit('lock')"
                class="p-1.5 hover:bg-white/10 rounded-md text-white/50 hover:text-white transition-colors cursor-pointer"
                title="Lock Window"
                :style="{ '--wails-draggable': 'none' }"
            >
                <Lock :size="14" :stroke-width="2.5" />
            </button>
            <button
                @click="emit('close')"
                class="p-1.5 hover:bg-red-500/20 hover:text-red-400 rounded-md text-white/50 transition-colors cursor-pointer"
                title="Close App"
                :style="{ '--wails-draggable': 'none' }"
            >
                <X :size="14" :stroke-width="2.5" />
            </button>
        </div>
    </div>
</template>
