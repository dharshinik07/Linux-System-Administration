#!/usr/bin/env python3
"""Loopback-only browser adapter. Security operations remain in Bash."""
import http.server, json, os, secrets, subprocess, threading
from datetime import datetime, timezone
from pathlib import Path
ROOT = Path(__file__).resolve().parent
TOKEN = secrets.token_urlsafe(32)
PORT = int(os.environ.get('ZTV_PORT', '8765'))
HOSTS = {f'localhost:{PORT}', f'127.0.0.1:{PORT}'}
ACTIONS = {'view','append','permissions','backup','check','simulate','blocked','restore','logs','enable','status'}
LOCK = threading.Lock()
VAULT = Path('/srv/ztvault/data')
EVENT_LOG = Path('/var/log/ztvault/events.log')
def iso_time(epoch):
    return datetime.fromtimestamp(epoch, timezone.utc).isoformat(timespec='milliseconds')
def metadata():
    files = {}
    for name in ('assignment.txt', 'marks.txt', 'canary.txt'):
        p = VAULT/name
        if p.is_file() and not p.is_symlink():
            st = p.stat()
            files[name] = {'modified_at':iso_time(st.st_mtime), 'size':st.st_size}
    return {'files':files, 'server_time':iso_time(datetime.now(timezone.utc).timestamp()), 'display_timezone':'Asia/Kolkata'}
def events():
    if not EVENT_LOG.exists(): return []
    rows=[]
    # Limit memory even when an old event log is large.
    from collections import deque
    with EVENT_LOG.open(errors='replace') as f:
        lines=deque(f,maxlen=100)
    for line in lines:
        stamp, sep, message=line.strip().partition(' | ')
        instant=None
        try:
            d=datetime.fromisoformat(stamp.replace('Z','+00:00'))
            if d.tzinfo is not None: instant=d.astimezone(timezone.utc).isoformat()
        except ValueError: pass
        rows.append({'timestamp':instant,'original_time':stamp,'legacy':instant is None,'message':message if sep else stamp})
    return list(reversed(rows))
def execute(action, value=''):
    result = subprocess.run(['/bin/bash', str(ROOT/'src/ztvault.sh'), '--web', action], input=value+'\n', text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=40)
    output = result.stdout.strip()
    ok = result.returncode == 0 and not any(x in output for x in ('ERROR:', 'FAIL:', 'BLOCKED:', 'Recovery stopped:', 'cancelled.', 'Cancelled.'))
    return {'ok':ok, 'output':output or 'Operation completed.', **metadata(), 'events':events() if action=='logs' else None}
class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args): pass
    def respond(self, code, data, content='application/json'):
        body = json.dumps(data).encode() if content=='application/json' else data
        self.send_response(code)
        self.send_header('Content-Type', content+'; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control','no-store')
        self.send_header('X-Content-Type-Options','nosniff')
        self.send_header('X-Frame-Options','DENY')
        self.send_header('Referrer-Policy','no-referrer')
        self.send_header('Content-Security-Policy',"default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'")
        self.end_headers(); self.wfile.write(body)
    def trusted(self): return self.headers.get('Host') in HOSTS
    def do_GET(self):
        if not self.trusted(): return self.respond(403, {'error':'Invalid host'})
        files={'/':('index.html','text/html'),'/app.js':('app.js','text/javascript'),'/style.css':('style.css','text/css')}
        if self.path=='/api/session': return self.respond(200,{'token':TOKEN})
        if self.path not in files: return self.respond(404,{'error':'Not found'})
        name, kind=files[self.path]
        self.respond(200,(ROOT/'web'/name).read_bytes(),kind)
    def do_POST(self):
        if not self.trusted() or self.headers.get('Origin') not in {f'http://{h}' for h in HOSTS} or not secrets.compare_digest(self.headers.get('X-Vault-Token',''),TOKEN):
            return self.respond(403,{'error':'Unauthorized request. Refresh the dashboard.'})
        if self.path!='/api/action': return self.respond(404,{'error':'Not found'})
        try:
            n=int(self.headers.get('Content-Length','0'))
            if not 0<n<=4096: raise ValueError('Invalid request size')
            data=json.loads(self.rfile.read(n)); action=data.get('action'); value=data.get('value','')
            if not isinstance(action,str) or action not in ACTIONS: raise ValueError('Unknown action')
            if not isinstance(value,str) or '\n' in value or '\r' in value: raise ValueError('Enter one line of text')
            if action=='append' and (not value.strip() or len(value)>200): raise ValueError('Enter a sentence of 1–200 characters')
            if action in {'simulate','restore'} and value!={'simulate':'DEMO','restore':'RESTORE'}[action]: raise ValueError('Confirmation word does not match')
            if not LOCK.acquire(blocking=False): return self.respond(409,{'error':'Another operation is running. Try again.'})
            try: result=execute(action,value)
            finally: LOCK.release()
            self.respond(200,result)
        except (ValueError,TypeError,AttributeError) as e: self.respond(400,{'error':str(e)})
        except subprocess.TimeoutExpired: self.respond(504,{'error':'Operation timed out. Check vault status before retrying.'})
        except Exception: self.respond(500,{'error':'Operation failed. Check the Ubuntu terminal and project installation.'})
if __name__=='__main__':
    if os.geteuid()!=0: raise SystemExit('Run: sudo bash run.sh')
    print(f'\nVault dashboard: http://localhost:{PORT}\nKeep this terminal open. Ctrl+C stops the web server.\n',flush=True)
    try: http.server.ThreadingHTTPServer(('127.0.0.1',PORT),Handler).serve_forever()
    except KeyboardInterrupt: print('\nDashboard stopped. The systemd monitor remains unchanged.')
    except OSError as e: raise SystemExit(f'Cannot start dashboard: {e}. Try ZTV_PORT=8766 sudo -E bash run.sh')
