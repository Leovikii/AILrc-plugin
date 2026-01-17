package main

import (
	"encoding/json"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"unsafe"
)

var (
	user32                = syscall.NewLazyDLL("user32.dll")
	procFindWindowW       = user32.NewProc("FindWindowW")
	procSetWindowLongPtrW = user32.NewProc("SetWindowLongPtrW")
	procCallWindowProcW   = user32.NewProc("CallWindowProcW")
)

const (
	GWLP_WNDPROC = -4
	WM_COPYDATA  = 0x004A
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

var (
	globalState     PlayerState
	globalMusicInfo MusicInfoInternal
	stateMutex      sync.RWMutex
	oldWndProc      uintptr
)

type MusicInfoInternal struct {
	FileName    string
	TrackNumber int
	IsActive    bool
	FullPath    string
}

func setupIPC() {
	hwnd := getWindowHandle()
	if hwnd == 0 {
		return
	}

	newWndProc := syscall.NewCallback(func(hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
		if msg == WM_COPYDATA {
			cds := (*COPYDATASTRUCT)(unsafe.Pointer(lParam))
			if cds.DwData == 19941012 {
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

	stateMutex.Lock()
	defer stateMutex.Unlock()

	switch baseMsg.Type {
	case "track":
		var td TrackData
		if err := json.Unmarshal(baseMsg.Data, &td); err == nil {
			globalMusicInfo = MusicInfoInternal{
				FileName:    filepath.Base(td.FilePath),
				TrackNumber: 0,
				IsActive:    true,
				FullPath:    td.FilePath,
			}
			globalState.Position = 0
		}
	case "state":
		var sd StateData
		if err := json.Unmarshal(baseMsg.Data, &sd); err == nil {
			globalState.State = sd.State
			globalMusicInfo.IsActive = true
		}
	case "position":
		var pd PositionData
		if err := json.Unmarshal(baseMsg.Data, &pd); err == nil {
			globalState.Position = int(pd.Position * 1000)
			globalState.State = 2
			globalMusicInfo.IsActive = true
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

func getWindowHandle() uintptr {
	title, _ := syscall.UTF16PtrFromString("AILrc")
	ret, _, _ := procFindWindowW.Call(0, uintptr(unsafe.Pointer(title)))
	return ret
}

func setWindowLongPtr(hwnd uintptr, index int, newLong uintptr) uintptr {
	ret, _, _ := procSetWindowLongPtrW.Call(hwnd, uintptr(index), newLong)
	return ret
}

func callWindowProc(prevWndProc uintptr, hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	ret, _, _ := procCallWindowProcW.Call(prevWndProc, hwnd, uintptr(msg), wParam, lParam)
	return ret
}
