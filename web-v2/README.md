# Zero-Trust Vault — Web Control Center v2

A local browser interface for the existing Linux microproject. Real Bash operations manage assignment edits, permission tests, clean backup verification, canary monitoring, incident containment, logs and verified manual recovery.

## What changed in v2

- Separate Overview, Student workspace, Defense & recovery, and Activity & logs views. Sidebar clicks replace the current view; browser back/forward works through hash routes.
- Assignment last-modified time comes from the actual filesystem timestamp, returned as an explicit UTC instant and displayed in **Asia/Kolkata (IST)**.
- Saving reads back the file and checks for the submitted sentence before displaying the save receipt.
- New web events record ISO-8601 UTC timestamps with `Z`; the Activity view converts these to IST and displays newest events first.
- Old unzoned entries are preserved and labelled **Legacy server time**. Their timezone cannot safely be reconstructed from the text alone.
- The browser clock, file modification time, log event time and log retrieval time are separately labelled.
- Server responses are not cached. Status refreshes every six seconds; API requests are serialized in the browser.
- Enable monitor installs the updated UTC-logging monitor at `/usr/local/lib/ztvault-web/monitor.sh` and updates the existing systemd service. Click **Enable monitor** once after upgrading to use this version for automatic events. The original terminal command is retained.

Example: **31 Oct 2026 06:42:59 UTC = 31 Oct 2026 12:12:59 IST**. A 12:14 browser operation time is the log retrieval time, not necessarily the time the assignment was updated.

## Upgrade

Stop the previous web server with Ctrl+C. Extract this folder separately and run it using the commands below. Existing sample files, clean backup and event history remain in their original Linux locations. Do not delete the vault or run a reset.

## Run in Ubuntu / WSL

Extract this folder, open Ubuntu in it, then run:

```bash
sudo bash run.sh
```

Open **http://localhost:8765** in your Windows browser. Keep Ubuntu open. Press Ctrl+C to stop the web server. No pip, npm, database, internet assets or build step is required. Python 3 and the original Linux utilities are required.

Existing `/srv/ztvault/data` and backup state are preserved. If no vault exists, the supplied fresh installer creates the accounts, directories and sample files; it refuses colliding existing state. On a new installation, click **Backup / verify**, then **Enable monitor**. Do not re-run setup manually on an existing vault.

## Five-minute review

1. Open dashboard. Explain the three live state cards.
2. Click **View current files**, then enter a sentence and **Save sentence**.
3. Click **Test access**. Student reading succeeds; outsider and student backup access are denied.
4. Click **Backup / verify**. Existing clean backups are preserved.
5. Click **Enable monitor**, then **Check now** to see SAFE.
6. Click **Simulate incident** and type `DEMO`. Wait approximately 15 seconds, or click **Check now**.
7. The vault becomes LOCKED. Click **Test blocking** and **Load security log**.
8. Click **Recover files**, type `RESTORE`. The original files return and access reopens.
9. Demonstrate blank input or an incorrect confirmation word being rejected.

Recovery replaces active sample files with the clean backup originals. Later legitimate edits disappear from the active vault; previous files are preserved under `/var/lib/ztvault/recovery`.

## Architecture and files

| File | Role |
|---|---|
| `web/index.html` | Dashboard, forms and confirmation dialogs |
| `web/style.css` | Responsive dark interface, keyboard focus, mobile layouts |
| `web/app.js` | Browser events, validation, API calls, six-second status refresh |
| `server.py` | Python standard-library HTTP adapter with fixed action allowlist |
| `src/ztvault.sh` | Existing Bash application plus noninteractive `--web` dispatcher |
| `scripts/setup.sh` | Fresh-install-only account and storage configuration |
| `run.sh` | Existing-state checks and private root-owned runtime snapshot |
| `tests/integration.py` | Isolated real Linux permissions, backup, detection and recovery tests |

Browser → local HTTP adapter → fixed Bash operation → Linux permissions / protected storage / systemd.

The Python adapter executes argument arrays, never arbitrary shell commands. Browser inputs reach Bash through stdin. Operations use the existing flock lock. The original installed terminal application and monitoring service remain compatible. Existing installed scripts are not overwritten when launching against an existing vault.

## Important scope

This upgrade adds HTML, CSS, JavaScript and a small Python HTTP adapter. **It is not a Bash-only application as a whole.** The security and storage operations remain Bash/Linux. Confirm the faculty permits the web layer under the revised frontend requirement. The original terminal interface is still included.

This is a local administrator demonstration, not an internet-facing enterprise service. The server binds only to loopback, validates Host/Origin, requires a random session token for operations, and serves only three allowlisted assets. It has no multi-user login or remote deployment support. Do not expose it using a public tunnel.

Canary detection covers changes to the trap file, not all ransomware. `chmod` cannot stop root or revoke already-open file handles. Backups are local and single-version; monitoring is approximately ten seconds while Ubuntu runs. The simulation modifies harmless sample text, not malware. A backup being PRESENT does not prove its integrity: use Backup / verify.

## Validation

Passed during packaging:

- Python, JavaScript and Bash syntax checks.
- Real Bash append and disk read-back in an isolated temporary vault, with only the account-switch boundary emulated because this environment prohibits `runuser`.
- Filesystem modification time advances after writing; server metadata matches that timestamp.
- New Bash event time is UTC with a `Z` suffix and matches the write time within two seconds.
- Old logs remain marked unzoned; new UTC events parse correctly.
- HTTP serving, token/origin checks, action allowlist, input bounds, confirmation validation and path restrictions.
- JavaScript route contract: only one of the four views is visible, active navigation changes correctly, and the screenshot's example UTC time converts to 12:12:59 IST.

Run the portable tests:

```bash
python3 tests/test_web.py
```

The route check used a lightweight DOM stub, not a rendered browser. A browser installation attempt failed, so visual browser QA remains unverified here. This environment also prevents real Linux account creation/switching. For complete privileged integration on Ubuntu:

```bash
sudo python3 tests/integration.py
```

This creates temporary test accounts and a temporary vault, and removes them afterward; it does not use the installed project vault. Validate live systemd scheduling separately:

```bash
systemctl status ztvault-monitor.timer --no-pager
sudo journalctl -u ztvault-monitor.service -n 20 --no-pager
```

### Confirm the timestamp on your laptop

1. Open Student workspace and save a new sentence.
2. Confirm the sentence appears and the green save receipt shows the new file time.
3. Run this in a second Ubuntu terminal:

```bash
sudo env TZ=Asia/Kolkata stat -c 'Assignment modified: %y' /srv/ztvault/data/assignment.txt
sudo tail -n 3 /var/log/ztvault/events.log
```

The stat time uses `+0530` and should match the UI to the second. New log entries use UTC (`Z`); add 5 hours 30 minutes to compare them with IST. If the Windows and Ubuntu clocks differ by more than two minutes, the UI displays a clock-mismatch message.

## Troubleshooting

- If the address is occupied: `sudo env ZTV_PORT=8766 bash run.sh`, then open http://localhost:8766.
- If already locked: recover using RESTORE and a valid clean backup.
- If setup reports incomplete existing state: preserve your data and inspect the named path; do not delete it to bypass the check.
- If automatic monitoring is inactive: enable it, with systemd running as PID 1 (`ps -p 1 -o comm=`).
- Permission denied in expected outsider/backup tests is a successful restriction, not an application failure.

## Team

Dharshini K (2411021060912) · Kani V (2411021061023) · Hemanath K (2411021060862) · Ibadul Azam (2411021060840)

Supervisor: Prof. Kusuma J. Alliance School of Advanced Computing, Alliance University. Linux System Administration — E1ITA307.
