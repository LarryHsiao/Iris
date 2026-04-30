#!/usr/bin/env bash
# Iris hook: write a marker file for the active Claude Code session.
#
# Wired to UserPromptSubmit, PreToolUse, and PostToolUse. Reads the JSON
# hook payload from stdin and drops a small JSON file at
#   ~/.claude/iris-status/<session_id>.json
# which Iris polls to light its Claude-thinking tile.
set -euo pipefail

exec /usr/bin/python3 -c '
import json, os, sys, time

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

sid = data.get("session_id") or "unknown"
cwd = data.get("cwd") or ""
tool = data.get("tool_name") or None
project = os.path.basename(cwd) if cwd else "unknown"

status = "tool" if tool else "thinking"
out_dir = os.path.expanduser("~/.claude/iris-status")
os.makedirs(out_dir, exist_ok=True)

with open(os.path.join(out_dir, f"{sid}.json"), "w") as f:
    json.dump({
        "sessionId": sid,
        "project": project,
        "status": status,
        "tool": tool,
        "since": int(time.time()),
    }, f)
'
