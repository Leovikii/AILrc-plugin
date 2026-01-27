package main

import (
	"embed"
	"fmt"
	"os"
	"runtime/debug"
	"syscall"
	"time"
	"unsafe"

	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
	"github.com/wailsapp/wails/v2/pkg/options/windows"
)

//go:embed all:frontend/dist
var assets embed.FS

func main() {
	defer func() {
		if r := recover(); r != nil {
			logContent := fmt.Sprintf("Time: %s\nError: %v\nStack Trace:\n%s",
				time.Now().Format(time.RFC3339), r, string(debug.Stack()))
			_ = os.WriteFile("crash.log", []byte(logContent), 0644)

			showErrorMessageBox("AILrc Critical Error", "Application has crashed. Please check crash.log for details.")
		}
	}()

	kernel32 := syscall.NewLazyDLL("kernel32.dll")
	procCreateMutex := kernel32.NewProc("CreateMutexW")
	procGetLastError := kernel32.NewProc("GetLastError")

	name, _ := syscall.UTF16PtrFromString("Global\\AILrc_Single_Instance_Mutex")

	mutex, _, _ := procCreateMutex.Call(0, 0, uintptr(unsafe.Pointer(name)))
	if mutex == 0 {
		return
	}

	lastErr, _, _ := procGetLastError.Call()
	if lastErr == 183 {
		return
	}

	app := NewApp()

	err := wails.Run(&options.App{
		Title:         "AILrc",
		Width:         800,
		Height:        120,
		AlwaysOnTop:   true,
		DisableResize: true,
		Frameless:     true,
		AssetServer: &assetserver.Options{
			Assets: assets,
		},
		BackgroundColour: &options.RGBA{R: 0, G: 0, B: 0, A: 0},
		OnStartup:        app.startup,
		OnBeforeClose:    app.beforeClose,
		Bind: []interface{}{
			app,
		},
		Windows: &windows.Options{
			WebviewIsTransparent: true,
			WindowIsTranslucent:  true,
			BackdropType:         windows.None,
		},
	})

	if err != nil {
		println("Error:", err.Error())
	}
}
