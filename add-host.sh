#!/bin/bash

trap '>&2 echo Error on line $LINENO' ERR

if [ $# -ne 2 ]; then
    echo usage: $0 dir host
    exit 1
fi

dir=$1
host=$2

_hosts=$dir/_hosts

if [ -e $_hosts/$host ]; then
    echo "$_hosts/$host already exists"
    exit 1
fi

mkdir -p $_hosts
cat <<EOF >$_hosts/$host
# Address = ::
# Address = 127.0.0.1
EOF
echo "Please check $_hosts/$host"

