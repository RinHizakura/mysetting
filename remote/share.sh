#!/usr/bin/env bash
# Serve the given directory (default: cwd) over HTTP and print a shareable LAN URL.
set -euo pipefail

DIR="${1:-.}"
PORT="${2:-8000}"
IP=$(ip -4 addr show scope global | awk '/inet/{print $2}' | cut -d/ -f1 | head -n1)

echo "Serving $DIR"
echo "Local:   http://localhost:$PORT"
echo "Network: http://${IP:-<unknown>}:$PORT"

cd "$DIR"
python3 -m http.server "$PORT"
