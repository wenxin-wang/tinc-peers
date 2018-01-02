#!/bin/bash

trap '>&2 echo Error on line $LINENO' ERR

if [ $# -ne 1 ]; then
    echo usage: $0 dir
    exit 1
fi

__DIR__=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

. $__DIR__/common.sh

dir=$1

hosts=$dir/_hosts
peers_txt=$dir/peers.txt

declare -A PAIRS IPS

while read -u 3 -r line; do
    read -r h1 ip1 net1 h2 ip2 net2 <<<$line
    IFS=":" read -r peer1 port1 <<<$h1
    IFS=":" read -r peer2 port2 <<<$h2
    assert_host $hosts $peer1
    assert_host $hosts $peer2
    PAIRS[$peer1]="$net1 ${PAIRS[$peer1]}"
    PAIRS[$peer2]="$net2 ${PAIRS[$peer2]}"
    IPS[$peer1]="$ip2 ${IPS[$peer1]}"
    IPS[$peer2]="$ip1 ${IPS[$peer2]}"
done 3< <(grep -v '^\s*#' $peers_txt)

for peer in "${!PAIRS[@]}"; do
    echo -----------------$peer-----------------------
    for net in ${PAIRS[$peer]}; do
        echo "sudo systemctl start tinc@$net"
    done
    for net in ${PAIRS[$peer]}; do
        echo "sudo systemctl --no-pager status tinc@$net"
    done
    for net in ${PAIRS[$peer]}; do
        echo "sudo systemctl enable tinc@$net"
    done
    for ip in ${IPS[$peer]}; do
        echo "ping $ip"
    done
done
