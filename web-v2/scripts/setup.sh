#!/bin/bash
# Fresh installation only. Never resets an existing demonstration.
set -Eeuo pipefail
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
umask 077
if (( EUID != 0 )); then
    echo "Run from the repository: sudo bash scripts/setup.sh" >&2
    exit 1
fi
project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for tool in bash getent groupadd useradd install ps tar sha256sum flock systemctl runuser tee mktemp; do
    command -v "$tool" >/dev/null || { echo "Missing required command: $tool" >&2; exit 1; }
done
if [[ "$(ps -p 1 -o comm= | tr -d '[:space:]')" != systemd ]]; then
    echo "This demonstration requires Ubuntu running systemd as PID 1." >&2
    exit 1
fi
# Refuse any existing project state before creating accounts or directories.
for target in /srv/ztvault /var/lib/ztvault /var/log/ztvault /usr/local/sbin/ztvault \
    /etc/systemd/system/ztvault-monitor.service /etc/systemd/system/ztvault-monitor.timer; do
    if [[ -e "$target" || -L "$target" ]]; then
        echo "Existing project detected: $target" >&2
        echo "Setup stopped without changing it. Use sudo ztvault for your existing project." >&2
        exit 1
    fi
done
for account in ztv_writer ztv_outsider; do
    if getent passwd "$account" >/dev/null; then
        echo "Account already exists: $account. Setup stopped." >&2
        exit 1
    fi
done
for group in ztv_access ztv_outsider; do
    if getent group "$group" >/dev/null; then
        echo "Group already exists: $group. Setup stopped." >&2
        exit 1
    fi
done
bash -n "$project_root/src/ztvault.sh"
for name in assignment.txt marks.txt canary.txt; do
    [[ -f "$project_root/samples/$name" ]] || { echo "Missing sample: $name" >&2; exit 1; }
done
groupadd ztv_access
useradd -M -g ztv_access -s /usr/sbin/nologin ztv_writer
useradd -M -U -s /usr/sbin/nologin ztv_outsider
install -d -o root -g root -m 0755 /srv/ztvault
install -d -o root -g ztv_access -m 2770 /srv/ztvault/data
install -d -o root -g root -m 0700 /var/lib/ztvault \
    /var/lib/ztvault/backups /var/lib/ztvault/baselines \
    /var/lib/ztvault/recovery /var/log/ztvault
for name in assignment.txt marks.txt canary.txt; do
    install -o root -g ztv_access -m 0660 \
        "$project_root/samples/$name" "/srv/ztvault/data/$name"
done
install -o root -g root -m 0750 "$project_root/src/ztvault.sh" /usr/local/sbin/ztvault
echo "Installed. Run: sudo ztvault"
echo "Choose 4 to create the clean backup, then 10 to enable monitoring."
echo "Setup does not start monitoring or create a backup automatically."
