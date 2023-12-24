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
if [ ! -d "$parent_path/$backup_folder" ]; then
  mkdir "$parent_path/$backup_folder"
fi

# Copy important files into backup folder
while read -r path; do
  file=$(basename "$path")
  cp -r "$path" "$parent_path/$backup_folder"
done < <(grep -v '^#' "$parent_path"/.env | grep 'path_' | sed 's/^.*=//')

# Individual commit message, if no parameter is set, use the current timestamp as commit message
if [ -n "$1" ]; then
    commit_message="$1"
else
    commit_message="New backup from $(date +"%d-%m-%y")"
fi

# Git commands
git init
git filter-branch --force --index-filter \
  'git rm -r --cached --ignore-unmatch "$parent_path"/.env' \
  --prune-empty --tag-name-filter cat -- --all
#git rm -rf --cached "$parent_path"/.env
git add "$parent_path"
git commit -m "$commit_message"
git push https://"$github_token"@github.com/"$github_username"/"$github_repository".git