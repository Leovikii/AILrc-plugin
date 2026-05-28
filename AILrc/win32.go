package main

import (
	"syscall"
	"unsafe"
)

const (
	GWL_EXSTYLE       = -20
	WS_EX_LAYERED     = 0x80000
	WS_EX_TRANSPARENT = 0x20
	LWA_ALPHA         = 0x2
	MB_ICONERROR      = 0x10

	// AIMP Remote API Constants
	WM_USER                       = 0x0400
	WM_AIMP_COMMAND               = WM_USER + 0x75
	WM_AIMP_PROPERTY              = WM_USER + 0x77
	AIMP_RA_CMD_PLAYPAUSE         = 14
	AIMP_RA_CMD_NEXT              = 17
	AIMP_RA_CMD_PREV              = 18
	AIMP_RA_PROPERTY_PLAYER_STATE = 0x40
	AIMP_RA_PROPVALUE_GET         = 0
)

type POINT struct {
	X int32
	Y int32
}

var (
	user32                         = syscall.NewLazyDLL("user32.dll")
	procFindWindowW                = user32.NewProc("FindWindowW")
	procSetWindowLongPtrW          = user32.NewProc("SetWindowLongPtrW")
	procGetWindowLongPtrW          = user32.NewProc("GetWindowLongPtrW")
	procSetLayeredWindowAttributes = user32.NewProc("SetLayeredWindowAttributes")
	procCallWindowProcW            = user32.NewProc("CallWindowProcW")
	procMessageBoxW                = user32.NewProc("MessageBoxW")
	procGetCursorPos               = user32.NewProc("GetCursorPos")
	procScreenToClient             = user32.NewProc("ScreenToClient")
	procSendMessageW               = user32.NewProc("SendMessageW")
)

func getWindowHandle() uintptr {
	title, _ := syscall.UTF16PtrFromString("AILrc")
	ret, _, _ := procFindWindowW.Call(0, uintptr(unsafe.Pointer(title)))
	return ret
}

func setWindowLongPtr(hwnd uintptr, index int, newLong uintptr) uintptr {
	ret, _, _ := procSetWindowLongPtrW.Call(hwnd, uintptr(index), newLong)
	return ret
}

func getWindowLongPtr(hwnd uintptr, index int) uintptr {
	ret, _, _ := procGetWindowLongPtrW.Call(hwnd, uintptr(index))
	return ret
}

func setLayeredWindowAttributes(hwnd uintptr, crKey uint32, bAlpha byte, dwFlags uint32) bool {
	ret, _, _ := procSetLayeredWindowAttributes.Call(hwnd, uintptr(crKey), uintptr(bAlpha), uintptr(dwFlags))
	return ret != 0
}

func callWindowProc(prevWndProc uintptr, hwnd uintptr, msg uint32, wParam, lParam uintptr) uintptr {
	ret, _, _ := procCallWindowProcW.Call(prevWndProc, hwnd, uintptr(msg), wParam, lParam)
	return ret
}

func showErrorMessageBox(title, message string) {
	titlePtr, _ := syscall.UTF16PtrFromString(title)
	messagePtr, _ := syscall.UTF16PtrFromString(message)
	procMessageBoxW.Call(0, uintptr(unsafe.Pointer(messagePtr)), uintptr(unsafe.Pointer(titlePtr)), MB_ICONERROR)
}

func getCursorPos(pt *POINT) bool {
	ret, _, _ := procGetCursorPos.Call(uintptr(unsafe.Pointer(pt)))
	return ret != 0
}

func screenToClient(hwnd uintptr, pt *POINT) bool {
	ret, _, _ := procScreenToClient.Call(hwnd, uintptr(unsafe.Pointer(pt)))
	return ret != 0
}

var aimpClassNamePtr *uint16

func init() {
	aimpClassNamePtr, _ = syscall.UTF16PtrFromString("AIMP2_RemoteInfo")
}

func sendAimpCommand(cmd uintptr) {
	hwnd, _, _ := procFindWindowW.Call(uintptr(unsafe.Pointer(aimpClassNamePtr)), 0)
	if hwnd != 0 {
		procSendMessageW.Call(hwnd, uintptr(WM_AIMP_COMMAND), cmd, 0)
	}
}

func getAimpState() int {
	hwnd, _, _ := procFindWindowW.Call(uintptr(unsafe.Pointer(aimpClassNamePtr)), 0)
	if hwnd != 0 {
		ret, _, _ := procSendMessageW.Call(hwnd, uintptr(WM_AIMP_PROPERTY), uintptr(AIMP_RA_PROPERTY_PLAYER_STATE|AIMP_RA_PROPVALUE_GET), 0)
		return int(ret)
	}
	return -1
}
