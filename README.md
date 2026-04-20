# Iris

An all-in-one on-screen monitor for macOS.

> Status: **work in progress.**

A thin, click-through overlay pinned to the top of the screen that surfaces the things you'd otherwise keep tabbing away to check — system vitals, now-playing media, and more — in a single glance.

## Current capabilities

- **Now-playing lyric bar** — follows Spotify's current track and streams synced lyrics from [lrclib.net](https://lrclib.net).
- **Live CPU usage** — sampled via `host_statistics64`.
- **Menu-bar control** — toggle the overlay on/off or quit from the status item.

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
