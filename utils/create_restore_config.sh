#!/usr/bin/env bash

#  Just some todo thoughts
#  The script should act independent of .env and always prompt for the token and repo you want to restore from,
#  this allows one to run restore without having to first run install.
#

scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..
    pwd -P
)

source "$scriptsh_parent_path"/utils/utils.func
source "$scriptsh_parent_path"/.env
restore_folder="$HOME"/printer_data/config/klipper-backup-restore
restore_config="$restore_folder"/restore.config
theme_path="$HOME"/printer_data/config/.theme

if [[ ! -d $restore_folder ]]; then
    mkdir $restore_folder
fi

rm -f $restore_config

newbackupPaths="backupPaths=( \\ \n"
for path in "${backupPaths[@]}"; do
    newbackupPaths+=" \"$path\" \\ \n"
done
newbackupPaths+=")"

echo -e "${newbackupPaths[@]}" >>$restore_config


if [ -d "$theme_path" ]; then
    cd $theme_path
    if [ "$(git remote get-url origin 2>/dev/null)" ]; then
        echo -e ".theme folder is a git repo"
        echo -e "Extracting remote url"
        remote_url=$(git remote get-url origin)
        echo -e "theme_url=$remote_url" >>$restore_config
        if [[ $(git status --porcelain | grep '^??') ]]; then
            echo ".theme folder has untracked changes. Backing up changes to .patch file"
            git add .
            git stash save ".theme changes"
            git stash show -p >$restore_folder/theme_changes.patch
        fi
    else
        echo -e ".theme is not a git repo"
    fi
fi


#Note:
  # use this when creating the restore script to add .theme changes back:
  # git apply $HOME/printer_data/config/klipper-backup-restore/theme_changes.patch

  #Steps will likely be git clone the fresh theme using git url in restore.config, apply patch, voila!