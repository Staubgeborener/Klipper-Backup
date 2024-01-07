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

# Copy important files into backup folder
while IFS= read -r path; do
  # Use eval to expand wildcards
  eval "cp $HOME/$path/* $HOME/$backup_folder/"
done < <(grep -v '^#' "$parent_path/.env" | grep 'path_' | sed 's/^.*=//')

# Copy Readme.md from backup repo
backup_parent_directory=$(dirname "$backup_folder")
echo -e "# klipper-backup 💾 \nKlipper backup script for manual or automated GitHub backups \n\nThis backup is provided by [klipper-backup](https://github.com/Staubgeborener/klipper-backup)." > "$HOME/$backup_parent_directory/README.md"

# Individual commit message, if no parameter is set, use the current timestamp as commit message
if [ -n "$1" ]; then
    commit_message="$1"
else
    commit_message="New backup from $(date +"%d-%m-%y")"
fi

# Git commands
cd "$HOME/$backup_parent_directory"
git init
git add .
git commit -m "$commit_message"
git branch -M main
git push --set-upstream https://"$github_token"@github.com/"$github_username"/"$github_repository".git main
