#!/bin/bash
set -Eeuo pipefail
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
umask 077
VAULT=/srv/ztvault/data
BASE=/var/lib/ztvault
BACKUP=$BASE/backups/clean-backup.tar.gz
MANIFEST=$BASE/baselines/original-files.sha256
CANARY=$BASE/baselines/canary.sha256
INCIDENT=$BASE/incident
LOG=/var/log/ztvault/events.log
if (( EUID != 0 )); then
    echo "Please run: sudo ztvault"
    exit 1
fi
for directory in "$VAULT" "$BASE/backups" \
    "$BASE/baselines" "$BASE/recovery" /var/log/ztvault; do
    if [[ ! -d "$directory" || -L "$directory" ]]; then
        echo "ERROR: Required project directory missing: $directory"
        exit 1
    fi
done
exec 9>"$BASE/operation.lock"
log_event() {
    printf '%s | %s\n' "$(date '+%F %T')" "$*" >> "$LOG"
}
require_open() {
    if [[ -f "$INCIDENT" ]]; then
        echo "BLOCKED: An incident is active. Recover the files first."
        return 1
    fi
}
check_samples() {
    local name
    for name in assignment.txt marks.txt canary.txt; do
        if [[ ! -f "$VAULT/$name" || -L "$VAULT/$name" ]]; then
            echo "ERROR: $name is missing or is not a regular file."
            return 1
        fi
    done
}
view_files() {
    require_open || return 0
    check_samples || return 0
    echo "----- ASSIGNMENT -----"
    runuser -u ztv_writer -- cat "$VAULT/assignment.txt"
    echo
    echo "----- SAMPLE MARKS -----"
    runuser -u ztv_writer -- cat "$VAULT/marks.txt"
}
update_assignment() {
    require_open || return 0
    check_samples || return 0
    local note
    read -r -p "Enter one sentence to add to the assignment: " note
    if [[ -z "${note//[[:space:]]/}" ]]; then
        echo "ERROR: Input cannot be empty."
        return 0
    fi
    if (( ${#note} > 200 )); then
        echo "ERROR: Please enter 200 characters or fewer."
        return 0
    fi
    if printf '%s\n' "$note" |
        runuser -u ztv_writer -- tee -a "$VAULT/assignment.txt" \
        >/dev/null; then
        echo "SUCCESS: Assignment updated."
        log_event "UPDATE: Student added a sentence to the assignment."
    else
        echo "ERROR: Could not update the assignment."
    fi
}
test_permissions() {
    require_open || return 0
    check_samples || return 0
    echo "----- STUDENT READ TEST -----"
    if runuser -u ztv_writer -- cat "$VAULT/assignment.txt"; then
        echo "PASS: Student can read the assignment."
    else
        echo "FAIL: Student could not read the assignment."
    fi
    echo "----- OUTSIDER READ TEST -----"
    if runuser -u ztv_outsider -- cat "$VAULT/assignment.txt"; then
        echo "FAIL: Outsider could access the assignment."
    else
        echo "PASS: Outsider access denied."
    fi
    echo "----- STUDENT BACKUP ACCESS TEST -----"
    if runuser -u ztv_writer -- ls "$BASE/backups"; then
        echo "FAIL: Student could access the backup directory."
    else
        echo "PASS: Protected backup access denied."
    fi
}
verify_backup() {
    if [[ ! -f "$BACKUP" ||
          ! -f "$BASE/backups/clean-backup.sha256" ||
          ! -f "$MANIFEST" || ! -f "$CANARY" ]]; then
        echo "ERROR: Complete clean backup is unavailable."
        return 1
    fi
    (cd "$BASE/backups"; sha256sum --check clean-backup.sha256)
}
create_backup() {
    require_open || return 0
    check_samples || return 0
    if [[ -e "$BACKUP" || -e "$MANIFEST" || -e "$CANARY" ||
          -e "$BASE/backups/clean-backup.sha256" ]]; then
        echo "A backup or baseline already exists."
        if verify_backup; then
            echo "Existing backup verified. Original backup preserved."
        else
            echo "ERROR: Existing backup is incomplete or damaged."
        fi
        return 0
    fi
    (
        local work
        work=$(mktemp -d "$BASE/backups/.build-XXXXXX")
        trap 'chmod 2770 "$VAULT"; rm -rf -- "$work"' EXIT
        chmod 0700 "$VAULT"
        cd "$VAULT"
        sha256sum assignment.txt marks.txt canary.txt \
            > "$work/original-files.sha256"
        sha256sum canary.txt > "$work/canary.sha256"
        tar -czf "$work/clean-backup.tar.gz" \
            assignment.txt marks.txt canary.txt
        tar -dzf "$work/clean-backup.tar.gz"
        sha256sum --check "$work/original-files.sha256"
        (cd "$work"; sha256sum clean-backup.tar.gz > clean-backup.sha256)
        install -m 0600 "$work/original-files.sha256" "$MANIFEST"
        install -m 0600 "$work/canary.sha256" "$CANARY"
        install -m 0600 "$work/clean-backup.tar.gz" "$BACKUP"
        install -m 0600 "$work/clean-backup.sha256" \
            "$BASE/backups/clean-backup.sha256"
        log_event "BACKUP: Clean backup and fingerprints created."
        echo "SUCCESS: Clean backup created and verified."
    )
}
monitor() {
    if [[ -f "$INCIDENT" ]]; then
        chmod 0700 "$VAULT"
        echo "LOCKED: Incident active. Recovery is required."
        return 0
    fi
    if [[ ! -s "$CANARY" ]]; then
        echo "ERROR: Create the clean backup before monitoring."
        return 1
    fi
    if [[ -f "$VAULT/canary.txt" && ! -L "$VAULT/canary.txt" ]] &&
        (cd "$VAULT" && sha256sum --check --status "$CANARY"); then
        echo "SAFE: Canary matches its original fingerprint."
    else
        chmod 0700 "$VAULT"
        printf '%s\n' "Canary changed, disappeared, or became invalid." \
            > "$INCIDENT"
        log_event "ALERT: Canary check failed. Student vault access blocked."
        echo "ALERT: Suspicious canary change detected."
        echo "DEFENSE: Student access to the vault has been blocked."
    fi
}
simulate_incident() {
    require_open || return 0
    check_samples || return 0
    if [[ ! -s "$CANARY" ]]; then
        echo "ERROR: Create the clean backup first."
        return 0
    fi
    local answer
    read -r -p "Type DEMO to modify only the sample canary: " answer
    if [[ "$answer" != "DEMO" ]]; then
        echo "Cancelled. No files changed."
        return 0
    fi
    printf '%s\n' "Harmless demonstration change." |
        runuser -u ztv_writer -- tee -a "$VAULT/canary.txt" >/dev/null
    log_event "DEMO: Sample canary deliberately modified."
    echo "Sample canary changed."
    echo "The automatic monitor will detect it if enabled."
    echo "Otherwise, choose option 5 to check now."
}
test_blocked_write() {
    if [[ ! -f "$INCIDENT" ]]; then
        echo "No incident is active. Run the demonstration first."
        return 0
    fi
    if printf '%s\n' "Containment test" |
        runuser -u ztv_writer -- tee -a "$VAULT/assignment.txt" \
        >/dev/null; then
        echo "FAIL: Student could still write."
    else
        echo "PASS: Student cannot write while the vault is locked."
    fi
}
recover_files() {
    if ! verify_backup; then
        echo "Recovery stopped: Backup verification failed."
        return 0
    fi
    local answer stage old
    read -r -p "Restore original files? Type RESTORE: " answer
    if [[ "$answer" != "RESTORE" ]]; then
        echo "Recovery cancelled."
        return 0
    fi
    stage=$(mktemp -d "$BASE/recovery/restore-XXXXXX")
    tar -xzf "$BACKUP" -C "$stage" \
        --no-same-owner --no-same-permissions
    if ! (
        cd "$stage"
        sha256sum --check "$MANIFEST"
        sha256sum --check "$CANARY"
    ); then
        echo "ERROR: Recovered files failed verification."
        echo "Current vault was not replaced."
        return 0
    fi
    chmod 0700 "$VAULT"
    printf '%s\n' "Recovery in progress." > "$INCIDENT"
    old=$(mktemp -d "$BASE/recovery/previous-XXXXXX")
    mv "$VAULT" "$old/data"
    install -d -o root -g ztv_access -m 0700 "$VAULT"
    local name
    for name in assignment.txt marks.txt canary.txt; do
        install -o root -g ztv_access -m 0660 \
            "$stage/$name" "$VAULT/$name"
    done
    (cd "$VAULT"; sha256sum --check "$MANIFEST")
    chmod 2770 "$VAULT"
    rm -f "$INCIDENT"
    log_event "RECOVERY: Original files verified and restored."
    echo "SUCCESS: Original files restored. Student access reopened."
    echo "Previous files preserved in: $old/data"
}
show_log() {
    if [[ -f "$LOG" ]]; then
        tail -n 25 "$LOG"
    else
        echo "No events recorded yet."
    fi
}
enable_monitoring() {
    if [[ ! -s "$CANARY" ]]; then
        echo "ERROR: Create the clean backup first."
        return 0
    fi
    cat > /etc/systemd/system/ztvault-monitor.service <<'EOF'
[Unit]
Description=Student vault canary check
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/ztvault --monitor
UMask=0077
EOF
    cat > /etc/systemd/system/ztvault-monitor.timer <<'EOF'
[Unit]
Description=Check student vault every ten seconds
[Timer]
OnActiveSec=10s
OnUnitActiveSec=10s
AccuracySec=1s
Unit=ztvault-monitor.service
[Install]
WantedBy=timers.target
EOF
    systemctl daemon-reload
    systemctl enable --now ztvault-monitor.timer
    log_event "AUTOMATION: Ten-second security timer enabled."
    echo "SUCCESS: Automatic checks enabled."
    echo "Monitoring runs while this Ubuntu instance is running."
}
show_status() {
    if [[ -f "$INCIDENT" ]]; then
        echo "Vault status: LOCKED"
    else
        echo "Vault status: OPEN"
    fi
    if [[ -f "$BACKUP" ]]; then
        echo "Backup: Present"
    else
        echo "Backup: Not created"
    fi
    if systemctl is-active --quiet ztvault-monitor.timer; then
        echo "Automatic monitoring: ACTIVE"
    else
        echo "Automatic monitoring: INACTIVE"
    fi
}
if [[ "${1:-}" == "--monitor" ]]; then
    flock -n 9 || exit 0
    monitor
    exit 0
fi
if (( $# > 0 )); then
    echo "Usage: sudo ztvault"
    exit 1
fi
while true; do
    echo
    echo "=========================================="
    echo "       ZERO-TRUST STUDENT FILE VAULT"
    echo "=========================================="
    show_status
    echo "1. View assignment and marks"
    echo "2. Add a sentence to the assignment"
    echo "3. Test access permissions"
    echo "4. Create or verify clean backup"
    echo "5. Check security now"
    echo "6. Simulate a suspicious canary change"
    echo "7. Test write blocking after an incident"
    echo "8. Recover original files"
    echo "9. View security log"
    echo "10. Enable automatic monitoring"
    echo "0. Exit"
    if ! read -r -p "Enter your choice: " choice; then
        break
    fi
    case "$choice" in
        1) action=view_files ;;
        2) action=update_assignment ;;
        3) action=test_permissions ;;
        4) action=create_backup ;;
        5) action=monitor ;;
        6) action=simulate_incident ;;
        7) action=test_blocked_write ;;
        8) action=recover_files ;;
        9) action=show_log ;;
        10) action=enable_monitoring ;;
        0) echo "Application closed."; break ;;
        *) echo "ERROR: Enter a number from 0 to 10."; continue ;;
    esac
    flock 9
    set +e
    (
        set -Eeuo pipefail
        trap 'echo "ERROR: Operation failed. Review the message above." >&2' ERR
        "$action"
    )
    result=$?
    set -e
    flock -u 9
    if (( result != 0 )); then
        echo "Operation did not complete successfully."
    fi
    read -r -p "Press Enter to return to the menu..." || break
done
