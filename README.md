# sshm-helper

Import hosts into `~/.ssh/config` for sshm.

```
./import-from-inventory-hosts.sh <hosts.yaml> [tag1,tag2,...] [ssh_config]
./import-from-ssh-known-hosts.sh <ssh_known_hosts> [tag1,tag2,...] [ssh_config]
```

Without tags you are asked whether to set some. `ssh_config` defaults to `~/.ssh/config`.
