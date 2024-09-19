#!/usr/bin/env bash

scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..
    pwd -P
)

source "$scriptsh_parent_path"/utils/utils.func
source "$scriptsh_parent_path"/.env
restore_folder="$HOME"/klipper-backup-restore
restore_config="$restore_folder"/restore.config
theme_path="$HOME"/printer_data/config/.theme

if [[ ! -d $restore_folder ]]; then
    mkdir $restore_folder
fi

rm -f $restore_config

cp "$scriptsh_parent_path"/.env "$restore_config"

sed -i "s/^github_token=.*/github_token=/" $restore_config
sed -i "s/^github_username=.*/github_username=/" $restore_config
sed -i "s/^github_repository=.*/github_repository=/" $restore_config
sed -i "s/^branch_name=.*/branch_name=/" $restore_config

if [ -d "$theme_path" ]; then
    cd $theme_path
    if [ "$(git remote get-url origin 2>/dev/null)" ]; then
        echo -e ".theme folder is a git repo"
        echo -e "Extracting remote url"
        remote_url=$(git remote get-url origin)
        echo -e "\ntheme_url=$remote_url" >>$restore_config
        if [[ $(git status --porcelain | grep '^??') || $(git status --porcelain | grep '^A') ]]; then
            echo ".theme folder has untracked/added changes. Backing up changes to .patch file"
            git add .
            git stash save ".theme changes"
            git stash show -p >$restore_folder/theme_changes.patch
        fi
    else
        echo -e ".theme is not a git repo"
    fi
fi
