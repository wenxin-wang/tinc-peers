#!/bin/bash

trap '>&2 echo Error on line $LINENO' ERR

if [ $# -ne 2 ]; then
    echo usage: $0 dir subnet
    exit 1
fi

dir=$1
subnet=$2

subnet_txt=$dir/subnet.txt
peers_txt=$dir/peers.txt

if [ -e $subnet_txt ]; then
    echo "$subnet_txt already exists"
    exit 1
fi

mkdir -p $dir
echo "$subnet" >$subnet_txt
touch $peers_txt
