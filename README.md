# sshm-helper

Import hosts into `~/.ssh/config` for [sshm](https://github.com/Gu1llaum-3/sshm) and sort them into per-cluster config files.

## Install

```
sudo curl -fsSL https://raw.githubusercontent.com/Bloodimooni/sshm-helper/main/sshm-helper -o /usr/local/bin/sshm-helper && sudo chmod +x /usr/local/bin/sshm-helper
```

Run the same command again to update. `move-cluster` without arguments needs `fzf`.

## Usage

```
sshm-helper import-inventory   <hosts.yaml>      [tag1,tag2,...] [ssh_config]
sshm-helper import-known-hosts <ssh_known_hosts> [tag1,tag2,...] [ssh_config]
sshm-helper move-cluster       [cluster[,cluster...]] [ssh_config]
```

- `import-*`: appends hosts (with a `# Tags:` line, as sshm writes it). Without tags you are asked whether to set some. Hosts already in the config are skipped.
- `move-cluster`: moves all hosts of a cluster (host name minus `-<role>-<index>`, e.g. `k8s-cloud-svcs-test-gw-0` → `k8s-cloud-svcs-test`) into `config_<cluster>` next to `ssh_config` and adds an `Include` for it at the top. Without a cluster name a table (fzf, TAB for multi-select) lets you pick.

`ssh_config` defaults to `~/.ssh/config`. Every command writes a `ssh_config.bak.<timestamp>` backup first.
