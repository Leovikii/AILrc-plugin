<script setup lang="ts">
import { X } from 'lucide-vue-next';
import type { AppConfig } from '../types';
import CustomSlider from './CustomSlider.vue';
import NumberInputRow from './NumberInputRow.vue';

interface Props {
    config: AppConfig;
}

const props = defineProps<Props>();

const emit = defineEmits<{
    change: [config: AppConfig];
    close: [];
}>();

const handleChange = (key: keyof AppConfig, value: any) => {
    if (typeof value === 'number') {
        value = parseFloat(value.toFixed(2));
    }
    emit('change', { ...props.config, [key]: value });
};
</script>

<template>
    <div class="flex flex-col h-full text-white/90 px-6 py-5 select-none animate-in fade-in duration-300 bg-black/40 backdrop-blur-md">
        <div class="flex justify-between items-center mb-8 border-b border-white/5 pb-3 shrink-0">
            <h2 class="text-xs font-black tracking-[0.25em] text-pink-500 uppercase">Settings</h2>
            <button @click="emit('close')" class="p-1.5 -mr-2 text-white/40 hover:text-white transition-colors" :style="{ '--wails-draggable': 'none' }">
                <X :size="18" :stroke-width="2.5" />
            </button>
        </div>

        <div class="flex-1 space-y-8 overflow-y-auto pr-1 scrollbar-hide min-h-0" :style="{ '--wails-draggable': 'none' }">
            <!-- Typography Section -->
            <div class="space-y-6">
                <div class="text-[10px] font-black text-white/20 uppercase tracking-[0.15em]">Typography</div>

                <CustomSlider
                    label="Font Size"
                    :value="config.fontSize"
                    :min="10"
                    :max="120"
                    :step="1"
                    unit=" PT"
                    @change="(v) => handleChange('fontSize', v)"
                />

                <CustomSlider
                    label="Text Opacity"
                    :value="config.textOpacity"
                    :min="0.1"
                    :max="1"
                    :step="0.05"
                    :display-fn="(v) => `${Math.round(v * 100)}%`"
                    @change="(v) => handleChange('textOpacity', v)"
                />
            </div>

            <!-- Appearance Section -->
            <div class="space-y-6">
                <div class="text-[10px] font-black text-white/20 uppercase tracking-[0.15em]">Appearance</div>
                <div class="grid grid-cols-2 gap-4">
                    <div class="bg-white/5 rounded-lg p-3 border border-white/5 flex flex-col gap-2.5 hover:bg-white/10 transition-colors" :style="{ '--wails-draggable': 'none' }">
                        <label class="text-[10px] font-bold text-white/50 uppercase">Fill Color</label>
                        <div class="flex items-center gap-3 relative h-8">
                            <input type="color" :value="config.fontColor" @input="(e) => handleChange('fontColor', (e.target as HTMLInputElement).value)" class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10" />
                            <div class="w-full h-full rounded shadow-sm ring-1 ring-white/10" :style="{ backgroundColor: config.fontColor }" />
                        </div>
                    </div>
                    <div class="bg-white/5 rounded-lg p-3 border border-white/5 flex flex-col gap-2.5 hover:bg-white/10 transition-colors" :style="{ '--wails-draggable': 'none' }">
                        <label class="text-[10px] font-bold text-white/50 uppercase">Glow Color</label>
                        <div class="flex items-center gap-3 relative h-8">
                            <input type="color" :value="config.strokeColor" @input="(e) => handleChange('strokeColor', (e.target as HTMLInputElement).value)" class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10" />
                            <div class="w-full h-full rounded shadow-sm ring-1 ring-white/10" :style="{ backgroundColor: config.strokeColor }" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Window Section -->
            <div class="space-y-6">
                <div class="text-[10px] font-black text-white/20 uppercase tracking-[0.15em]">Window</div>

                <NumberInputRow
                    label="Window Width"
                    :value="config.windowWidth || 800"
                    unit="PX"
                    @change="(v) => handleChange('windowWidth', v)"
                />

                <CustomSlider
                    label="Background Opacity"
                    :value="config.bgOpacity"
                    :min="0"
                    :max="1"
                    :step="0.05"
                    :display-fn="(v) => `${Math.round(v * 100)}%`"
                    @change="(v) => handleChange('bgOpacity', v)"
                />
            </div>
        </div>

        <div class="mt-4 pt-4 border-t border-white/5 shrink-0">
            <button @click="emit('close')" class="w-full py-3 bg-pink-600 hover:bg-pink-500 text-white text-[11px] font-bold rounded-lg shadow-lg shadow-pink-900/40 transition-all active:scale-[0.98] flex items-center justify-center gap-2" :style="{ '--wails-draggable': 'none' }">
                <span>APPLY & CLOSE</span>
            </button>
        </div>
    </div>
</template>
