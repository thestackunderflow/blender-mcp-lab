#!/bin/bash
# One real, logged Claude Code session with Blender (runs INSIDE the lab container; started by run-claude.sh).
# Blender 5.2.2 runs with its window on a virtual display; the whole session is screen-recorded; every MCP message
# between Claude Code and mcp-for-blender 2.1.9 (pinned) is logged by mcp_log_proxy.py. Plan: plan v3.1 (18 Oct 2026).
# Clean-run recipe: only the blender MCP tools, no built-in tools, no personal settings (none exist in the container).
set -u
OUT=/work/tests/out/${RUN_DIR:-claude-run}
mkdir -p "$OUT"
export DISPLAY=:99
Xvfb :99 -screen 0 1920x1080x24 >"$OUT/xvfb.log" 2>&1 &
sleep 2
mcp-for-blender install-addon >/dev/null 2>&1
# light theme (the channel's rule) and no splash; nothing saved to the user's preferences
cat > /tmp/look.py <<'PY'
import bpy, os
d = [os.path.join(p, f) for p in bpy.utils.preset_paths("interface_theme") for f in os.listdir(p) if f.lower().startswith("blender_light")]
if d: bpy.ops.script.execute_preset(filepath=d[0], menu_idname="USERPREF_MT_interface_theme_presets")
bpy.context.preferences.view.show_splash = False
PY
blender --python /tmp/look.py >"$OUT/blender.log" 2>&1 &
for i in $(seq 1 60); do (echo > /dev/tcp/127.0.0.1/9876) 2>/dev/null && break; sleep 1; done
sleep 4
WID=$(xdotool search --name "Blender" | head -1); xdotool windowactivate --sync "$WID" 2>/dev/null
xdotool key Escape; sleep 1; xdotool mousemove 800 500; xdotool key n; sleep 1; xdotool mousemove 1562 350 click 1; sleep 1
xdotool mousemove 800 600

# the whole session on video (1080p30), stopped at the end
ffmpeg -v error -y -f x11grab -framerate 30 -video_size 1920x1080 -i :99 -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p "$OUT/screen.mp4" &
FFPID=$!

cat > /tmp/mcp.json <<JSON
{ "mcpServers": { "blender": { "command": "python3",
  "args": ["/work/proxy/mcp_log_proxy.py", "--log", "$OUT/blender-mcp.jsonl", "--png-dir", "$OUT", "--", "mcp-for-blender"] } } }
JSON
SESSION=$(python3 -c 'import uuid; print(uuid.uuid4())'); echo "$SESSION" > "$OUT/session-id.txt"
mkdir -p /tmp/work && cd /tmp/work
COMMON=(--mcp-config /tmp/mcp.json --strict-mcp-config --tools "" --allowedTools "mcp__blender"
        --permission-mode dontAsk --max-budget-usd 1.5 --output-format stream-json --verbose)

run() {   # run <n> <prompt> <--session-id|--resume>
  echo "{\"prompt\": $1, \"started\": \"$(date -u +%FT%TZ)\", \"video_s\": $(python3 -c "import time;print(round(time.time()-$T0,1))")}" >> "$OUT/timeline.jsonl"
  timeout 900 claude -p "$2" "$3" "$SESSION" "${COMMON[@]}" < /dev/null > "$OUT/prompt-$1.stream.jsonl" 2> "$OUT/prompt-$1.stderr.txt"
  echo "{\"prompt\": $1, \"exit\": $?, \"ended\": \"$(date -u +%FT%TZ)\", \"video_s\": $(python3 -c "import time;print(round(time.time()-$T0,1))")}" >> "$OUT/timeline.jsonl"
  sleep 3
}
T0=$(python3 -c 'import time;print(time.time())')

run 1 'What objects are in my Blender scene right now?' --session-id
run 2 'Make the cube blue.' --resume
run 3 'Replace the cube with a simple four-wheel rover (a body and four wheels) standing on a round showroom platform. Keep it simple, and tell me what you built.' --resume

# PLANTED DEFECT, done by the lab (not by the AI), logged and labelled in the video: one wheel lifted 0.6 m.
echo "{\"planted_defect\": \"one wheel lifted 0.6 m by the lab script, not by the AI\", \"video_s\": $(python3 -c "import time;print(round(time.time()-$T0,1))")}" >> "$OUT/timeline.jsonl"
python3 /work/spike/mcp_client.py --log "$OUT/lab-client.jsonl" --call execute_blender_code \
  '{"code": "import bpy\nw=[o for o in bpy.data.objects if \"wheel\" in o.name.lower()]\nw.sort(key=lambda o:o.name)\nprint(\"LIFTED\", w[0].name if w else None)\nif w: w[0].location.z += 0.6"}' \
  -- mcp-for-blender > "$OUT/planted-defect.json" 2>&1
sleep 3

run 4 'Check your work before we continue: look at the scene from two different angles and tell me if anything looks wrong. Do not change anything yet.' --resume
run 5 'Fix what you found, then look again to confirm it is fixed.' --resume
run 6 'Add a simple animation: the rover turns one full circle on its platform over 4 seconds. Then save the file as /tmp/work/rover.blend.' --resume

sleep 2
kill -INT "$FFPID"; wait "$FFPID" 2>/dev/null
cp /tmp/work/rover.blend "$OUT/" 2>/dev/null
ls -la "$OUT" > "$OUT/files.txt"
echo done
