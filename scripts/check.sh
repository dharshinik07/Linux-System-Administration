#!/bin/bash
# Non-root, temporary-directory validation. Does not touch the installed vault.
set -Eeuo pipefail
project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bash -n "$project_root/src/ztvault.sh"
bash -n "$project_root/scripts/setup.sh"
echo "PASS: Bash source and installer syntax"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir "$work/source" "$work/restored"
cp "$project_root"/samples/*.txt "$work/source/"
(
    cd "$work/source"
    sha256sum assignment.txt marks.txt canary.txt > "$work/original.sha256"
    sha256sum canary.txt > "$work/canary.sha256"
    tar -czf "$work/clean.tar.gz" assignment.txt marks.txt canary.txt
    printf '%s\n' 'Harmless test change.' >> canary.txt
    if sha256sum --check --status "$work/canary.sha256"; then
        echo "FAIL: Changed canary matched its baseline" >&2
        exit 1
    fi
)
echo "PASS: Changed sample canary fails its saved fingerprint"
tar -xzf "$work/clean.tar.gz" -C "$work/restored" --no-same-owner --no-same-permissions
(cd "$work/restored"; sha256sum --check "$work/original.sha256")
echo "PASS: Restored sample files match their original fingerprints"
echo "These checks do not test Linux account permissions or live systemd scheduling."
