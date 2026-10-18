#!/bin/sh
# Spike part 2: light theme, no splash, the N panel (MCP for Blender tab), and a 5-second screen recording.
set -u
OUT=/work/spike/out; mkdir -p "$OUT"
export DISPLAY=:99
Xvfb :99 -screen 0 1920x1080x24 >"$OUT/xvfb2.log" 2>&1 &
sleep 2
mcp-for-blender setup < /dev/null > /dev/null 2>&1
# Light theme (Blender's own "Blender Light" preset) and no splash, applied at startup only (nothing saved).
cat > /tmp/look.py <<'PY'
import bpy, os
presets = bpy.utils.preset_paths("interface_theme")
light = [os.path.join(d, f) for d in presets for f in os.listdir(d) if f.lower().startswith("blender_light")]
print("THEME", light[:1])
if light:
    bpy.ops.script.execute_preset(filepath=light[0], menu_idname="USERPREF_MT_interface_theme_presets")
bpy.context.preferences.view.show_splash = False
PY
blender --python /tmp/look.py > "$OUT/blender2.log" 2>&1 &
for i in $(seq 1 60); do (echo > /dev/tcp/127.0.0.1/9876) 2>/dev/null && { echo "port 9876 open after ${i}s"; break; }; sleep 1; done
sleep 4
WID=$(xdotool search --name "Blender" | head -1)
xdotool windowactivate --sync "$WID" 2>/dev/null
xdotool key Escape; sleep 1
xdotool mousemove 800 500; sleep 0.5; xdotool key n; sleep 2
ffmpeg -v error -y -f x11grab -video_size 1920x1080 -i :99 -frames:v 1 "$OUT/03-light-n-panel.png" && echo "screenshot ok"
# open the "MCP for Blender" sidebar tab (vertical tab on the sidebar edge, measured on 03-light-n-panel.png)
xdotool mousemove 1562 350 click 1; sleep 2
ffmpeg -v error -y -f x11grab -video_size 1920x1080 -i :99 -frames:v 1 "$OUT/05-mcp-tab.png" && echo "screenshot mcp tab ok"
# a 5-second recording while the MCP client asks for the scene: the recording path the video would use
ffmpeg -v error -y -f x11grab -framerate 30 -video_size 1920x1080 -i :99 -t 5 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$OUT/04-recording-test.mp4" &
FF=$!
sleep 1
timeout 60 python3 /work/spike/mcp_client.py --log "$OUT/spike-wire.jsonl" --call get_scene_info '{}' -- mcp-for-blender > /dev/null 2>&1
wait $FF; ls -la "$OUT/04-recording-test.mp4"
grep THEME "$OUT/blender2.log"
echo "== done"
