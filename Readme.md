# AILrc

A modern, high-performance desktop lyric renderer for AIMP player, built with Go (Wails) and React.

Unlike traditional lyric plugins that rely on inefficient polling, AILrc uses a native **Delphi plugin** to push playback status and metadata directly to the renderer via IPC, ensuring zero latency, smooth animations, and minimal CPU usage.

## ✨ Features

* **Zero Latency Sync**: Native AIMP plugin pushes playback state (10ms precision).
* **Modern UI**: Built with React & TailwindCSS. Support for blurred backgrounds, glowing text, and smooth transitions.
* **Format Support**: Supports `.lrc`, `.srt`, and `.vtt` lyric files.
* **Smart Search**: Automatically finds lyrics in the same directory as the audio file (supports `filename.vtt` and `filename.wav.vtt`).
* **Click-Through Mode**: Lock the window to let mouse events pass through to underlying applications.
* **Customizable**: Adjust font size, colors, opacity, and window dimensions via a built-in settings panel.

## 🛠 Tech Stack

* **Frontend**: React, TypeScript, TailwindCSS v4
* **Backend**: Go (Wails framework)
* **Plugin**: Delphi (Pascal) for AIMP SDK interaction
* **IPC**: Windows `WM_COPYDATA` for high-speed message passing

## 🚀 Installation & Usage

### 1. Install the Plugin
1.  Download the latest release.
2.  Double-click `AILrc_plugin.aimppack` to install it via the AIMP Package Installer.
3.  Ensure the plugin is enabled in AIMP Preferences > Plugins > **AILrc plugin**.

### 2. Setup the Renderer
1.  Place `AILrc.exe` in the **root directory** of your AIMP installation (the same folder where `AIMP.exe` is located).
    * *Example:* `C:\Program Files\AIMP\AILrc.exe`
2.  Start AIMP. The plugin will automatically launch AILrc.

### 3. Loading Lyrics
Simply play a music file in AIMP. AILrc will automatically look for a matching lyric file in the same folder as the audio track.

## 🏗 Development

### Prerequisites
* Go 1.20+
* Node.js 18+
* Delphi 10.3+ (only if modifying the `aimp_plugin`)
* Wails CLI (`go install github.com/wailsapp/wails/v2/cmd/wails@latest`)

### Build Renderer
```bash
# Install frontend dependencies
cd frontend
npm install

# Build the application (Windows)
wails build -clean