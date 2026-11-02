#!/usr/bin/env python3
"""Real Linux permission/backup/recovery checks in a temporary isolated vault."""
import os, pathlib, subprocess, tempfile, shutil
assert os.geteuid()==0, 'Run: sudo python3 tests/integration.py'
ROOT=pathlib.Path(__file__).resolve().parents[1]
suffix=str(os.getpid()); writer='ztwt'+suffix; outsider='ztot'+suffix; group='ztgt'+suffix
created=[]
def cmd(*args): return subprocess.run(args,check=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
try:
 cmd('groupadd',group);created.append(('group',group))
 for user in (writer,outsider):
  cmd('useradd','-M','-g',group if user==writer else 'nogroup','-s','/usr/sbin/nologin',user);created.append(('user',user))
 with tempfile.TemporaryDirectory(prefix='ztvault-web-test-') as temp:
  t=pathlib.Path(temp);t.chmod(0o755);vault=t/'data';base=t/'state';log=t/'logs'
  for p in (vault,base/'backups',base/'baselines',base/'recovery',log):p.mkdir(parents=True,exist_ok=True)
  base.chmod(0o700);log.chmod(0o700)
  shutil.chown(vault,user='root',group=group);vault.chmod(0o2770)
  for p in (ROOT/'samples').iterdir():
   q=vault/p.name;shutil.copy(p,q);shutil.chown(q,user='root',group=group);q.chmod(0o660)
  code=(ROOT/'src/ztvault.sh').read_text().replace('/srv/ztvault/data',str(vault)).replace('/var/lib/ztvault',str(base)).replace('/var/log/ztvault',str(log)).replace('ztv_writer',writer).replace('ztv_outsider',outsider).replace('ztv_access',group)
  script=t/'test-core.sh';script.write_text(code)
  def run(action,value=''):
   r=subprocess.run(['bash',str(script),'--web',action],input=value+'\n',text=True,capture_output=True)
   assert r.returncode==0,(action,r.stdout,r.stderr)
   return r.stdout+r.stderr
  assert run('permissions').count('PASS:')==3;print('PASS: real student / outsider / backup permissions')
  assert 'SUCCESS' in run('backup');print('PASS: clean backup creation')
  assert 'ERROR' in run('append','');print('PASS: empty input rejected')
  before=(vault/'assignment.txt').stat().st_mtime_ns
  assert 'SUCCESS' in run('append','Browser integration test')
  assert (vault/'assignment.txt').stat().st_mtime_ns>=before
  assert 'Z | UPDATE:' in (log/'events.log').read_text()
  assert 'Browser integration test' in run('view')
  assert 'SAFE' in run('check');print('PASS: legitimate edits preserve SAFE state')
  assert 'preserved' in run('backup');print('PASS: existing clean backup preserved')
  run('simulate','DEMO');assert 'ALERT' in run('check');assert 'PASS:' in run('blocked');print('PASS: canary change, containment and denied write')
  assert 'cancelled' in run('restore','NO');assert (base/'incident').exists();print('PASS: recovery confirmation enforced')
  assert 'SUCCESS' in run('restore','RESTORE');assert 'SAFE' in run('check');assert 'Browser integration test' not in run('view');print('PASS: verified rollback and reopened access')
finally:
 for kind,name in reversed(created):
  subprocess.run(['userdel' if kind=='user' else 'groupdel',name],capture_output=True)
