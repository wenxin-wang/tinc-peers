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
ssh_txt=$dir/ssh.txt
peers_txt=$dir/peers.txt

if [ ! -r $ssh_txt ]; then
    echo "$ssh_txt not found!"
    echo "Each line of it should be 'tinc_name<space>ssh_options'"
    echo "Lines could be commented with a starting '#'"
    echo "Example content of the file:"
    echo "host1 /etc/tinc example.com"
    echo "host2 /srv/container-data/tinc -p 2000 abc.example.com"
    exit 1
fi

declare -A HOSTS
declare -A TINC_DIR

while read -r line; do
    read -r host tinc_dir ssh_opts <<<$line
    HOSTS[$host]=$ssh_opts
    TINC_DIR[$host]=$tinc_dir
done < <(grep -v '^\s*#' $ssh_txt)

sync_pub_key() {
    echo "sync public key from $_name to $_peer"
    local peer_tinc_hosts="${TINC_DIR[$_peer]}"/$_pnet/hosts
    local cmd="mkdir -p $peer_tinc_hosts; cat >$peer_tinc_hosts/$_name"
    echo $cmd
    if [ z"$_popts" == zlocalhost ]; then
        echo "$pub_key" | \
            sudo bash -c "$cmd"
    else
        echo "$pub_key" | \
            ssh $_popts "sudo bash -c '$cmd'"
    fi
    echo "sync complete"
}

copy_conf() {
    local tinc_dir="${TINC_DIR[$_name]}"
    local tinc_hosts="${TINC_DIR[$_name]}"/$_net/hosts
    if [ ! -e $tinc_dir/$_net/tinc.conf ]; then
        mkdir -p $tinc_dir
        echo "copying configs for connection from $_name to $_peer"
        sudo cp -r $host_dir/$_net $tinc_dir
        sudo mkdir -p $tinc_hosts
        echo "copy complete"
    fi
    if [ ! -e $tinc_dir/$_net/rsa_key.priv ]; then
        echo "generating public key for connection from $_name to $_peer"
        sudo cp $hosts/$_name $tinc_hosts
        if [ z"$_port" != z ]; then
            sudo bash -c "echo 'Port = $_port' >>$tinc_hosts/$_name"
        fi
        sudo tincd -c $tinc_dir/$_net -K2048
        pub_key=$(sudo cat $tinc_hosts/$_name)
        echo "generate complete"
        sync_pub_key
    fi
}

upload_conf() {
    local tinc_dir="${TINC_DIR[$_name]}"
    local tinc_hosts="${TINC_DIR[$_name]}"/$_net/hosts
    echo "$_name $_sopts $tinc_dir $tinc_hosts"
    ssh $_sopts "sudo mkdir -p $tinc_dir"
    if ! ssh $_sopts "sudo test -e $tinc_dir/$_net/tinc.conf"; then
        echo "uploading configs for connection from $_name to $_peer"
        tar -cz -C $host_dir $_net | \
            ssh $_sopts \
                "sudo bash -c '
mkdir -p $tinc_dir;
tar -xz --no-same-owner -C $tinc_dir;
mkdir -p $tinc_hosts'"
        echo "upload complete"
    fi
    if ! ssh $_sopts "sudo test -e $tinc_dir/$_net/rsa_key.priv"; then
        echo "generating public key for connection from $_name to $_peer"
        cat $hosts/$_name | ssh $_sopts "sudo bash -c 'cat >$tinc_hosts/$_name'"
        if [ z"$_port" != z ]; then
            ssh $_sopts "sudo bash -c 'echo \"Port = $_port\" >>$tinc_hosts/$_name'"
        fi
        ssh -t $_sopts "sudo tincd -c $tinc_dir/$_net -K2048"
        pub_key=$(ssh $_sopts "sudo cat $tinc_hosts/$_name")
        echo "generate complete"
        sync_pub_key
    fi
}

sync_conf_to() {
    _name=$1
    _net=$2
    _peer=$3
    _pnet=$4
    _port=$5
    echo $_name $_net $_peer
    host_dir=$dir/$_name
    _sopts=${HOSTS[$_name]}
    _popts=${HOSTS[$_peer]}
    if [ z"$_popts" == z ] || [ z"$_sopts" == z ]; then
        :
    elif [ "$_sopts" == localhost ]; then
        copy_conf
    else
        upload_conf
    fi
}


while read -u 3 -r line; do
    echo ---------------------------------------------
    read -r h1 ip1 net1 h2 ip2 net2 <<<$line
    IFS=":" read -r peer1 port1 <<<$h1
    IFS=":" read -r peer2 port2 <<<$h2
    assert_host $hosts $peer1
    assert_host $hosts $peer2
    sync_conf_to $peer1 $net1 $peer2 $net2 $port1
    sync_conf_to $peer2 $net2 $peer1 $net1 $port2
done 3< <(grep -v '^\s*#' $peers_txt)
