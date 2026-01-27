package main

import (
	"syscall"
	"unsafe"
)

const (
	GWL_EXSTYLE       = 0xFFFFFFEC
	WS_EX_LAYERED     = 0x80000
	WS_EX_TRANSPARENT = 0x20
	LWA_ALPHA         = 0x2
	MB_ICONERROR      = 0x10
)

var (
	user32                         = syscall.NewLazyDLL("user32.dll")
	procFindWindowW                = user32.NewProc("FindWindowW")
	procSetWindowLongPtrW          = user32.NewProc("SetWindowLongPtrW")
	procGetWindowLongPtrW          = user32.NewProc("GetWindowLongPtrW")
	procSetLayeredWindowAttributes = user32.NewProc("SetLayeredWindowAttributes")
	procCallWindowProcW            = user32.NewProc("CallWindowProcW")
	procMessageBoxW                = user32.NewProc("MessageBoxW")
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
