import Foundation

struct CallState: Equatable {
    let inCall: Bool
    let appName: String?
    let processName: String?

    static let idle = CallState(inCall: false, appName: nil, processName: nil)
}

enum CallMonitor {
    private static let callKeywords = [
        "call", "meeting", "conference", "huddle", "facetime", "video-conference"
    ]

    private static let callApps: [(match: String, label: String)] = [
        ("Microsoft Teams", "Teams"),
        ("MSTeams", "Teams"),
        ("Teams", "Teams"),
        ("zoom.us", "Zoom"),
        ("zoom", "Zoom"),
        ("Slack", "Slack"),
        ("Discord", "Discord"),
        ("Webex", "Webex"),
        ("FaceTime", "FaceTime"),
        ("Skype", "Skype"),
        ("LINE", "LINE"),
        ("Meet", "Google Meet"),
        ("GoogleMeet", "Google Meet")
    ]

    static func sample() -> CallState {
        guard let output = runPmset() else { return .idle }
        return parse(output: output)
    }

    static func parse(output: String) -> CallState {
        struct Assertion {
            let proc: String
            let kind: String
            let name: String
        }

        let lines = output.components(separatedBy: "\n")
        let assertionRegex = try? NSRegularExpression(
            pattern: #"pid \d+\(([^)]+)\):\s+\[[^\]]+\]\s+[\d:]+\s+(\w+) named: "([^"]*)""#
        )
        let createdForRegex = try? NSRegularExpression(pattern: #"Created for PID: (\d+)"#)

        var assertions: [Assertion] = []
        var createdFor: [Int: Int] = [:]

        for line in lines {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let regex = assertionRegex,
               let match = regex.firstMatch(in: line, range: range),
               match.numberOfRanges == 4,
               let procRange = Range(match.range(at: 1), in: line),
               let kindRange = Range(match.range(at: 2), in: line),
               let nameRange = Range(match.range(at: 3), in: line) {
                assertions.append(.init(
                    proc: String(line[procRange]),
                    kind: String(line[kindRange]),
                    name: String(line[nameRange])
                ))
            } else if let regex = createdForRegex,
                      let match = regex.firstMatch(in: line, range: range),
                      match.numberOfRanges == 2,
                      let pidRange = Range(match.range(at: 1), in: line),
                      let pid = Int(line[pidRange]),
                      !assertions.isEmpty {
                createdFor[assertions.count - 1] = pid
            }
        }

        for (index, assertion) in assertions.enumerated() {
            let lowerName = assertion.name.lowercased()
            if callKeywords.contains(where: { lowerName.contains($0) }) {
                let label = matchCallApp(assertion.proc) ?? assertion.proc
                print("[CallMonitor] keyword match: \(assertion.proc) / \(assertion.kind) / \(assertion.name)")
                return CallState(inCall: true, appName: label, processName: assertion.proc)
            }
            if assertion.proc == "coreaudiod",
               assertion.name.contains("input.context"),
               let ownerPid = createdFor[index],
               let ownerName = processName(pid: ownerPid) {
                let label = matchCallApp(ownerName) ?? ownerName
                print("[CallMonitor] mic-in-use by \(ownerName) → \(label)")
                return CallState(inCall: true, appName: label, processName: ownerName)
            }
        }

        return .idle
    }

    private static func matchCallApp(_ procName: String) -> String? {
        for entry in callApps where procName.localizedCaseInsensitiveContains(entry.match) {
            return entry.label
        }
        return nil
    }

    private static func runPmset() -> String? {
        runProcess(path: "/usr/bin/pmset", arguments: ["-g", "assertions"])
    }

    private static func processName(pid: Int) -> String? {
        guard let output = runProcess(
            path: "/bin/ps",
            arguments: ["-p", "\(pid)", "-o", "comm="]
        ) else { return nil }
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return (trimmed as NSString).lastPathComponent
    }

    private static func runProcess(path: String, arguments: [String]) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = arguments
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
        } catch {
            return nil
        }
        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        try? handle.close()
        task.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }
}
