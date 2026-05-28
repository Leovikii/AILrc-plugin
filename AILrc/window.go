package main

import (
	"context"
	"sync"
	"time"
)

type DOMRect struct {
	X      int `json:"x"`
	Y      int `json:"y"`
	Width  int `json:"width"`
	Height int `json:"height"`
}

var (
	pollCancel context.CancelFunc
	pollMutex  sync.Mutex
)

func SetClickThrough(enabled bool, rect *DOMRect) {
	hwnd := getWindowHandle()
	if hwnd == 0 {
		return
	}

	pollMutex.Lock()
	if pollCancel != nil {
		pollCancel()
		pollCancel = nil
	}
	pollMutex.Unlock()

	applyTransparent := func(transparent bool) {
		exStyle := getWindowLongPtr(hwnd, GWL_EXSTYLE)
		if transparent {
			exStyle |= WS_EX_LAYERED | WS_EX_TRANSPARENT
		} else {
			exStyle &^= WS_EX_TRANSPARENT
		}
		setWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle)
	}

	if !enabled {
		applyTransparent(false)
		return
	}

	// Enabled = true
	applyTransparent(true)

	if rect != nil && rect.Width > 0 && rect.Height > 0 {
		ctx, cancel := context.WithCancel(context.Background())
		
		pollMutex.Lock()
		pollCancel = cancel
		pollMutex.Unlock()

		go func() {
			ticker := time.NewTicker(30 * time.Millisecond)
			defer ticker.Stop()

			isTransparent := true

			for {
				select {
				case <-ctx.Done():
					return
				case <-ticker.C:
					var pt POINT
					if getCursorPos(&pt) {
						if screenToClient(hwnd, &pt) {
							// pt is now relative to the top-left of the client area (in physical pixels)
							inside := pt.X >= int32(rect.X) && pt.X <= int32(rect.X+rect.Width) &&
								pt.Y >= int32(rect.Y) && pt.Y <= int32(rect.Y+rect.Height)

							if inside && isTransparent {
								applyTransparent(false)
								isTransparent = false
							} else if !inside && !isTransparent {
								applyTransparent(true)
								isTransparent = true
							}
						}
					}
				}
			}
		}()
	}
}
