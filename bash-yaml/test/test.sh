#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091

# Configure
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./../script/yaml.sh

# Debug
DEBUG="$1"

function is_debug() {
    [ "$DEBUG" = "--debug" ] && return 0 || return 1
}

if is_debug; then
    parse_yaml file.yml && echo
fi

# Execute
create_variables file.yml
echo "${date_cur}"
echo "${date_prv}"
echo "${res}"
echo "${num_mem}"
for i in 0 1 2
do
echo "${members__num[$i]}"
echo "${members__run[$i]}"
echo "${members__IC[$i]}"
echo "${members__LBC[$i]}"
echo "${members__GEP[$i]}"
done

# Functions
function test_list() {
    local list=$1

    if is_debug; then
        echo "All values from list: ${list[*]}";
    fi

    x=0
    for i in ${list[*]}; do
        if is_debug; then
            echo "Item: $i";
        fi

        [ "$i" = "$x" ] || return 1
        x="$((x+1))"
    done

    if is_debug; then echo; fi
}

