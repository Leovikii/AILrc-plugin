import { useState, useEffect } from 'react';
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
    const [musicInfo, setMusicInfo] = useState<MusicInfo | null>(null);
    const [playerState, setPlayerState] = useState<PlayerState | null>(null);

    useEffect(() => {
        FetchMusicInfo().then(setMusicInfo);
        FetchPlayerState().then(setPlayerState);

        const cancelTrack = EventsOn("track", () => {
            FetchMusicInfo().then(setMusicInfo);
            setPlayerState(prev => prev ? { ...prev, Position: 0 } : { Position: 0, State: 1 });
        });

        const cancelState = EventsOn("state", (data: any) => {
            if (typeof data === 'object' && data.state !== undefined) {
                setPlayerState(prev => prev ? { ...prev, State: data.state } : { Position: 0, State: data.state });
            } else {
                FetchPlayerState().then(setPlayerState);
            }
        });

        const cancelPosition = EventsOn("position", (data: any) => {
             if (typeof data === 'number') {
                 const posMs = Math.floor(data * 1000);
                 setPlayerState(prev => prev ? { ...prev, Position: posMs } : { Position: posMs, State: 1 });
             } else if (data && data.position !== undefined) {
                 const posMs = Math.floor(data.position * 1000);
                 setPlayerState(prev => prev ? { ...prev, Position: posMs } : { Position: posMs, State: 1 });
             }
        });

        return () => {
            cancelTrack();
            cancelState();
            cancelPosition();
        };
    }, []);

    return { 
        musicInfo, 
        playerState,
    };
}