#!/bin/bash

trap '>&2 echo Error on line $LINENO' ERR

if [ $# -ne 3 ]; then
    echo usage: $0 dir peer1 peer2
    exit 1
fi

__DIR__=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

dir=$1
peer1=$2
peer2=$3

_hosts=$dir/_hosts
peers_txt=$dir/peers.txt

subnet=$(cat $dir/subnet.txt)

if [ ! -f $_hosts/$peer1 ]; then
    echo "$peer1 not configured in $_hosts"
    echo "Maybe you should call '$__DIR__/add-host.sh $dir $peer1'"
    exit 1
fi

if [ ! -f $_hosts/$peer2 ]; then
    echo "$peer2 not configured in $_hosts"
    echo "Maybe you should call '$__DIR__/add-host.sh $dir $peer2'"
    exit 1
fi

touch $peers_txt
line=$(grep -w $peer1 $peers_txt | grep -w $peer2 || :)
if [ z"$line" != z ]; then
    read -r nid d_ a1 d_ a2 <<<$line
else
    read -r nid a1 a2 <<<$($__DIR__/get_peer_addrs.py $subnet $peers_txt)
    echo "$nid $peer1 $a1 $peer2 $a2" >>$peers_txt
fi

if [ z"$nid" == z ]; then
    echo "No address available in $subnet, see $dir/peers.txt"
    exit 1
fi

generate_conf() {
    local name=$1
    local addr=$2
    local peer=$3
    local conf_dir=$dir/$name/${peer}
    local tinc_conf=$conf_dir/tinc.conf
    if [ -e $conf_dir ]; then
        echo $conf_dir already exists
    else
        mkdir -p $dir/$name
        cp -r $__DIR__/templates $conf_dir
        sed -i "s|@name@|$name|g" $tinc_conf
        if grep -q '^\<Address\>' $_hosts/$peer; then
            sed -i "s|^#\<ConnectTo\>.*$|ConnectTo = $peer|g" $tinc_conf
        fi
        sed -i "s|@addr@|$addr/30|g" $conf_dir/tinc-up
    fi
}


generate_conf $peer1 $a1 $peer2
generate_conf $peer2 $a2 $peer1
