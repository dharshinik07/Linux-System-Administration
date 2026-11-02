# Code explanation

The source is `src/ztvault.sh`. It begins with strict Bash options, a controlled PATH, root privilege checks, required-directory checks and a shared operation lock.

| Function | Responsibility |
|---|---|
| `log_event` | Append a timestamped event |
| `require_open` | Reject ordinary operations during an incident |
| `check_samples` | Require regular, non-symlink sample files |
| `view_files` | Read assignment and marks as the student |
| `update_assignment` | Validate a sentence and append it through `runuser` |
| `test_permissions` | Demonstrate student access and expected denials |
| `verify_backup` | Check backup metadata availability and archive checksum |
| `create_backup` | Preserve one verified clean archive and trusted fingerprints |
| `monitor` | Check canary, restrict access on failure, record incident |
| `simulate_incident` | Make a harmless canary change after exact `DEMO` input |
| `test_blocked_write` | Test write denial during an incident |
| `recover_files` | Verify and restore originals after exact `RESTORE` input |
| `show_log` | Display the last 25 application log lines |
| `enable_monitoring` | Write and enable systemd service/timer units |
| `show_status` | Display vault, backup and timer status |

## Main execution flow

1. Validate privileges and setup.
2. Open file descriptor 9 for the operation lock.
3. In `--monitor` mode, attempt the nonblocking lock and perform one check.
4. Otherwise display the menu in a `while` loop.
5. Use `read -r` to accept a choice and `case` to select a function.
6. Lock the operation, execute it, report failures, then unlock.
7. Return to the menu until option 0 or end of input.

## Find code during the review

From the repository:

```bash
grep -nE '^[a-z_]+\(\)' src/ztvault.sh
sed -n '/^update_assignment()/,/^}/p' src/ztvault.sh
sed -n '/^monitor()/,/^}/p' src/ztvault.sh
sed -n '/^recover_files()/,/^}/p' src/ztvault.sh
```

The PDF source appendix omits printed line numbers. `grep -n` is only a navigation aid when reviewing the actual source file.

## Key commands

- `chmod`: change permissions; containment sets the root-owned directory to 0700.
- `runuser`: execute file operations with a test account's permissions.
- `sha256sum`: calculate and verify fingerprints; does not encrypt files.
- `tar`: create, compare and extract the compressed archive.
- `flock`: serialize monitor and menu operations.
- `systemctl`: manage timer/service units.
- `journalctl`: read systemd service logs.
- `tee`: append accepted input as data.
- `tail`: show recent application events.
- `install`: create directories and copy files with explicit ownership/modes.
