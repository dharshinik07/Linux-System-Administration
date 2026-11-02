#!/bin/bash
set -Eeuo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
if (( EUID != 0 )); then echo 'Run: sudo bash run.sh'; exit 1; fi
command -v python3 >/dev/null || { echo 'Install Python: sudo apt install python3'; exit 1; }
if [[ ! -d /srv/ztvault/data ]]; then
    bash scripts/setup.sh
fi
for directory in /srv/ztvault/data /var/lib/ztvault/backups /var/lib/ztvault/baselines /var/lib/ztvault/recovery /var/log/ztvault; do
    [[ -d "$directory" && ! -L "$directory" ]] || { echo "Incomplete existing installation: $directory"; exit 1; }
done
# Run from a private root-owned snapshot; existing vault data is never reset.
runtime=$(mktemp -d /run/ztvault-web-XXXXXX)
trap 'rm -rf -- "$runtime"' EXIT
cp -r server.py web src "$runtime/"
chmod -R go-rwx "$runtime"
python3 "$runtime/server.py"
