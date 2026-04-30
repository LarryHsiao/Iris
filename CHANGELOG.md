# Changelog

All notable changes to Iris are documented here.

## [Unreleased]

### Added
- Claude-thinking tile: a rotating sparkle joins the tile row while any
  Claude Code session is mid-turn, with elapsed seconds beneath. Driven
  by two hook scripts (`iris-claude-on.sh` / `iris-claude-off.sh`) that
  drop marker files into `~/.claude/iris-status/`; Iris polls and shows
  the tile while any marker is present. Off by default; opt in under
  Settings → Content → Claude. One-click installer copies the bundled
  scripts into `<root>/hooks/` and patches `<root>/settings.json`,
  preserving existing hook entries and writing a timestamped backup
  first. Custom config root supported (e.g. `~/.claude-personal`). Stale
  markers older than three minutes are swept, so a missed `Stop` hook
  will not leave the tile stuck on.

## [1.7.1] — 2026-04-28

### Added
- Follow-up calendar chip: when an upcoming meeting overlaps with the
  ongoing one or starts within the imminent window, a second chip
  surfaces alongside the current one so its Join button is reachable
  without waiting for the first to end. Each chip's title truncates at
  78pt when paired (120pt solo) and the countdown keeps its natural
  width, so the row never spills past the overlay.
- Focus phase-end chime: optional sound on phase change with a system-
  sound picker (14 options), repeat count (1–5), and spacing
  (0.20–1.00s). Each tap loads as a fresh `NSSound` from
  `/System/Library/Sounds/` so repeats overlap rather than collapsing
  into a single play. Gated by the master "Play sound on phase change"
  toggle.
- Focus pause-between-phases: when enabled (default on), the timer
  halts at phase end and waits for you to start the next phase
  manually instead of auto-rolling into the next focus or break.
- Notification permission check on launch and on settings apply: if
  Iris notifications are denied while phase-change alerts are enabled,
  an alert points to System Settings → Notifications → Iris so the
  alerts don't fail silently.

### Changed
- On-call chip is now clickable: tap to bring the call's host app to
  the front. Matched by process name against `NSRunningApplication`;
  silently degrades to a static label if no running app matches.

## [1.7] — 2026-04-27

### Added
- Calendar imminent chip is now a Join button when the event carries a meeting URL (Microsoft Teams, Zoom, Google Meet, Webex). Icon swaps to a video glyph and the chip turns blue; click opens the link via the system URL handler. The link is parsed from the event's URL field, location, or notes — no extra permission required. The chip persists for the duration of an ongoing meeting (label switches to "Xm left") so re-joining after a drop is one tap away.
- Air quality + pollen via Open-Meteo. New AIR tile renders the European AQI as a 22pt ring tinted by band (green → purple); off by default, opt in via Settings → Tiles. The Weather tile is now tappable: tap to swap the lyric line for "Temp · City" plus an Air subtitle that combines AQI, band, and active grass/tree/weed pollen levels. AQI is fetched on first need and refreshed every 30 minutes, gated on either the AIR tile or the Weather tile being enabled. No new permission — same IP-based geolocation as the existing weather lookup.

### Fixed
- Call chip and calendar banner chip now anchor to the left of the top-spectrum strip even when the spectrum is idle/faded. Previously the strip collapsed to the chip's width when the spectrum branch was gone, and the parent VStack's default center alignment drifted the chip to the middle of the bar.
- Single-volume disk tile now aligns with the other tiles at full bar height. The thin-mode label-removal refactor accidentally dropped the 8pt reserve that used to keep the disk gauge the same height as CPU / GPU / MEM; the reserve is back in large mode while thin mode still collapses the row completely.

### Changed
- First launch no longer shows the "Iris wants to control Spotify" AppleEvents prompt. The Spotify `osascript` call is now skipped whenever Spotify isn't running, deferring the TCC prompt until the user has Spotify open — a contextual moment rather than a cold-boot surprise.
- Settings dialog preview now horizontally centers the `LyricBarView` instead of pinning it to the leading edge, so the mock overlay reads as a balanced widget rather than a misaligned stripe.

### Added
- `dev.sh` at the repo root: builds Iris in Debug, stops any running instance, and launches the fresh binary. Use for rebuild-and-relaunch without opening Xcode.

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
