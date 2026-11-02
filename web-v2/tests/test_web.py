"""Non-root tests: real file timestamps, event parsing, HTTP and action validation.
The subprocess boundary is stubbed only where privileged Linux access is required.
"""
import importlib.util,json,tempfile,unittest,threading,urllib.request,urllib.error,subprocess
from pathlib import Path
from datetime import datetime,timezone
from unittest.mock import patch
from types import SimpleNamespace
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('vault_server',ROOT/'server.py');app=importlib.util.module_from_spec(spec);spec.loader.exec_module(app)
class Tests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.path=Path(self.tmp.name)
  self.vault=patch.object(app,'VAULT',self.path);self.vault.start()
  self.log=patch.object(app,'EVENT_LOG',self.path/'events.log');self.log.start()
 def tearDown(self):self.log.stop();self.vault.stop();self.tmp.cleanup()
 def test_save_and_filesystem_timestamp(self):
  p=self.path/'assignment.txt';p.write_text('Original\n')
  import os
  os.utime(p,(1000,1000))
  before=app.metadata()['files']['assignment.txt']['modified_at']
  def backend(args,**kw):
   self.assertEqual(args[-1],'append')
   with p.open('a') as f:f.write(kw['input'])
   return SimpleNamespace(returncode=0,stdout='SUCCESS: Assignment updated and saved to disk.')
  with patch.object(app.subprocess,'run',side_effect=backend):result=app.execute('append','Saved sentence')
  self.assertTrue(result['ok']);self.assertIn('Saved sentence',p.read_text())
  stamp=result['files']['assignment.txt']['modified_at'];self.assertNotEqual(before,stamp)
  self.assertAlmostEqual(datetime.fromisoformat(stamp).timestamp(),p.stat().st_mtime,places=2)
  self.assertEqual(datetime.fromisoformat(stamp).utcoffset().total_seconds(),0)
 def test_actual_bash_append_and_utc_event(self):
  # Isolate all paths; emulate only the account-switch boundary, not file I/O.
  vault=self.path/'data';state=self.path/'state';logs=self.path/'logs'
  for p in (vault,state/'backups',state/'baselines',state/'recovery',logs):p.mkdir(parents=True,exist_ok=True)
  for name in ('assignment.txt','marks.txt','canary.txt'):(vault/name).write_text('Original\n')
  code=(ROOT/'src/ztvault.sh').read_text().split('# Browser adapter:')[0]
  code=code.replace('/srv/ztvault/data',str(vault)).replace('/var/lib/ztvault',str(state)).replace('/var/log/ztvault',str(logs))
  code=code.replace('if (( EUID != 0 )); then','if false; then')
  code+='\nrunuser() { shift 3; "$@"; }\nflock 9\nupdate_assignment\n'
  script=self.path/'append-test.sh';script.write_text(code)
  p=vault/'assignment.txt';import os;os.utime(p,(1000,1000));before=p.stat().st_mtime
  r=subprocess.run(['bash',str(script)],input='Actual Bash save test\n',capture_output=True,text=True)
  self.assertEqual(r.returncode,0,r.stderr);self.assertIn('SUCCESS',r.stdout)
  self.assertEqual(p.read_text(),'Original\nActual Bash save test\n');self.assertGreater(p.stat().st_mtime,before)
  event=(logs/'events.log').read_text().split(' | ')[0]
  self.assertTrue(event.endswith('Z'));self.assertLess(abs(datetime.fromisoformat(event.replace('Z','+00:00')).timestamp()-p.stat().st_mtime),2)
 def test_log_history_not_reinterpreted(self):
  app.EVENT_LOG.write_text('2026-10-31 06:42:59 | UPDATE: Old entry\n2026-10-31T06:42:59Z | UPDATE: New entry\n')
  entries=app.events();self.assertFalse(entries[0]['legacy']);self.assertTrue(entries[1]['legacy']);self.assertIsNone(entries[1]['timestamp'])
 def test_http_validation(self):
  server=app.http.server.ThreadingHTTPServer(('127.0.0.1',0),app.Handler)
  port=server.server_address[1];base=f'http://127.0.0.1:{port}'
  def request(path,data=None,headers=None):
   body=json.dumps(data).encode() if data is not None else None
   try:
    with urllib.request.urlopen(urllib.request.Request(base+path,data=body,headers=headers or {})) as r:return r.status,r.read()
   except urllib.error.HTTPError as e:return e.code,e.read()
  with patch.object(app,'HOSTS',{f'127.0.0.1:{port}'}):
   thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
   try:
    self.assertEqual(request('/')[0],200)
    self.assertEqual(request('/api/action',{'action':'status'})[0],403)
    headers={'Origin':base,'X-Vault-Token':app.TOKEN,'Content-Type':'application/json'}
    for d in ({'action':[]},{'action':'append','value':''},{'action':'append','value':'x\ny'},{'action':'append','value':'x'*201},{'action':'restore','value':'no'},{'action':'simulate','value':'no'}):self.assertEqual(request('/api/action',d,headers)[0],400)
    self.assertEqual(request('/../../etc/passwd')[0],404)
    self.assertEqual(request('/api/action',{'action':'status'},dict(headers,Origin='https://example.org'))[0],403)
   finally:server.shutdown();server.server_close()
if __name__=='__main__':unittest.main(verbosity=2)
