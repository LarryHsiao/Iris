import Foundation

enum ClaudeHookInstaller {
    enum Status: Equatable {
        case notInstalled
        case installed
        case partial(String)
        case failed(String)
    }

    private static let scriptNames = ["iris-claude-on.sh", "iris-claude-off.sh"]
    private static let onScript = "iris-claude-on.sh"
    private static let offScript = "iris-claude-off.sh"

    private static let onEvents = ["UserPromptSubmit", "PreToolUse", "PostToolUse"]
    private static let offEvents = ["Stop"]

    static func resolveRoot(_ raw: String) -> URL {
        let expanded = (raw as NSString).expandingTildeInPath
        return URL(fileURLWithPath: expanded, isDirectory: true)
    }

    static func hooksDirectory(under root: URL) -> URL {
        root.appendingPathComponent("hooks", isDirectory: true)
    }

    static func settingsFile(under root: URL) -> URL {
        root.appendingPathComponent("settings.json")
    }

    static func currentStatus(rootRaw: String) -> Status {
        let root = resolveRoot(rootRaw)
        let hooks = hooksDirectory(under: root)
        let settings = settingsFile(under: root)
        let fm = FileManager.default

        let scriptsPresent = scriptNames.allSatisfy { name in
            fm.fileExists(atPath: hooks.appendingPathComponent(name).path)
        }
        guard scriptsPresent, fm.fileExists(atPath: settings.path) else {
            return .notInstalled
        }
        guard let data = try? Data(contentsOf: settings),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooksMap = parsed["hooks"] as? [String: Any] else {
            return .notInstalled
        }
        let onWired = onEvents.allSatisfy { hasIrisEntry(in: hooksMap[$0], scriptName: onScript) }
        let offWired = offEvents.allSatisfy { hasIrisEntry(in: hooksMap[$0], scriptName: offScript) }
        return (onWired && offWired) ? .installed : .notInstalled
    }

    static func install(rootRaw: String) -> Status {
        let root = resolveRoot(rootRaw)
        do {
            try copyScripts(into: hooksDirectory(under: root))
            try patchSettings(at: settingsFile(under: root), commandRoot: root)
            return .installed
        } catch let error as NSError {
            return .failed(error.localizedDescription)
        }
    }

    private static func copyScripts(into hooks: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: hooks, withIntermediateDirectories: true)
        guard let resources = Bundle.main.resourceURL else {
            throw NSError.iris("Bundle resource path missing")
        }
        for name in scriptNames {
            let src = resources.appendingPathComponent(name)
            let dst = hooks.appendingPathComponent(name)
            guard fm.fileExists(atPath: src.path) else {
                throw NSError.iris("Bundled script missing: \(name)")
            }
            if fm.fileExists(atPath: dst.path) {
                try fm.removeItem(at: dst)
            }
            try fm.copyItem(at: src, to: dst)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dst.path)
        }
    }

    private static func patchSettings(at settingsURL: URL, commandRoot: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(
            at: settingsURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var root: [String: Any] = [:]
        if fm.fileExists(atPath: settingsURL.path) {
            let data = try Data(contentsOf: settingsURL)
            if !data.isEmpty {
                guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw NSError.iris("settings.json is not a JSON object")
                }
                root = parsed
                let backup = settingsURL.deletingLastPathComponent()
                    .appendingPathComponent("settings.json.iris-bak.\(Int(Date().timeIntervalSince1970))")
                try data.write(to: backup)
            }
        }

        let onCommand = displayPath(for: commandRoot.appendingPathComponent("hooks/\(onScript)"))
        let offCommand = displayPath(for: commandRoot.appendingPathComponent("hooks/\(offScript)"))

        var hooks = (root["hooks"] as? [String: Any]) ?? [:]
        for event in onEvents {
            hooks[event] = mergedEntries(in: hooks[event], scriptName: onScript, command: onCommand)
        }
        for event in offEvents {
            hooks[event] = mergedEntries(in: hooks[event], scriptName: offScript, command: offCommand)
        }
        root["hooks"] = hooks

        let data = try JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: settingsURL, options: .atomic)
    }

    static func displayPath(for url: URL) -> String {
        let path = url.path
        let home = NSHomeDirectory()
        if path == home { return "~" }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private static func mergedEntries(in current: Any?, scriptName: String, command: String) -> [Any] {
        var entries = (current as? [Any]) ?? []
        if hasIrisEntry(in: entries, scriptName: scriptName) {
            return entries
        }
        let irisEntry: [String: Any] = [
            "hooks": [
                [
                    "type": "command",
                    "command": command
                ]
            ]
        ]
        entries.append(irisEntry)
        return entries
    }

    private static func hasIrisEntry(in branch: Any?, scriptName: String) -> Bool {
        guard let entries = branch as? [Any] else { return false }
        for entry in entries {
            guard let dict = entry as? [String: Any],
                  let hooks = dict["hooks"] as? [Any] else { continue }
            for hook in hooks {
                guard let hookDict = hook as? [String: Any],
                      let command = hookDict["command"] as? String else { continue }
                if command.hasSuffix("/\(scriptName)") {
                    return true
                }
            }
        }
        return false
    }
}

private extension NSError {
    static func iris(_ message: String) -> NSError {
        NSError(
            domain: "ClaudeHookInstaller",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
