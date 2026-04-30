#!/usr/bin/env bash
# Iris hook: clear the marker file when a Claude Code session settles.
#
# Wired to Stop. Reads the JSON hook payload from stdin and removes
#   ~/.claude/iris-status/<session_id>.json
# so Iris drops the Claude-thinking tile.
set -euo pipefail

exec /usr/bin/python3 -c '
import json, os, sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

sid = data.get("session_id") or "unknown"
path = os.path.expanduser(f"~/.claude/iris-status/{sid}.json")
try:
    os.remove(path)
except FileNotFoundError:
    pass
'
