#!/usr/bin/env bash
# Starts the logged Claude Code + Blender session (claude-run/session.sh) inside the lab container.
# Needs: docker, the image blender-mcp-lab:0.1, and .env with CLAUDE_CODE_OAUTH_TOKEN (git-ignored; passed at run time).
set -uo pipefail
cd "$(dirname "$0")/.."
LAB="$(pwd -W 2>/dev/null || pwd)"
RUN_DIR=${RUN_DIR:-claude-run}
OUT=tests/out/$RUN_DIR
[ -f .env ] || { echo "no .env with CLAUDE_CODE_OAUTH_TOKEN" >&2; exit 2; }
# A run's evidence is never overwritten: pick a new RUN_DIR instead.
[ -e "$OUT" ] && { echo "refusing: $OUT exists (set RUN_DIR=claude-run-<x>)" >&2; exit 1; }
mkdir -p "$OUT"
MSYS_NO_PATHCONV=1 docker run --rm --shm-size 1g --env-file .env -e RUN_DIR="$RUN_DIR" -v "$LAB:/work" \
  blender-mcp-lab:0.1 bash /work/claude-run/session.sh > "$OUT/session-console.txt" 2>&1
echo "exit $?"
