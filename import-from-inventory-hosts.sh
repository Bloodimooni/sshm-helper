#!/usr/bin/env bash
# Import hosts from a Tarook/Ansible YAML inventory into sshm.
# sshm reads ~/.ssh/config and stores tags as a "# Tags: a, b" comment
# directly above each Host block, so entries are appended in that format.
#
# Usage: import-from-inventory-hosts.sh <hosts.yaml> [tag1,tag2,...] [ssh_config]
# Without tags you are asked whether to set some (default: no).
# ssh_config defaults to ~/.ssh/config.

set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") <hosts.yaml> [tag1,tag2,...] [ssh_config]" >&2
    exit 1
}

[[ $# -lt 1 || $# -gt 3 ]] && usage

inventory="$1"
tags_raw="${2:-}"
ssh_config="${3:-$HOME/.ssh/config}"

[[ -r "$inventory" ]] || { echo "error: cannot read $inventory" >&2; exit 1; }

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

# Host keys sit at 4-space indent under <group>.hosts; emit "host ip" pairs.
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
    /^    [^ #][^ ]*: *$/ { h = $1; sub(/:$/, "", h); next }
    /^      local_ipv4_address:/ { print h, $2 }
' "$inventory")

echo "done: $added added, $skipped skipped ($ssh_config)"
