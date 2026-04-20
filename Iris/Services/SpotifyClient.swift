import Foundation

struct SpotifyTrack: Equatable {
    let id: String
    let name: String
    let artist: String
    let positionSeconds: Double
}

enum SpotifyClient {
    static func currentTrack() -> SpotifyTrack? {
        let script = """
        tell application "Spotify"
            if it is running then
                try
                    set t to current track
                    return (id of t) & "|" & (name of t) & "|" & (artist of t) & "|" & (player position as text)
                end try
            end if
            return ""
        end tell
        """
        guard let out = run(script), !out.isEmpty else { return nil }
        let parts = out.split(separator: "|", maxSplits: 3, omittingEmptySubsequences: false)
        guard parts.count == 4, let pos = Double(parts[3]) else { return nil }
        return SpotifyTrack(
            id: String(parts[0]),
            name: String(parts[1]),
            artist: String(parts[2]),
            positionSeconds: pos
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
