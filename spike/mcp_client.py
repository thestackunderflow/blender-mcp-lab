"""A minimal MCP stdio client (stdlib only) for the spike: starts the server, initializes, lists tools, calls one
tool, prints JSON. Every message both ways is appended to a JSONL log. Usage:
    python3 mcp_client.py --log out/spike-wire.jsonl --call get_scene_info '{}' -- mcp-for-blender
"""
import argparse
import json
import subprocess
import sys
import time

ap = argparse.ArgumentParser()
ap.add_argument('--log', required=True)
ap.add_argument('--call', nargs=2, metavar=('TOOL', 'ARGS_JSON'))
ap.add_argument('cmd', nargs=argparse.REMAINDER)
a = ap.parse_args()
cmd = a.cmd[1:] if a.cmd and a.cmd[0] == '--' else a.cmd

log = open(a.log, 'a', encoding='utf8')
p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=sys.stderr, text=True, bufsize=1)
nid = [0]


def send(method, params=None, notify=False):
    msg = {'jsonrpc': '2.0', 'method': method}
    if params is not None:
        msg['params'] = params
    if not notify:
        nid[0] += 1
        msg['id'] = nid[0]
    log.write(json.dumps({'t': time.time(), 'dir': 'client->server', 'msg': msg}) + '\n')
    p.stdin.write(json.dumps(msg) + '\n')
    p.stdin.flush()
    if notify:
        return None
    while True:
        line = p.stdout.readline()
        if not line:
            raise SystemExit('server closed')
        try:
            r = json.loads(line)
        except ValueError:
            continue
        log.write(json.dumps({'t': time.time(), 'dir': 'server->client', 'msg': r}) + '\n')
        if r.get('id') == msg['id']:
            return r


init = send('initialize', {'protocolVersion': '2025-06-18', 'capabilities': {}, 'clientInfo': {'name': 'blender-spike', 'version': '0'}})
send('notifications/initialized', notify=True)
tools = send('tools/list', {})
out = {'serverInfo': init.get('result', {}).get('serverInfo'),
       'tools': [t['name'] for t in tools.get('result', {}).get('tools', [])],
       'tools_json_chars': len(json.dumps(tools.get('result', {}).get('tools', [])))}
if a.call:
    r = send('tools/call', {'name': a.call[0], 'arguments': json.loads(a.call[1])})
    res = r.get('result', {})
    out['call'] = {'tool': a.call[0], 'isError': res.get('isError'),
                   'text': ' '.join(c.get('text', '') for c in res.get('content', []) if c.get('type') == 'text')[:3000],
                   'error': r.get('error')}
print(json.dumps(out, indent=2))
p.stdin.close()
p.terminate()
