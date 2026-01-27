import { ref, watch, type Ref, type ComputedRef } from 'vue';
import { FetchLyrics } from "../../wailsjs/go/main/App";
import { LyricLine } from "../types";

export function useLyrics(
    fileName: Ref<string | undefined> | ComputedRef<string | undefined>,
    position: Ref<number | undefined> | ComputedRef<number | undefined>
) {
    const lyrics = ref<LyricLine[]>([]);
    const mainText = ref<string>("AILrc Ready");
    const subText = ref<string>("");

    watch(fileName, async (newFileName) => {
        if (newFileName) {
            const lrc = await FetchLyrics(newFileName);
            lyrics.value = lrc || [];
        }
    }, { immediate: true });

    let throttleTimer: number | null = null;
    let lastPosition: number | undefined = undefined;

    watch([position, lyrics], ([newPosition, newLyrics]) => {
        if (newPosition === undefined || newLyrics.length === 0) return;

        if (throttleTimer !== null) {
            lastPosition = newPosition;
            return;
        }

        const updateLyric = (pos: number) => {
            let left = 0;
            let right = newLyrics.length - 1;
            let idx = -1;

            while (left <= right) {
                const mid = Math.floor((left + right) / 2);
                if (newLyrics[mid].time <= pos) {
                    idx = mid;
                    left = mid + 1;
                } else {
                    right = mid - 1;
                }
            }

            if (idx !== -1) {
                mainText.value = newLyrics[idx].mainText;
                subText.value = newLyrics[idx].subText;
            } else {
                if (pos < newLyrics[0].time) {
                    mainText.value = "...";
                    subText.value = "";
                }
            }
        };

        updateLyric(newPosition);

        throttleTimer = window.setTimeout(() => {
            throttleTimer = null;
            if (lastPosition !== undefined && lastPosition !== newPosition) {
                updateLyric(lastPosition);
                lastPosition = undefined;
            }
        }, 50);
    });

    return { mainText, subText };
}
