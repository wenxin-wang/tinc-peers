#!/bin/bash

trap '>&2 echo Error on line $LINENO' ERR

if [ $# -ne 1 ]; then
    echo usage: $0 dir
    exit 1
fi

dir=$1

peers_txt=$dir/peers.txt

mkdir -p $dir
if [ ! -e $peers_txt ]; then
    cat <<EOF >$peers_txt
# addr will be used as addr/30
# peer1:port1 addr1 peer2:port2 addr2
# peer2:port1 addr1 peer3:port2 addr2
EOF
fi
