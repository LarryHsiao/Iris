# Iris

A lightweight, always-on-top HUD for macOS — live system vitals and synced song lyrics in a single draggable overlay, so you never have to tab away.

> Status: **work in progress.**

![Iris overlay showing lyrics and system ring gauges](docs/screenshot.png)

## Features

- **Synced lyrics** — follows Spotify's current track and streams time-synced lyrics from [lrclib.net](https://lrclib.net), scrolling in real time.
- **Album artwork** — shows the current track's cover art alongside the lyric line.
- **Playback progress bar** — a thin bar at the bottom of the overlay tracks position within the current track.
- **System ring gauges** — CPU and memory usage as compact ring indicators; disk shows free space as a text label.
- **Draggable overlay** — float it anywhere on screen; position is saved and restored across launches.
- **Menu-bar control** — toggle visibility or quit via the `ʟ` status item.

## Planned

- GPU / memory / network / battery tiles
- Additional media sources (Apple Music, system-wide Now Playing)
- User-configurable layout and themes
- Per-display positioning

## Requirements

- macOS 14+
- Xcode 15+
- Spotify desktop app (for lyrics)

## Build

Open `Iris.xcodeproj` in Xcode and run the `Iris` scheme.

## License

[MIT](LICENSE) © Larry Hsiao
