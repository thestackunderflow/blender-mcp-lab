# Spike report: Blender MCP in Docker (18 Oct 2026)

**Verdict: GO, Docker works.** No Blender install on Windows needed for the lab (it stays an allowed fallback).

| Question | Result | Evidence |
|---|---|---|
| Blender 5.2.2 LTS with its normal window in Docker? | Yes, on a virtual display (Xvfb), software rendering | `out/01-blender-window.png` |
| `uvx mcp-for-blender setup` headless? | Installs and enables the add-on; "No MCP clients found" (no Claude Code in the image yet) | `out/setup.txt` |
| Add-on server up? | Port 9876 open about 5 s after Blender starts | `spike.sh` output |
| MCP round trip (test client, not an AI) | `get_scene_info` → "1 camera, 1 light, 1 mesh … Cube, Light, Camera" | `out/05-scene-info.json`, `out/spike-wire.jsonl` |
| Tools offered | 9 tools, 16,796 characters of tool JSON (server "MCP for Blender" 1.30.0, add-on 1.8) | `out/05-scene-info.json` |
| Light theme for the channel | Blender's own "Blender Light" preset applied at start, splash off | `out/03-light-n-panel.png` |
| The beginner shot: N panel → MCP for Blender tab | "✓ Connected on port 9876" + Disconnect (not "Start MCP Server" in this version) | `out/05-mcp-tab.png` |
| Screen recording | ffmpeg x11grab, 30 fps, 5 s test OK | `out/04-recording-test.mp4` |

Things the video should mention neutrally: the panel also shows a "Get Premium" upsell for AI model generation,
a "Join Discord" button and an "up to date" check (the add-on contacts the internet for updates). CORRECTION (18 Oct, fact-check of run B): only CONTENT collection (prompts, code, screenshots) is opt-in. A minimal
anonymous usage record IS sent by default (README: "What is collected by default (no opt-in)"); run B logged 18 POSTs
to the telemetry endpoint ("201 Created") with the consent prompt cancelled. DISABLE_TELEMETRY=true turns it off.

Still open (need the owner's Claude Code token in `.env`): Claude Code inside the container, the real session
("what's in my scene?", "make the cube blue", the rover), and recording `setup` with Claude Code detected.
