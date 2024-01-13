#!/usr/bin/env bash

# Check for updates
[ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
sed 's/\// /g') | cut -f1) ] && echo -e "Klipper-backup is up to date\n" || echo -e "Klipper-backup is $(tput setaf 1)not$(tput sgr0) up to date, consider making a $(tput setaf 1)git pull$(tput sgr0) to update\n"

# Set parent directory path
parent_path=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)

# Initialize variables from .env file
source "$parent_path"/.env

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
cp "$parent_path"/.gitignore "$HOME/$backup_parent_directory/.gitignore"
echo -e "# klipper-backup 💾 \nKlipper backup script for manual or automated GitHub backups \n\nThis backup is provided by [klipper-backup](https://github.com/Staubgeborener/klipper-backup)." > "$HOME/$backup_parent_directory/README.md"

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
# Check if .git exists else init git repo
if [ ! -d ".git" ]; then
  mkdir .git 
  echo "[init]
          defaultBranch = $branch_name" >> .git/config #Add desired branch name to config before init
  git init
  branch=$(git symbolic-ref --short -q HEAD)
else
  branch=$(git symbolic-ref --short -q HEAD)
fi

[[ "$commit_username" != "" ]] && git config user.name "$commit_username" || git config user.name "$(whoami)"
[[ "$commit_email" != "" ]] && git config user.email "$commit_email" || git config user.email "$(whoami)@$(hostname --long)"
git add .
git commit -m "$commit_message"
git push -u https://"$github_token"@github.com/"$github_username"/"$github_repository".git $branch
# Remove klipper folder after backup so that any file deletions can be logged on next backup
rm -rf $HOME/$backup_folder/