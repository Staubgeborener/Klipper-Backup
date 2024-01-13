#!/usr/bin/env bash

# Check for updates
[ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
sed 's/\// /g') | cut -f1) ] && echo -e "Klipper-backup is up to date\n" || echo -e "Klipper-backup is $(tput setaf 1)not$(tput sgr0) up to date, consider making a $(tput setaf 1)git pull$(tput sgr0) to update\n"

# Set parent directory path
parent_path=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)

# Initialize variables from .env file
source "$parent_path"/.env

# Check that backup_folder is not set to root of users home directory
backup_folderDepth=$(echo "$backup_folder" | tr '/' '\n' | grep -c .)
if [[ $backup_folder == '.' ]]; then
echo "Your \$backup_folder path cannot be the root of: $HOME"
echo "Please change the path location in .env!"
exit 1
fi

# Change directory to parent path
cd "$parent_path" || exit

backup_path="$HOME/$backup_folder"

# Check if backup folder exists, create one if it does not
if [ ! -d $backup_path ]; then
  mkdir -p $backup_path
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
      cp -r $file $backup_path/
    fi
  done
done < <(grep -v '^#' "$parent_path/.env" | grep 'path_' | sed 's/^.*=//')

# Check if backup_folder path depth is greater than 1, this is needed to ensure that if path is only 1 level deep we do not create the git repo in /home/{username}/
# we DO NOT want to use backup_path here as we want to exclude /home/{username}/ from the awk search
if [[ $backup_folderDepth -gt 1 ]]; then
backup_parent_directory=$(echo "$backup_folder" | awk -F'/' '{print $1}') # first level of backup path
else
backup_parent_directory=$backup_folder
fi

cp "$parent_path"/.gitignore "$HOME/$backup_parent_directory/.gitignore"

# Create and add Readme to backup folder
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
git push -f -u https://"$github_token"@github.com/"$github_username"/"$github_repository".git $branch

# Remove backup folder after backup so that any file deletions can be logged on next backup
if [[ $backup_folderDepth -gt 1 ]]; then
  rm -rf $backup_path
  find $HOME/$backup_parent_directory -type d -empty -delete
elif [ -d $backup_path ]; then
    find $backup_path -maxdepth 1 -mindepth 1 ! -name '.git' -exec rm -rf {} \;
fi