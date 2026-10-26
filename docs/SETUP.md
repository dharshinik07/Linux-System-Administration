# Ubuntu setup and operation

## 1. Check the environment

```bash
cat /etc/os-release
uname -r
ps -p 1 -o comm=
findmnt -T "$HOME"
command -v bash tar sha256sum flock systemctl runuser
```

For this setup, PID 1 must be `systemd`. The demonstrated environment is Ubuntu 26.04 on WSL2 using ext4.

## 2. Fresh installation

From the repository root:

```bash
bash scripts/check.sh
sudo bash scripts/setup.sh
sudo ztvault
```

The installer creates the two test accounts and access group, installs the sample files with Linux permissions, and copies the Bash application to `/usr/local/sbin/ztvault`. Both test accounts have interactive login disabled. It does not enable monitoring or create a baseline until you choose those menu options.

Choose **4** to create the clean backup, then **10** to enable monitoring. Existing project paths or colliding users/groups cause the installer to stop before changing them. This prevents accidentally overwriting a previously working demonstration. If installation stops after an unexpected system error, inspect the reported error and existing state instead of deleting the vault or accounts blindly.

## 3. Existing installation

Simply run:

```bash
sudo ztvault
```

Use option 8 with `RESTORE` if a previous incident left the vault locked. Do not run setup to reset the demonstration.

## 4. Inspect permissions and monitoring

```bash
id ztv_writer
id ztv_outsider
sudo ls -ld /srv/ztvault/data /var/lib/ztvault/backups
systemctl status ztvault-monitor.timer --no-pager
sudo journalctl -u ztvault-monitor.service -n 20 --no-pager
sudo tail -n 25 /var/log/ztvault/events.log
```

`active (waiting)` is normal for the timer. The oneshot service may be inactive between checks. Option 10 writes these units under `/etc/systemd/system/`:

- `ztvault-monitor.service`: runs `/usr/local/sbin/ztvault --monitor`.
- `ztvault-monitor.timer`: `OnActiveSec=10s`, `OnUnitActiveSec=10s`, `AccuracySec=1s`.

## 5. Pause or resume checks

```bash
sudo systemctl stop ztvault-monitor.timer
sudo systemctl start ztvault-monitor.timer
```

Stopping the timer does not unlock an incident. Use verified recovery through the menu. To disable future timer activation when you finish using the project:

```bash
sudo systemctl disable --now ztvault-monitor.timer
```

## Common results

| Message | Explanation |
|---|---|
| Setup stopped: existing project | Use `sudo ztvault`; setup protects existing state |
| Create the clean backup first | Choose option 4 before simulation or monitoring |
| Backup already exists | Option 4 verifies the preserved original |
| Permission denied during an access test | Expected when testing outsider/backup/incident restrictions |
| LOCKED | An incident remains active; use option 8 and `RESTORE` |
| No incident is active | Option 7 is meaningful only after containment |
| Assignment sentence disappears after recovery | The clean backup predates that sentence |

The repository deliberately includes no automatic uninstall or destructive reset script.
