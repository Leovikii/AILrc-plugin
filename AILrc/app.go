package main

import (
	"context"
	"path/filepath"

	"github.com/wailsapp/wails/v2/pkg/runtime"
)

type MusicInfo struct {
	FileName    string `json:"FileName"`
	TrackNumber int    `json:"TrackNumber"`
}

type PlayerState struct {
	Position int `json:"Position"`
	State    int `json:"State"`
}

type App struct {
	ctx context.Context
}

func NewApp() *App {
	return &App{}
}

func (a *App) startup(ctx context.Context) {
	a.ctx = ctx

	setupIPC(ctx)

	config := LoadAppConfig()
	if config.WindowWidth > 0 {
		runtime.WindowSetSize(ctx, config.WindowWidth, 120)
	}
}

func (a *App) FetchMusicInfo() MusicInfo {
	internal := GetMusicInfo()
	return MusicInfo{
		FileName:    internal.FileName,
		TrackNumber: internal.TrackNumber,
	}
}

func (a *App) FetchPlayerState() PlayerState {
	return GetRealtimeState()
}

func (a *App) FetchLyrics(filename string) []LyricLine {
	internal := GetMusicInfo()

	if filepath.Base(internal.FullPath) == filename {
		return LoadLyrics(internal.FullPath)
	}
	return LoadLyrics(filename)
}

func (a *App) SetWindowClickThrough(enabled bool) {
	SetClickThrough(enabled)
}

func (a *App) GetConfig() AppConfig {
	return LoadAppConfig()
}

func (a *App) SaveConfig(config AppConfig) {
	SaveAppConfig(config)
}

func (a *App) QuitApp() {
	runtime.Quit(a.ctx)
}

func (a *App) ResizeWindow(width, height int) {
	runtime.WindowSetSize(a.ctx, width, height)
}
