# sshm-helper

Import hosts into `~/.ssh/config` for [sshm](https://github.com/Gu1llaum-3/sshm) and sort them into per-cluster config files.

## Install

```
sudo curl -fsSL https://raw.githubusercontent.com/Bloodimooni/sshm-helper/main/sshm-helper -o /usr/local/bin/sshm-helper && sudo chmod +x /usr/local/bin/sshm-helper
```

Run the same command again to update. `move-cluster` without arguments needs `fzf`.

## Usage

```
sshm-helper import       <file> [tag1,tag2,...] [ssh_config]
sshm-helper move-cluster [cluster[,cluster...]] [ssh_config]
sshm-helper include      [on|off] [ssh_config]
```

- `import`: appends hosts (with a `# Tags:` line, as sshm writes it). `<file>` can be a Tarook/Ansible inventory (`hosts.yaml`) or an `ssh_known_hosts` file with `@cert-authority` lines; the type is detected automatically. Without tags you are asked whether to set some, and afterwards whether to move the imported clusters into their own config files. Hosts already in the config (or a `sshm/config_*` file) are skipped.
- `move-cluster`: moves all hosts of a cluster (host name minus `-<role>-<index>`, e.g. `k8s-cloud-svcs-test-gw-0` → `k8s-cloud-svcs-test`) into `sshm/config_<cluster>` next to `ssh_config` (so `~/.ssh/sshm/`). It is deliberately not included from `ssh_config`, so the default sshm view stays small; open a cluster with `sshm -c ~/.ssh/sshm/config_<cluster>`. Without a cluster name a table (fzf, TAB for multi-select) lets you pick.
- `include`: adds (`on`) or removes (`off`) a single `Include sshm/config_*` line at the top of `ssh_config`, so all cluster files show up in plain `sshm` and work with plain `ssh`. Without `on`/`off` it toggles. Off by default.

`ssh_config` defaults to `~/.ssh/config`. `import` writes a backup to `~/.ssh/sshm/backups/` first; only the newest 7 backups are kept.
