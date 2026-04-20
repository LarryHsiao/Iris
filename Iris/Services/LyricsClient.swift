import Foundation

struct SyncedLyrics {
    struct Line {
        let time: Double
        let text: String
    }

    let lines: [Line]

    func line(at seconds: Double) -> String? {
        guard !lines.isEmpty else { return nil }
        var lo = 0
        var hi = lines.count - 1
        var best = -1
        while lo <= hi {
            let mid = (lo + hi) / 2
            if lines[mid].time <= seconds {
                best = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return best >= 0 ? lines[best].text : nil
    }
}

enum LyricsClient {
    static func fetch(track: String, artist: String) async -> SyncedLyrics? {
        var comp = URLComponents(string: "https://lrclib.net/api/get")!
        comp.queryItems = [
            URLQueryItem(name: "track_name", value: track),
            URLQueryItem(name: "artist_name", value: artist),
        ]
        guard let url = comp.url else { return nil }
        do {
            var request = URLRequest(url: url)
            request.setValue("Iris/0.1", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)
            guard
                let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let lrc = obj["syncedLyrics"] as? String
            else { return nil }
            return parse(lrc)
        } catch {
            return nil
        }
    }

    private static func parse(_ lrc: String) -> SyncedLyrics {
        var out: [SyncedLyrics.Line] = []
        let pattern = #"\[(\d+):(\d+)\.(\d+)\](.*)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        for raw in lrc.split(separator: "\n") {
            let line = String(raw)
            let range = NSRange(line.startIndex..., in: line)
            guard let match = regex.firstMatch(in: line, range: range) else { continue }
            let ns = line as NSString
            let mm = Double(ns.substring(with: match.range(at: 1))) ?? 0
            let ss = Double(ns.substring(with: match.range(at: 2))) ?? 0
            let cs = Double(ns.substring(with: match.range(at: 3))) ?? 0
            let text = ns.substring(with: match.range(at: 4))
                .trimmingCharacters(in: .whitespaces)
            let t = mm * 60 + ss + cs / 100
            out.append(.init(time: t, text: text))
        }
        return SyncedLyrics(lines: out.sorted { $0.time < $1.time })
    }
}
