![Zero-Trust Vault — Linux System Administration](docs/assets/vault-header.svg)

# Zero-Trust Enterprise Storage Vault with Automated Ransomware Defense and Disaster Rollback

A student can edit an assignment. An outsider cannot read it. What happens if a file that nobody should edit changes? This Ubuntu microproject uses a **canary file** to detect that change, restricts student access, and lets an administrator restore a verified backup.

**[Project report (PDF)](docs/Project_Report.pdf) · [Web application presentation (PPTX)](docs/Project_Presentation.pptx) · [Screenshot evidence](screenshots/README.md)**

## Run the application

Use **Ubuntu with systemd and sudo access**, including Ubuntu on WSL2. From Ubuntu Bash:

```bash
git clone https://github.com/dharshinik07/Linux-System-Administration.git
cd Linux-System-Administration/web-v2
sudo bash run.sh
```

Open **http://localhost:8765** in your browser and leave the terminal open. No package installation through npm or pip is needed. The launcher uses the existing project vault if present. On a fresh system, it invokes the supplied installer to create dedicated Linux accounts, directories and sample files. Use a lab machine or WSL distribution for the demonstration.

For the original Bash terminal interface, run `sudo ztvault` after setup. See the [terminal setup guide](docs/SETUP.md) and [web application guide](web-v2/README.md) for details.

## Five-minute faculty demonstration

| Step | Action in the browser | What it demonstrates |
|---|---|---|
| 1 | **Overview** → check vault access, backup and monitor status | Current state of the Linux vault |
| 2 | **Defense & recovery** → **Backup / verify**, then **Test access** | Establish the clean baseline before editing. The student can read the assignment; the outsider cannot. |
| 3 | **Student workspace** → add a sentence and save | Bash appends the text as the student. The interface reads the file back and displays its modification time in IST. |
| 4 | **Defense & recovery** → **Enable monitor**, then **Simulate incident** and type `DEMO` | Safely change only the sample canary. No malware runs. |
| 5 | Allow a timer interval, then **Test blocking** | The monitor detects the mismatch, restricts the vault and logs an alert. |
| 6 | **Recover files** → type `RESTORE`, then reopen the workspace | The administrator verifies and restores the clean backup. The sentence added after backup disappears from the active file. |
| 7 | **Activity & logs** → inspect the recent events | Compare the edit, alert and recovery timestamps. New web events display in IST; older unzoned entries retain their original time. |

## How it works

The browser sends a selected action to a local Python HTTP adapter. The adapter validates the request and calls an allowed Bash operation. The original terminal menu also uses Bash. Linux permissions enforce access, and a systemd timer checks the canary approximately every ten seconds while Ubuntu runs.

| Linux command | Role in the project |
|---|---|
| `runuser` | Test the student and outsider accounts using their actual permissions. |
| `chmod` | Change the vault directory from group access (`2770`) to owner-only access (`0700`) during containment. |
| `tee -a` | Append the student's sentence without replacing the assignment. |
| `sha256sum` and `tar` | Check fingerprints, archive the clean files, and verify them during recovery. |
| `flock` | Keep the timer and interactive operations from modifying vault state simultaneously. |
| `systemctl` and `journalctl` | Manage the timer and inspect the monitoring service's output. |

## Source, evidence and validation

| Resource | Use it for |
|---|---|
| [Web frontend](web-v2/web/) · [HTTP adapter](web-v2/server.py) · [Web Bash engine](web-v2/src/ztvault.sh) | Current application source |
| [Original Bash menu](src/ztvault.sh) · [Code walkthrough](docs/CODE_EXPLANATION.md) | Explain the terminal implementation used in the report |
| [Web tests](web-v2/tests/) · [Terminal demo steps](docs/DEMO.md) | Reproduce checks on Ubuntu |
| [Four-person speaking script](docs/Four_Person_Speaking_Script.pdf) | Earlier terminal presentation; use the current PPT speaker notes for the web review |

From the cloned repository root, run `python3 web-v2/tests/test_web.py` for portable checks. The separate `sudo python3 web-v2/tests/integration.py` test creates temporary Linux accounts and an isolated vault; run it on your Ubuntu lab machine to exercise real permission boundaries. The screenshots document the recorded **terminal** demonstration.

**Scope:** Detection covers the canary. Changes elsewhere may go undetected. The backup is local and single-version; it cannot recover from total disk loss. The dashboard is a local administrator demonstration. Recovery requires explicit confirmation.

## Project team

| Member | Registration number |
|---|---|
| Dharshini K | 2411021060912 |
| Kani V | 2411021061023 |
| Hemanath K | 2411021060862 |
| Ibadul Azam | 2411021060840 |

**Supervisor:** Prof. Kusuma J  
**Course:** Linux System Administration (E1ITA307), Alliance School of Advanced Computing, Alliance University, Bengaluru.
