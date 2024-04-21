#!/usr/bin/env bash

parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)

source "$parent_path"/utils/utils.func
source "$parent_path"/.env

echo "${backupPaths[@]}" > restore.config
