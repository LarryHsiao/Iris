import Foundation

struct SpotifyTrack: Equatable {
    let id: String
    let name: String
    let artist: String
    let positionSeconds: Double
    let artworkURL: String?
}

enum SpotifyClient {
    static func currentTrack() -> SpotifyTrack? {
        let script = """
        tell application "Spotify"
            if it is running then
                try
                    set t to current track
                    set art to ""
                    try
                        set art to artwork url of t
                    end try
                    return (id of t) & "|" & (name of t) & "|" & (artist of t) & "|" & (player position as text) & "|" & art
                end try
            end if
            return ""
        end tell
        """
        guard let out = run(script), !out.isEmpty else { return nil }
        let parts = out.split(separator: "|", maxSplits: 4, omittingEmptySubsequences: false)
        guard parts.count >= 4, let pos = Double(parts[3]) else { return nil }
        let art = parts.count >= 5 ? String(parts[4]) : ""
        return SpotifyTrack(
            id: String(parts[0]),
            name: String(parts[1]),
            artist: String(parts[2]),
            positionSeconds: pos,
            artworkURL: art.isEmpty ? nil : art
        )
    }

    private static func run(_ source: String) -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", source]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
