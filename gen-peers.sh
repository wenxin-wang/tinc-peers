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

if [ ! -f $peers_txt ]; then
    echo "$peers_txt not exists"
    exit 1
fi

generate_conf() {
    local name=$1
    local addr=$2
    local net=$3
    local peer=$4
    local peer_port=$5
    local conf_dir=$dir/$name/$net
    local tinc_conf=$conf_dir/tinc.conf
    if [ -e $conf_dir ]; then
        echo $conf_dir already exists
    else
        mkdir -p $dir/$name
        cp -r $__DIR__/templates $conf_dir
        sed -i "s|@name@|$name|g" $tinc_conf
        if grep -q '^\<Address\>' $hosts/$peer; then
            sed -i "s|^#\<ConnectTo\>.*$|ConnectTo = $peer|g" $tinc_conf
        fi
        sed -i "s|@addr@|$addr/30|g" $conf_dir/tinc-up
    fi
}

while read -r line; do
    read -r h1 ip1 net1 h2 ip2 net2 <<<$line
    IFS=":" read -r peer1 port1 <<<$h1
    IFS=":" read -r peer2 port2 <<<$h2
    assert_host $hosts $peer1
    assert_host $hosts $peer2
    generate_conf $peer1 $ip1 $net1 $peer2 $port2
    generate_conf $peer2 $ip2 $net2 $peer1 $port1
done < <(grep -v '^\s*#' $peers_txt)
