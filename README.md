# Blender MCP lab: connect Claude Code to Blender, then check what it really built

The lab behind **"Blender MCP: Connect Claude and Build Your First 3D Scene" (MCP Servers, Tested #5)**.
Blender 5.2.2 LTS and [mcp-for-blender](https://github.com/ahujasid/mcp-for-blender) 2.1.9 run in Docker with Blender's
real window on a virtual display, so the whole session is screen-recorded, and every MCP message between Claude Code
and the server is logged.

Lab snapshot: **18 October 2026**. Blender 5.2.2 LTS · mcp-for-blender 2.1.9 (server "MCP for Blender" 1.30.0, add-on 1.8)
· Claude Code 2.1.302 (claude-opus-5-5) · uv 0.9.2. Nothing is installed on the host except Docker and Claude Code's login token.

## What happened (run B, the session in the video)

Six plain requests, one session, only the Blender MCP tools (no file or shell tools). About two minutes, **$0.33**.

| # | Request | What Claude did | Evidence |
|---|---|---|---|
| 1 | "What objects are in my Blender scene right now?" | `get_scene_info`: 1 camera, 1 light, 1 mesh (the cube) | `blender-mcp.jsonl` |
| 2 | "Make the cube blue." | one `execute_blender_code` call; said it hadn't looked at the result | `prompt-2.stream.jsonl` |
| 3 | "Replace the cube with a simple four-wheel rover … on a round showroom platform." | built it in one call, then `look` from two angles: "looks right" | screen.mp4 0:16–0:39 |
| — | **our test script, not the AI**, lifted `Rover_Wheel_1` by 0.6 m | | `planted-defect.json`, `timeline.jsonl` |
| 4 | "Check your work … look from two different angles … don't change anything yet." | found it from the scene data: wheel 1 at z = 1.3, the others at 0.7 | `prompt-4.stream.jsonl` |
| 5 | "Fix what you found, then look again." | moved it back to 0.7, printed all four, looked from four angles | `prompt-5.stream.jsonl` |
| 6 | "Add a simple animation: one full circle over 4 seconds … save the file." | first script crashed partway; the second carried on and saved `rover.blend` | `prompt-6.stream.jsonl`, `rover.blend` |

Everything is in `tests/out/claude-run-b/`. `NOTES.md` there explains two things worth knowing:

- **A wrong memory.** In request 4 Claude also said the wheel was "already raised" in its first three-quarter view and
  that it had missed it. Its first `look` finished at 16:29:56.96 UTC; our script moved the wheel at 16:30:03.73
  (`blender-mcp.jsonl`, `lab-client.jsonl`), and the recording shows all four wheels level at 0:40 and the raised one at 0:44.
  So that sentence was wrong. One run, so don't read too much into it: check the scene, not the summary.
- **A real crash.** The first animation script stopped with `'Action' object has no attribute 'fcurves'`
  (an API Blender 5 removed). What it did before the crash stayed in the scene, and the second script reused it.

Run A (`tests/out/claude-run/`) is kept on purpose: our session script only *copied* the add-on instead of enabling it,
so Blender was never connected. Claude reported every failure and claimed nothing. `session.sh` now uses `setup` and
refuses to start unless port 9876 is open.

## Defaults worth knowing (checked in this lab)

- The AI can run any Python in Blender. **Safe mode** (`BLENDER_MCP_SAFE_MODE=1`) is off by default; it checks scripts in
  the MCP server before they're sent. It reduces risk but is not a sandbox.
- The Blender add-on listens on **port 9876 with no login**: keep it on your own machine.
- **Usage data:** prompts, code and screenshots are only shared if you opt in, but a small anonymous usage record is sent
  **by default** (the project's README says so; run B logged 18 sends to the telemetry endpoint). `DISABLE_TELEMETRY=true`
  turns it off.

## Run it

```sh
docker build -t blender-mcp-lab:0.1 .
# the spike: Blender with its window, the add-on, get_scene_info through MCP, screenshots and a short recording
docker run --rm --shm-size 1g -v "$PWD:/work" blender-mcp-lab:0.1 bash spike/spike.sh

# the real Claude Code session (needs your own token: `claude setup-token`, then CLAUDE_CODE_OAUTH_TOKEN=... in .env)
cp .env.example .env    # paste the token; .env is git-ignored
RUN_DIR=claude-run-c bash claude-run/run-claude.sh
```

A new run never overwrites an old one (`run-claude.sh` refuses an existing `RUN_DIR`). Results go to `tests/out/<RUN_DIR>/`:
`screen.mp4`, `blender-mcp.jsonl` (every MCP message), `prompt-N.stream.jsonl` (Claude Code's own log), `timeline.jsonl`.

## Files

- `Dockerfile`: Debian 12 + Blender 5.2.2 (checksummed) + uv + mcp-for-blender 2.1.9 + Claude Code 2.1.302.
- `spike/`: the first feasibility run and its report (`SPIKE-REPORT.md`, including a correction about usage data).
- `claude-run/`: `run-claude.sh` (host side) and `session.sh` (inside the container).
- `proxy/mcp_log_proxy.py`: logs every MCP message both ways; screenshots are saved with time + hash names.
- `video/frames/`: stills from run B's recording used in the video.

## Limits

One session, one model, one machine (Linux in Docker, software rendering). Another run can go differently.
mcp-for-blender is a community project, not made by the Blender Foundation.

License: Apache-2.0 (this lab). Blender is GPL; mcp-for-blender has its own license.
