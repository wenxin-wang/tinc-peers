assert_host() {
    local dir=$1
    local name=$2
    if [ ! -f $dir/$name ]; then
        echo "$name not configured in $_dir"
        echo "Maybe you should call '$__DIR__/add-host.sh $dir $name'"
        exit 1
    fi
}
