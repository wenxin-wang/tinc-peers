#!/bin/bash

trap '>&2 echo Error on line $LINENO' ERR

if [ $# -ne 1 ]; then
    echo usage: $0 dir
    exit 1
fi

dir=$1

_hosts=$dir/_hosts
ssh_txt=$dir/ssh.txt

if [ ! -r $ssh_txt ]; then
    echo "$ssh_txt not found!"
    echo "Each line of it should be 'tinc_name<space>ssh_options'"
    echo "Lines could be commented with a starting '#'"
    echo "Example content of the file:"
    echo "host1 example.com"
    echo "host2 -p 2000 abc.example.com"
    exit 1
fi

declare -A HOSTS

while read -r line; do
    read -r host ssh_opts <<<$line
    HOSTS[$host]=$ssh_opts
done < <(grep -v '^\s*#' $ssh_txt)

sync_pub_key() {
    echo "sync public key from $_h to $peer"
    local _psopts=${HOSTS[$peer]}
    local peer_tinc_hosts=$tinc_dir/$_h/hosts
    local cmd="mkdir -p $peer_tinc_hosts; cat >$peer_tinc_hosts/$_h"
    echo $cmd
    if [ z"$_psopts" == zlocalhost ]; then
        echo "$pub_key" | \
            sudo bash -c "$cmd"
    else
        echo "$pub_key" | \
            ssh $_psopts "sudo bash -c '$cmd'"
    fi
    echo "sync complete"
}

copy_conf() {
    local d
    for d in $host_dir/*; do
        peer=${d##*/}
        if [ z"${HOSTS[$peer]}" == z ]; then
            continue
        fi
        if [ ! -e $tinc_dir/$peer/tinc.conf ]; then
            mkdir -p $tinc_dir
            echo "copying configs for connection from $_h to $peer"
            sudo cp -r $host_dir/$peer $tinc_dir
            sudo mkdir -p $tinc_dir/$peer/hosts
            echo "copy complete"
        fi
        tinc_hosts=$tinc_dir/$peer/hosts
        if [ ! -e $tinc_dir/$peer/rsa_key.priv ]; then
            echo "generating public key for connection from $_h to $peer"
            sudo cp $_hosts/$_h $tinc_hosts
            sudo tincd -n $peer -K2048
            pub_key=$(sudo cat $tinc_hosts/$_h)
            echo "generate complete"
            sync_pub_key
        fi
    done
}

upload_conf() {
    ssh $_sopts "sudo mkdir -p /etc/tinc"
    local d
    for d in $host_dir/*; do
        peer=${d##*/}
        if [ z"${HOSTS[$peer]}" == z ]; then
            continue
        fi
        if ! ssh $_sopts "sudo test -e $tinc_dir/$peer/tinc.conf"; then
            echo "uploading configs for connection from $_h to $peer"
            tar -cz -C $host_dir $peer | \
                ssh $_sopts \
                    "sudo bash -c '
mkdir -p $tinc_dir;
tar -xz --no-same-owner -C $tinc_dir;
mkdir -p $tinc_dir/$peer/hosts'"
            echo "upload complete"
        fi
        tinc_hosts=$tinc_dir/$peer/hosts
        if ! ssh $_sopts "sudo test -e $tinc_dir/$peer/rsa_key.priv"; then
            echo "generating public key for connection from $_h to $peer"
            cat $_hosts/$_h | ssh $_sopts "sudo bash -c 'cat >$tinc_hosts/$_h'"
            ssh -t $_sopts "sudo tincd -n $peer -K2048"
            pub_key=$(ssh $_sopts "sudo cat $tinc_hosts/$_h")
            echo "generate complete"
            sync_pub_key
        fi
    done
}

tinc_dir=/etc/tinc
for _h in "${!HOSTS[@]}"; do
    host_dir=$dir/$_h
    _sopts=${HOSTS[$_h]}
    if [ z"$_sopts" == z ]; then
        continue
    elif [ "$_sopts" == localhost ]; then
        copy_conf
    else
        upload_conf
    fi
done

# ssh $@ $dest "sudo mkdir -p /etc/tinc"
#

#     n=${d##*/}
#     dest_conf=/etc/tinc/$n
#     echo $dest_conf/rsa_key.priv
#     ssh $@ $dest "sudo gzip -c /etc/tinc/$n/hosts/$host" | gzip -d >$host_dir/$n/hosts/$host
# done
