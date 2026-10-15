#!/usr/bin/env bash
# Import hosts from an ssh_known_hosts file (@cert-authority lines) into sshm.
# sshm reads ~/.ssh/config and stores tags as a "# Tags: a, b" comment
# directly above each Host block, so entries are appended in that format.
#
# Usage: import-from-ssh-known-hosts.sh <ssh_known_hosts> [tag1,tag2,...] [ssh_config]
# Without tags you are asked whether to set some (default: no).
# ssh_config defaults to ~/.ssh/config.

set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") <ssh_known_hosts> [tag1,tag2,...] [ssh_config]" >&2
    exit 1
}

[[ $# -lt 1 || $# -gt 3 ]] && usage

known_hosts="$1"
tags_raw="${2:-}"
ssh_config="${3:-$HOME/.ssh/config}"

[[ -r "$known_hosts" ]] || { echo "error: cannot read $known_hosts" >&2; exit 1; }

if [[ -z "$tags_raw" ]]; then
    read -r -p "Set tags? [y/N] " answer || true
    if [[ "$answer" =~ ^[Yy] ]]; then
        read -r -p "Tags (comma-separated): " tags_raw || true
    fi
fi

# "cah,cluster-demo-1" -> "cah, cluster-demo-1" (format sshm writes)
tags="$(sed -E 's/[[:space:]]*,[[:space:]]*/, /g; s/^[[:space:]]+|[[:space:]]+$//g' <<<"$tags_raw")"

mkdir -p "$(dirname "$ssh_config")"
touch "$ssh_config"
chmod 600 "$ssh_config"
cp "$ssh_config" "$ssh_config.bak.$(date +%Y%m%d%H%M%S)"

added=0
skipped=0

# "@cert-authority name,ip1,ip2 keytype key" -> "name ip1"
while read -r host ip; do
    [[ -z "$host" || -z "$ip" ]] && continue

    if grep -qE "^[[:space:]]*Host[[:space:]]+(.*[[:space:]])?${host//./\\.}([[:space:]]|$)" "$ssh_config"; then
        echo "skip: $host already in $ssh_config"
        skipped=$((skipped + 1))
        continue
    fi

    {
        # blank separator line if file is non-empty and doesn't end with one
        if [[ -s "$ssh_config" && -n "$(tail -n1 "$ssh_config")" ]]; then
            echo
        fi
        [[ -n "$tags" ]] && echo "# Tags: $tags"
        echo "Host $host"
        echo "    HostName $ip"
    } >>"$ssh_config"

    echo "add:  $host -> $ip"
    added=$((added + 1))
done < <(awk '
    $1 == "@cert-authority" { n = split($2, f, ","); if (n >= 2) print f[1], f[2] }
' "$known_hosts")

echo "done: $added added, $skipped skipped ($ssh_config)"
