#!/usr/bin/env bash

# Set parent directory path
parent_path=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)

# Initialize variables from .env file
github_token=$(grep 'github_token=' "$parent_path"/.env | sed 's/^.*=//')
github_username=$(grep 'github_username=' "$parent_path"/.env | sed 's/^.*=//')
github_repository=$(grep 'github_repository=' "$parent_path"/.env | sed 's/^.*=//')
backup_folder=$(grep 'backup_folder=' "$parent_path"/.env | sed 's/^.*=//')

# Change directory to parent path
cd "$parent_path" || exit

# Check if backup folder exists, create one if it does not
if [ ! -d "$HOME/$backup_folder" ]; then
  mkdir -p "$HOME/$backup_folder"
fi

while IFS= read -r path; do
  # Iterate over every file in the path
  for file in $HOME/$path; do
    # Check if it's a symbolic link
    if [ -h "$file" ]; then
      echo "Skipping symbolic link: $file"
      # Check if file is an extra backup of printer.cfg moonraker/klipper seems to like to make 4-5 of these sometimes no need to back them all up as well.
    elif [[ $(basename "$file") =~ ^printer-[0-9]+_[0-9]+\.cfg$ ]]; then
        echo "Skipping file: $file"
    else
      cp $file $HOME/$backup_folder/
    fi
  done
done < <(grep -v '^#' "$parent_path/.env" | grep 'path_' | sed 's/^.*=//')

# Add basic readme to backup repo
backup_parent_directory=$(dirname "$backup_folder")
echo -e "# klipper-backup 💾 \nKlipper backup script for manual or automated GitHub backups \n\nThis backup is provided by [klipper-backup](https://github.com/tylerjet/klipper-backup)." > "$HOME/$backup_parent_directory/README.md"

# Individual commit message, if no parameter is set, use the current timestamp as commit message
timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ -n "$1" ]; then
    commit_message="$1"
elif [[ "$timezone" == *"America"* ]]; then
    commit_message="New backup from $(date +"%m-%d-%y")"
else
    commit_message="New backup from $(date +"%d-%m-%y")"
fi

# Git commands
cd "$HOME/$backup_parent_directory"
git config init.defaultBranch main #supress git warning about branch name changes coming soon
git init
git add .
git commit -m "$commit_message"
git push -u https://"$github_token"@github.com/"$github_username"/"$github_repository".git main
# Remove klipper folder after backup so that any file deletions can be logged on next backup
rm -rf $HOME/$backup_folder/
