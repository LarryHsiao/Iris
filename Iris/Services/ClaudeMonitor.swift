import Foundation

struct ClaudeSession: Equatable, Identifiable {
    enum Status: String, Equatable {
        case thinking
        case tool
    }

    let id: String
    let project: String
    let status: Status
    let tool: String?
    let since: Date
}

struct ClaudeState: Equatable {
    let sessions: [ClaudeSession]

    static let idle = ClaudeState(sessions: [])

    var isActive: Bool { !sessions.isEmpty }

    var oldest: ClaudeSession? {
        sessions.min(by: { $0.since < $1.since })
    }
}

enum ClaudeMonitor {
    private static let staleAfter: TimeInterval = 180

    static let directory: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/iris-status", isDirectory: true)
    }()

    static func sample(now: Date = Date()) -> ClaudeState {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else {
            return .idle
        }

        var sessions: [ClaudeSession] = []
        for url in entries where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let session = decode(data: data) else { continue }
            if now.timeIntervalSince(session.since) > staleAfter {
                try? fm.removeItem(at: url)
                continue
            }
            sessions.append(session)
        }
        return ClaudeState(sessions: sessions)
    }

    private static func decode(data: Data) -> ClaudeSession? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = obj["sessionId"] as? String,
              let project = obj["project"] as? String,
              let statusRaw = obj["status"] as? String,
              let status = ClaudeSession.Status(rawValue: statusRaw),
              let since = obj["since"] as? TimeInterval else { return nil }
        let tool = obj["tool"] as? String
        return ClaudeSession(
            id: id,
            project: project,
            status: status,
            tool: tool,
            since: Date(timeIntervalSince1970: since)
        )
    }
}
