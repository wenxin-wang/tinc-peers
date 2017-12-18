#!/usr/bin/env python3
import sys
import ipaddress as ipaddr


def main(subnet, peers_txt):
    nids = set()
    with open(peers_txt, 'r') as fd:
        for line in fd:
            nid, _ = line.split(' ', 1)
            nids.add(int(nid))
    subnet = ipaddr.IPv4Network(subnet)
    if len(nids) == subnet.prefixlen:
        return
    nids = sorted(nids)
    prev = 0
    for i in nids:
        if prev + 1 < i:
            break
        prev = i
    subnet_int = int(subnet.network_address)
    subnet_int += (4 * prev)
    print("%d %s %s" % (prev + 1, ipaddr.IPv4Address(subnet_int + 1),
                        ipaddr.IPv4Address(subnet_int + 2)))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
