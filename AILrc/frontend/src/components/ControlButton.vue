<script setup lang="ts">
interface Props {
    title?: string;
    isDanger?: boolean;
}

defineProps<Props>();
const emit = defineEmits<{ click: [] }>();
</script>

<template>
    <button
        @click="emit('click')"
        :class="[
            'p-1.5 rounded-md transition-colors cursor-pointer flex items-center justify-center',
            isDanger 
                ? 'text-white/60 hover:text-red-400 hover:bg-red-500/20' 
                : 'text-white/60 hover:text-white hover:bg-white/10'
        ]"
        :style="{ '--wails-draggable': 'none' }"
        :title="title"
    >
        <slot />
    </button>
</template>
