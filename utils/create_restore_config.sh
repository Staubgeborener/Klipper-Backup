#!/usr/bin/env bash

scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..
    pwd -P
)

source "$scriptsh_parent_path"/utils/utils.func
source "$scriptsh_parent_path"/.env

newbackupPaths="backupPaths=( \\ \n"
for path in "${backupPaths[@]}"; do
    newbackupPaths+=" \"$path\" \\ \n"
done
newbackupPaths+=")"

echo -e "${newbackupPaths[@]}" >"$HOME"/printer_data/config/.restore.config

if [ -d '"$HOME"/printer_data/config/.theme"' ]; then
    if [ "$(git remote get-url origin)" ]; then
        echo ".theme folder is a git repo"
    else
        echo ".theme is not a git repo"
    fi
fi
