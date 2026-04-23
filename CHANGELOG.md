# Changelog

All notable changes to Iris are documented here.

## [Unreleased]

### Added
- Sparkline expansion: tap a CPU, GPU, MEM, or Network tile to replace the lyric line with a recent-history sparkline (last 60 samples) and current value. Re-tap or wait 5s to collapse.
- Auto-hide overlay when a fullscreen app is frontmost: fades out smoothly and returns when you exit fullscreen. Toggle in Settings → System. Window stays alive so audio capture and polling keep running.
- Wi-Fi name and public IP in the expanded network tile. Opt-in toggle in Settings → System (default off). SSID comes from CoreWLAN and requires Location permission on macOS 14.4+; public IP is fetched from `api.ipify.org` and refreshed on network changes plus every 10 minutes.
- Focus (Pomodoro) tile. Tap to start/pause; right-click for Reset, Skip phase, and Start/Pause/Resume. Phase ring fills in red during focus and green during break. Focus/break durations and phase-change notifications configurable in Settings → Tiles → Focus. Tile is hidden by default — enable it in Settings → Tiles.

## [1.4] — 2026-04-22

### Added
- Audio spectrum visualizer: system-audio capture via `ScreenCaptureKit`, 32-band vDSP FFT with per-band bass tilt and system-volume scaling, rendered as rounded bars. Three positions selectable from Settings:
  - **Behind** — faint backdrop inside the lyric bar.
  - **Above** — strip above the bar at 2/3 the bar height; the on-call chip floats on top of it.
  - **Below** — matching strip under the bar with bars hanging upside-down.
- Permission flow: first enable triggers `CGRequestScreenCaptureAccess` and a follow-up alert linking to *System Settings → Privacy & Security → Screen Recording*.
- Weather tile: icon + current temperature gauge on the right, fetched from Open-Meteo every 15 minutes. Location resolved via IP geolocation (no permission, no API key).

## [1.3] — 2026-04-22

### Added
- On-call banner: compact chip above the overlay showing the active call app (Teams, Zoom, Slack, Discord, Webex, FaceTime, Skype, LINE, Google Meet). Detected via `pmset` assertions and `coreaudiod` mic usage, no private APIs.
- Settings: "Show on-call label" toggle to hide the banner.
- Disk dot gauge: the disk tile is now a ~22pt disc of 196 dots arranged in a phyllotactic spiral, filled center-outward in proportion to free space (green ≥ 20%, yellow < 20%, red < 5%).
- Multi-volume support: additional mounted volumes can be enabled in Settings → Tiles → Disks; the system volume is always shown. When multiple gauges are visible, an internal/external drive SF Symbol sits under each, with the full volume name on hover.

### Changed
- Settings panel split into Content / Tiles / System tabs; Apply closes the window and is no longer gated on a dirty check.

## [1.2] — 2026-04-21

### Added
- Overlay width control in Settings.
- Settings dialog with drag-to-reorder tiles.
- GPU, network, and battery tiles.
