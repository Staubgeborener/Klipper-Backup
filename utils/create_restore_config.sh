#!/usr/bin/env bash

#  Just some todo thoughts
#  Should the script act independent of .env and always prompt for the token and repo you want to restore from,
# leaning toward yes as it allows one to run restore without having to first run install.sh

# 
scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..
    pwd -P
)

source "$scriptsh_parent_path"/utils/utils.func
source "$scriptsh_parent_path"/.env
restore_config="$HOME"/printer_data/config/.restore.config

rm -f $restore_config

newbackupPaths="backupPaths=( \\ \n"
for path in "${backupPaths[@]}"; do
    newbackupPaths+=" \"$path\" \\ \n"
done
newbackupPaths+=")"

echo -e "${newbackupPaths[@]}" >>$restore_config

# look at ways to determine if files are dirty from changes made after installing theme, and look at how we might back those up, 
# maybe creating a stash and backing up the stash files only so then you fresh clone on a restore and then patch the stashed changes back in
if [ -d ""$HOME"/printer_data/config/.theme" ]; then
    if [ "$(git -C "$HOME"/printer_data/config/.theme remote get-url origin 2>/dev/null)" ]; then
        echo -e ".theme folder is a git repo"
        echo -e "Extracting remote url"
        remote_url=$(git -C "$HOME"/printer_data/config/.theme remote get-url origin)
        echo -e "theme_url=$remote_url" >>$restore_config
    else
        echo -e ".theme is not a git repo"
    fi
fi
