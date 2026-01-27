package main

func SetClickThrough(enabled bool) {
	hwnd := getWindowHandle()
	if hwnd == 0 {
		return
	}

	exStyle := getWindowLongPtr(hwnd, GWL_EXSTYLE)

	if enabled {
		exStyle |= WS_EX_LAYERED | WS_EX_TRANSPARENT
	} else {
		exStyle &^= WS_EX_TRANSPARENT
	}

	setWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle)
}
