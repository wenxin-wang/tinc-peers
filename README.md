---
title: tinc peer
---

Use tinc for one-to-one peer connection. By default, if you have multiple peers,
you are on the "same physical" network; but sometimes using one-to-one peer
connections to form a mesh network is desired, e.g. to use tunnels as one-to-one
links, and configure dynamic routing on it.

# Usage

All command could be called multiple times with the same arguments. It should
not break existing configurations. If you want to start from scratch, remove the
relevant files/directory.

## Init and Add Hosts

```bash
./init.sh $dir $subnet4
./add-host.sh $dir $host1
./add-host.sh $dir $host2
# Add address if a host could be connected to
vi $dir/_hosts/$host1
vi $dir/_hosts/$host2
```

## Connecting Peers

```bash
./add-peer.sh $dir $host1 $host2
```
