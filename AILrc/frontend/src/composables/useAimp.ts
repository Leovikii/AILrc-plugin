import { ref, onMounted, onUnmounted } from 'vue';
import { EventsOn } from "../../wailsjs/runtime/runtime";
import { FetchMusicInfo, FetchPlayerState } from "../../wailsjs/go/main/App";

interface MusicInfo {
    FileName: string;
    TrackNumber: number;
}

interface PlayerState {
    Position: number;
    State: number;
}

export function useAimp() {
    const musicInfo = ref<MusicInfo | null>(null);
    const playerState = ref<PlayerState | null>(null);

    onMounted(async () => {
        musicInfo.value = await FetchMusicInfo();
        playerState.value = await FetchPlayerState();

        const cancelTrack = EventsOn("track", async () => {
            musicInfo.value = await FetchMusicInfo();
            if (playerState.value) {
                playerState.value.Position = 0;
            } else {
                playerState.value = { Position: 0, State: 1 };
            }
        });

        const cancelState = EventsOn("state", async (data: any) => {
            if (typeof data === 'object' && data.state !== undefined) {
                if (playerState.value) {
                    playerState.value.State = data.state;
                } else {
                    playerState.value = { Position: 0, State: data.state };
                }
            } else {
                playerState.value = await FetchPlayerState();
            }
        });

        const cancelPosition = EventsOn("position", (data: any) => {
             if (typeof data === 'number') {
                 const posMs = Math.floor(data * 1000);
                 if (playerState.value) {
                     playerState.value.Position = posMs;
                 } else {
                     playerState.value = { Position: posMs, State: 1 };
                 }
             } else if (data && data.position !== undefined) {
                 const posMs = Math.floor(data.position * 1000);
                 if (playerState.value) {
                     playerState.value.Position = posMs;
                 } else {
                     playerState.value = { Position: posMs, State: 1 };
                 }
             }
        });

        onUnmounted(() => {
            cancelTrack();
            cancelState();
            cancelPosition();
        });
    });

    return { 
        musicInfo, 
        playerState,
    };
}
