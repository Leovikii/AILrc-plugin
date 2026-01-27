package main

import (
	"context"
	"encoding/json"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"unsafe"

	"github.com/wailsapp/wails/v2/pkg/runtime"
)

const (
	GWLP_WNDPROC     = -4
	WM_COPYDATA      = 0x004A
	IPC_MAGIC_NUMBER = 19941012
)

type COPYDATASTRUCT struct {
	DwData uintptr
	CbData uint32
	LpData uintptr
}

type PluginMessage struct {
	Type string          `json:"type"`
	Data json.RawMessage `json:"data"`
}

type TrackData struct {
	Title    string  `json:"title"`
	Artist   string  `json:"artist"`
	Album    string  `json:"album"`
	FilePath string  `json:"file_path"`
	Duration float64 `json:"duration"`
}

type StateData struct {
	State int `json:"state"`
}

type PositionData struct {
	Position float64 `json:"position"`
}

type LockData struct {
	Locked bool `json:"locked"`
}

var (
	globalState     PlayerState
	globalMusicInfo MusicInfoInternal
	stateMutex      sync.RWMutex
	oldWndProc      uintptr
	ipcContext      context.Context
)

type MusicInfoInternal struct {
	FileName    string
	TrackNumber int
	IsActive    bool
	FullPath    string
}

func setupIPC(ctx context.Context) {
	ipcContext = ctx
	hwnd := getWindowHandle()
	if hwnd == 0 {
		return
	}

	newWndProc := syscall.NewCallback(func(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
		if msg == WM_COPYDATA {
			cds := (*COPYDATASTRUCT)(unsafe.Pointer(lParam))
			if cds.DwData == IPC_MAGIC_NUMBER {
				jsonStr := ""
				if cds.CbData > 0 {
					data := make([]byte, cds.CbData)
					copy(data, (*[1 << 30]byte)(unsafe.Pointer(cds.LpData))[:cds.CbData])
					jsonStr = string(data)
					if idx := strings.IndexByte(jsonStr, 0); idx >= 0 {
						jsonStr = jsonStr[:idx]
					}
				}
				go handleMessage(jsonStr)
				return 1
			}
		}
		return callWindowProc(oldWndProc, hwnd, msg, wParam, lParam)
	})

	oldWndProc = setWindowLongPtr(hwnd, GWLP_WNDPROC, newWndProc)
}

func handleMessage(jsonStr string) {
	var baseMsg PluginMessage
	if err := json.Unmarshal([]byte(jsonStr), &baseMsg); err != nil {
		return
	}

	if baseMsg.Type == "lock" {
		var ld LockData
		if err := json.Unmarshal(baseMsg.Data, &ld); err == nil {
			SetClickThrough(ld.Locked)
			if ipcContext != nil {
				runtime.EventsEmit(ipcContext, "lock_state_change", ld.Locked)
			}
		}
		return
	}

	switch baseMsg.Type {
	case "track":
		var td TrackData
		if err := json.Unmarshal(baseMsg.Data, &td); err == nil {
			stateMutex.Lock()
			globalMusicInfo = MusicInfoInternal{
				FileName:    filepath.Base(td.FilePath),
				TrackNumber: 0,
				IsActive:    true,
				FullPath:    td.FilePath,
			}
			globalState.Position = 0
			stateMutex.Unlock()

			if ipcContext != nil {
				runtime.EventsEmit(ipcContext, "track", td)
			}
		}

	case "state":
		var sd StateData
		if err := json.Unmarshal(baseMsg.Data, &sd); err == nil {
			stateMutex.Lock()
			globalState.State = sd.State
			globalMusicInfo.IsActive = true
			stateMutex.Unlock()

			if ipcContext != nil {
				runtime.EventsEmit(ipcContext, "state", sd)
			}
		}

	case "position":
		var pd PositionData
		if err := json.Unmarshal(baseMsg.Data, &pd); err == nil {
			stateMutex.Lock()
			globalState.Position = int(pd.Position * 1000)
			globalState.State = 2
			globalMusicInfo.IsActive = true
			stateMutex.Unlock()

			if ipcContext != nil {
				runtime.EventsEmit(ipcContext, "position", pd)
			}
		}
	}
}

func GetMusicInfo() MusicInfoInternal {
	stateMutex.RLock()
	defer stateMutex.RUnlock()
	return globalMusicInfo
}

func GetRealtimeState() PlayerState {
	stateMutex.RLock()
	defer stateMutex.RUnlock()
	return globalState
}
