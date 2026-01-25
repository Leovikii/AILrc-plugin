<script setup lang="ts">
import { ref, watch } from 'vue';

interface Props {
    label: string;
    value: number;
    unit: string;
}

const props = defineProps<Props>();

const emit = defineEmits<{
    change: [value: number];
}>();

const localValue = ref(props.value.toString());

watch(() => props.value, (newValue) => {
    localValue.value = newValue.toString();
});

const commitChange = () => {
    const num = parseInt(localValue.value, 10);
    if (!isNaN(num) && num > 0) {
        emit('change', num);
    } else {
        localValue.value = props.value.toString();
    }
};

const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Enter') {
        (e.target as HTMLInputElement).blur();
    }
};
</script>

<template>
    <div class="flex justify-between items-center h-9">
        <span class="text-[11px] font-bold text-white/50 uppercase tracking-wider">{{ label }}</span>
        <div class="flex items-center bg-white/5 rounded-md border border-white/5 hover:border-white/20 focus-within:border-pink-500/50 focus-within:bg-white/10 transition-all h-full">
            <input
                type="number"
                v-model="localValue"
                @blur="commitChange"
                @keydown="handleKeyDown"
                class="w-16 bg-transparent text-right text-xs font-mono text-white/90 outline-none h-full pl-2"
                :style="{ '--wails-draggable': 'none' }"
            />
            <span class="text-[10px] text-white/30 font-bold px-2 pointer-events-none select-none">{{ unit }}</span>
        </div>
    </div>
</template>