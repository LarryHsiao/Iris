# Changelog

All notable changes to Iris are documented here.

## [Unreleased]

### Fixed
- Call chip and calendar banner chip now anchor to the left of the top-spectrum strip even when the spectrum is idle/faded. Previously the strip collapsed to the chip's width when the spectrum branch was gone, and the parent VStack's default center alignment drifted the chip to the middle of the bar.

### Changed
- First launch no longer shows the "Iris wants to control Spotify" AppleEvents prompt. The Spotify `osascript` call is now skipped whenever Spotify isn't running, deferring the TCC prompt until the user has Spotify open — a contextual moment rather than a cold-boot surprise.

## [1.6] — 2026-04-24

### Added
- Thin mode: halves the overlay bar (56pt → 30pt), hides the label beneath every gauge (CPU, GPU, MEM, BAT, FOC, CAL, disk drive icon), and truncates lyrics to a single line. Toggle in Settings → System → Overlay. The overlay's top edge stays pinned across toggles so the bar appears to grow/shrink downward rather than drift.
- Mini tile preview next to each toggle in Settings → Tiles, so the thing being enabled is visible beside its switch.
- Disk tile is tappable: the lyric slot swaps for per-volume free/total space while the tile is expanded.

### Changed
- Settings dialog is now vertically scrollable so in-progress UI cannot push controls past the bottom edge. Close and Apply stay pinned at the footer.
- The Settings footer button formerly labelled "Cancel" now reads "Close" — it closes without applying, and the new label says that plainly. Escape still dismisses.
- Focus tile no longer auto-hides during an ongoing calendar event; it stays in place so a pomodoro in progress is visible alongside a meeting.
- Spectrum visualizer unmounts when fully faded, sparing the render pass while idle.

## [1.5] — 2026-04-23

### Added
- Sparkline expansion: tap a CPU, GPU, MEM, or Network tile to replace the lyric line with a recent-history sparkline (last 60 samples) and current value. Re-tap or wait 5s to collapse.
- Auto-hide overlay when a fullscreen app is frontmost: fades out smoothly and returns when you exit fullscreen. Toggle in Settings → System. Window stays alive so audio capture and polling keep running.
- Wi-Fi name and public IP in the expanded network tile. Opt-in toggle in Settings → System (default off). SSID comes from CoreWLAN and requires Location permission on macOS 14.4+; public IP is fetched from `api.ipify.org` and refreshed on network changes plus every 10 minutes.
- Focus (Pomodoro) tile. Tap to start/pause; right-click for Reset, Skip phase, and Start/Pause/Resume. Phase ring fills in red during focus and green during break. Focus/break durations and phase-change notifications configurable in Settings → Tiles → Focus. Tile is hidden by default — enable it in Settings → Tiles. Auto-hides during an ongoing calendar event when Calendar is on.
- Calendar event surface. When idle with no track playing, the artwork/lyrics slot becomes an IdleView showing the next meeting (title + relative time) or the current clock. While music is playing, a ring-gauge Calendar tile shows the countdown; tap it to swap the lyric line for the event title, relative time, and start–end range. When the next event is within a configurable threshold (default 5 min), an amber chip floats above the bar. Opt-in toggle in Settings → Content → Calendar; uses EventKit full access with the `com.apple.security.personal-information.calendars` hardened-runtime entitlement and `NSCalendarsFullAccessUsageDescription` in Info.plist.

### Changed
- Settings window stays open after Apply so configuration can be iterated without reopening. Cancel still closes.
- Lyric-to-tile minimum gap tightened from ~44pt to 8pt; banner chips over the spectrum get a 4pt inset on leading and bottom.

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
