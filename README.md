# Iris

<img src="docs/icon.svg" width="96" align="right" />

A lightweight, always-on-top HUD for macOS — live system vitals and synced song lyrics in a single draggable overlay, so you never have to tab away.

> Status: **work in progress.**

![Iris overlay with an audio spectrum strip, on-call chip, lyrics, ring gauges, disk dot discs, and weather tile](docs/screenshot.png)

## Features

- **Synced lyrics** — follows Spotify's current track and streams time-synced lyrics from [lrclib.net](https://lrclib.net), scrolling in real time.
- **Album artwork** — shows the current track's cover art alongside the lyric line.
- **Playback progress bar** — a thin bar at the bottom of the overlay tracks position within the current track.
- **System ring gauges** — CPU, GPU, and memory usage as compact ring indicators; network shows live up/down throughput; battery shows charge and charging state.
- **Disk dot gauge** — free space rendered as a phyllotactic disc of dots, filled center-outward; green when healthy, yellow under 20%, red under 5%. Multiple volumes can be monitored side by side (system by default; others opt-in via Settings).
- **Weather tile** — current condition icon plus temperature, fetched from Open-Meteo with IP-based geolocation (no permission, no API key).
- **Audio spectrum visualizer** — live FFT of the system audio output, rendered as bars that can sit above, below, or behind the lyric bar. Volume-scaled and fades out when playback is silent. First use prompts for Screen Recording access.
- **On-call banner** — a compact chip lights up when you're in a call on Teams, Zoom, Slack, Discord, Webex, FaceTime, Skype, LINE, or Google Meet. No private APIs.
- **Claude-thinking tile** — a rotating sparkle joins the tile row while any Claude Code session is mid-turn, with the elapsed seconds beneath it; vanishes when no session is live. Opt-in; needs the hook scripts shipped under `Iris/Scripts/claude-hooks/` (see below).
- **Draggable overlay** — float it anywhere on screen; position is saved and restored across launches.
- **Menu-bar control** — toggle visibility or open Settings via the `ʟ` status item.

## Planned

- Additional media sources (Apple Music, system-wide Now Playing)
- User-configurable layout and themes
- Per-display positioning

## Requirements

- macOS 14+
- Xcode 15+
- Spotify desktop app (for lyrics)

## Install

Download `Iris.dmg` from the [latest release](https://github.com/LarryHsiao/Iris/releases/latest), mount it, and drag `Iris.app` into `Applications`.

**First launch:** because Iris is a menu-bar-only app (no Dock icon), the usual Gatekeeper confirmation dialog can end up hidden when you double-click. Instead, **right-click `Iris.app` → Open** the first time. After that, launch it normally.

If the app appears to launch but nothing shows up, the quarantine flag is still attached — clear it with:

```bash
xattr -rd com.apple.quarantine /Applications/Iris.app
```

## Build

Open `Iris.xcodeproj` in Xcode and run the `Iris` scheme.

## Claude indicator (optional)

Iris can show a rotating sparkle tile while any Claude Code session is mid-turn. The signal comes from two hook scripts that write a marker file to `~/.claude/iris-status/` on each turn boundary; Iris polls that directory and shows the tile while any marker is present.

**One-click install:** open Iris → Settings → Content → Claude, click the ⓘ next to **Show Claude-thinking tile**, then **Install hooks**. Iris copies the bundled scripts into `~/.claude/hooks/` and patches `~/.claude/settings.json`, preserving any existing hook entries. A timestamped backup of `settings.json` is written first. The toggle flips on automatically when the install succeeds.

**Manual install** (if you'd rather not have the app touch your config): place the two scripts shipped under `Iris/Scripts/claude-hooks/` (or pulled out of `Iris.app/Contents/Resources/`) at `~/.claude/hooks/iris-claude-on.sh` and `~/.claude/hooks/iris-claude-off.sh`, mark them executable, and add the following under `~/.claude/settings.json`'s `hooks` block:

```json
{
  "hooks": {
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/iris-claude-on.sh" }] }],
    "PreToolUse":       [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/iris-claude-on.sh" }] }],
    "PostToolUse":      [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/iris-claude-on.sh" }] }],
    "Stop":             [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/iris-claude-off.sh" }] }]
  }
}
```

Then toggle **Show Claude-thinking tile** on. The tile vanishes when no marker is present. Iris also sweeps any marker older than three minutes, so a missed `Stop` hook will not leave a tile stuck on.

## License

[MIT](LICENSE) © Larry Hsiao
