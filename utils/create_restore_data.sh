#!/usr/bin/env bash

## WANT TO CHANGE:
# Instead of individually grabbing values from .env use sed to clear token, username, repository and branch and then copy the entire contents to restore folder.
# Then on restore you fill back in those 4 fields while restoring the backup and copy that back over to klipper-backup folder as .env
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

# newbackupPaths="backupPaths=( \\ \n"
# for path in "${backupPaths[@]}"; do
#     trimmedPath=$(echo "$path" | sed 's/^[ \t]*//;s/[ \t]*$//')
#     if [[ -n "$trimmedPath" ]]; then
#         newbackupPaths+=" \"$trimmedPath\" \\"$'\n'
#     fi
# done
# newbackupPaths+=")"

# echo -e "${newbackupPaths[@]}" >>$restore_config

# echo -e "commit_username=${commit_username}" >>$restore_config
# echo -e "commit_email=${commit_email}" >>$restore_config

if [ -d "$theme_path" ]; then
    cd $theme_path
    if [ "$(git remote get-url origin 2>/dev/null)" ]; then
        echo -e ".theme folder is a git repo"
        echo -e "Extracting remote url"
        remote_url=$(git remote get-url origin)
        echo -e "theme_url=$remote_url" >>$restore_config
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
