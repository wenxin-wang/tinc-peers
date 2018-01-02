#!/bin/bash

trap '>&2 echo Error on line $LINENO' ERR

if [ $# -ne 2 ]; then
    echo usage: $0 dir host
    exit 1
fi

dir=$1
host=$2

hosts=$dir/_hosts

if [ -e $hosts/$host ]; then
    echo "$hosts/$host already exists"
    exit 1
fi

mkdir -p $hosts
cat <<EOF >$hosts/$host
# Address = ::
# Address = 127.0.0.1
EOF
echo "Please check $hosts/$host"

