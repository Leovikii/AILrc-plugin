package main

import (
	"encoding/json"
	"log"
	"os"
	"path/filepath"
)

type AppConfig struct {
	FontSize            int     `json:"fontSize"`
	FontColor           string  `json:"fontColor"`
	StrokeColor         string  `json:"strokeColor"`
	BgOpacity           float64 `json:"bgOpacity"`
	TextOpacity         float64 `json:"textOpacity"`
	WindowWidth         int     `json:"windowWidth"`
	WindowX             int     `json:"windowX"`
	WindowY             int     `json:"windowY"`
	WindowPositionSaved bool    `json:"windowPositionSaved"`
}

func DefaultConfig() AppConfig {
	return AppConfig{
		FontSize:            48,
		FontColor:           "#FFFFFF",
		StrokeColor:         "#000000",
		BgOpacity:           0.6,
		TextOpacity:         1.0,
		WindowWidth:         800,
		WindowX:             -1,
		WindowY:             -1,
		WindowPositionSaved: false,
	}
}

func GetConfigPath() string {
	configDir, err := os.UserConfigDir()
	if err != nil {
		return "config.json"
	}
	appDir := filepath.Join(configDir, "AILrc")
	if err := os.MkdirAll(appDir, 0755); err != nil {
		log.Printf("Failed to create config directory: %v", err)
		return "config.json"
	}
	return filepath.Join(appDir, "config.json")
}

func LoadAppConfig() AppConfig {
	config := DefaultConfig()

	path := GetConfigPath()
	data, err := os.ReadFile(path)
	if err == nil {
		if err := json.Unmarshal(data, &config); err != nil {
			log.Printf("Failed to parse config file: %v, using defaults", err)
		}
	}

	return config
}

func SaveAppConfig(config AppConfig) error {
	path := GetConfigPath()
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}
