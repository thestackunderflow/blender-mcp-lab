#!/bin/sh
# Spike, 18 Oct 2026: can Blender 5.2.2 + mcp-for-blender 2.1.9 run in Docker with a real window, be driven over MCP,
# and be screen-captured? Run inside the image: docker run --rm -v <lab>:/work blender-mcp-lab:spike sh spike/spike.sh
set -u
OUT=/work/spike/out; mkdir -p "$OUT"; : > "$OUT/spike-wire.jsonl"
export DISPLAY=:99
Xvfb :99 -screen 0 1920x1080x24 >"$OUT/xvfb.log" 2>&1 &
sleep 2

echo "== 1. setup (no AI client inside this container yet)"
mcp-for-blender setup --help > "$OUT/setup-help.txt" 2>&1
timeout 60 mcp-for-blender setup < /dev/null > "$OUT/setup.txt" 2>&1; echo "setup exit=$?"; tail -20 "$OUT/setup.txt"

echo "== 2. install-addon (manual path), addon dirs"
mcp-for-blender addon-paths > "$OUT/addon-paths.txt" 2>&1; cat "$OUT/addon-paths.txt"
mcp-for-blender install-addon > "$OUT/install-addon.txt" 2>&1; echo "install-addon exit=$?"; tail -5 "$OUT/install-addon.txt"

echo "== 3. enable the addon and save preferences (headless, one shot)"
blender -b --factory-startup --python-expr "
import bpy, addon_utils
mods=[m.__name__ for m in addon_utils.modules() if 'mcp' in m.__name__.lower() or 'blender' in m.__name__.lower()]
print('ADDON_CANDIDATES', mods)
" > "$OUT/enable.txt" 2>&1; grep ADDON_CANDIDATES "$OUT/enable.txt"

echo "== 4. Blender with its window on the virtual display"
blender > "$OUT/blender.log" 2>&1 &
for i in $(seq 1 60); do (echo > /dev/tcp/127.0.0.1/9876) 2>/dev/null && { echo "port 9876 open after ${i}s"; break; }; sleep 1; done
sleep 3
ffmpeg -v error -y -f x11grab -video_size 1920x1080 -i :99 -frames:v 1 "$OUT/01-blender-window.png" && echo "screenshot 1 ok"

echo "== 5. MCP: tools/list + get_scene_info through mcp-for-blender (a test client, not an AI)"
timeout 60 python3 /work/spike/mcp_client.py --log "$OUT/spike-wire.jsonl" --call get_scene_info '{}' -- mcp-for-blender > "$OUT/05-scene-info.json" 2>"$OUT/05-stderr.txt"
echo "mcp exit=$?"; head -c 1500 "$OUT/05-scene-info.json"; echo

echo "== 6. the N panel"
WID=$(xdotool search --name "Blender" | head -1); echo "window=$WID"
xdotool windowactivate --sync "$WID" 2>/dev/null; xdotool mousemove 900 500; xdotool key n; sleep 2
ffmpeg -v error -y -f x11grab -video_size 1920x1080 -i :99 -frames:v 1 "$OUT/02-n-panel.png" && echo "screenshot 2 ok"
echo "== done"
