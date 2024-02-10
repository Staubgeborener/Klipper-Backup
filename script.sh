#!/usr/bin/env bash

# Set parent directory path
parent_path=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)

# Initialize variables from .env file
source "$parent_path"/.env

backup_folder="config_backup"
backup_path="$HOME/$backup_folder"
git_host=${git_host:-"github.com"}
full_git_url="https://"$github_token"@"$git_host"/"$github_username"/"$github_repository".git"

# Check for updates
[ $(git -C "$parent_path" rev-parse HEAD) = $(git -C "$parent_path" ls-remote $(git -C "$parent_path" rev-parse --abbrev-ref @{u} | \
sed 's/\// /g') | cut -f1) ] && echo -e "Klipper-backup is up to date\n" || echo -e "NEW klipper-backup version available!\n"

# Check if backup folder exists, create one if it does not
if [ ! -d "$backup_path" ]; then
    mkdir -p "$backup_path"
fi

# Git commands
cd "$backup_path"
# Check if .git exists else init git repo
if [ ! -d ".git" ]; then
    mkdir .git
    echo "[init]
    defaultBranch = "$branch_name"" >> .git/config #Add desired branch name to config before init
    git init
    # Check if the current checked out branch matches the branch name given in .env if not update to new branch
    elif [[ $(git symbolic-ref --short -q HEAD) != "$branch_name" ]]; then
    echo "New branch in .env detected, rename $(git symbolic-ref --short -q HEAD) to $branch_name branch"
    git branch -m "$branch_name"
fi

# Check if username is defined in .env
if [[ "$commit_username" != "" ]]; then
    git config user.name "$commit_username"
else
    git config user.name "$(whoami)"
    sed -i "s/^commit_username=.*/commit_username=\"$(whoami)\"/" "$parent_path"/.env
fi

# Check if email is defined in .env
if [[ "$commit_email" != "" ]]; then
    git config user.email "$commit_email"
else
    # Get the MAC address of the first network interface for unique id
    mac_address=$(ipconfig | grep -o -E '([0-9a-fA-F]:?){6}' | head -n 1)
    # Use the MAC address to generate a unique identifier
    unique_id=$(echo "$mac_address" | sha256sum | cut -c 1-8)
    git config user.email "$(whoami)@$(hostname --long)-$unique_id"
    sed -i "s/^commit_email=.*/commit_email=\"$(whoami)@$(hostname --long)-$unique_id\"/" "$parent_path"/.env
fi

# Check if remote origin already exists and create if one does not
if [ -z "$(git remote get-url origin 2>/dev/null)" ]; then
    git remote add origin "$full_git_url"
fi

# Check if remote origin changed and update when it is
if [[ "$full_git_url" != $(git remote get-url origin) ]]; then
    git remote set-url origin "$full_git_url"
fi

git config advice.skippedCherryPicks false

# Check if branch exists on remote (newly created repos will not yet have a remote) and pull any new changes
if git ls-remote --exit-code --heads origin $branch_name > /dev/null 2>&1; then
    git pull origin "$branch_name"
    # Delete the pulled files so that the directory is empty again before copying the new backup
    # The pull is only needed so that the repository nows its on latest and does not require rebases or merges
    find "$backup_path" -maxdepth 1 -mindepth 1 ! -name '.git' -exec rm -rf {} \;
fi

cd "$HOME"
while IFS= read -r path; do
    # Check if path is a directory or not a file (needed for /* checking as /* treats the path as not a directory)
    if [[ -d "$HOME/$path" || ! -f "$HOME/$path" ]]; then
        # Check if path does not end in /* or /
        if [[ ! "$path" =~ /\*$ && ! "$path" =~ /$ ]]; then
            path="$path/*"
            elif [[ ! "$path" =~ \$ && ! "$path" =~ /\*$ ]]; then
            path="$path*"
        fi
    fi
    # Check if path contains files
    if compgen -G "$HOME/$path" > /dev/null; then
        # Iterate over every file in the path
        for file in $path; do
            # Check if it's a symbolic link
            if [ -h "$file" ]; then
                echo "Skipping symbolic link: $file"
                # Check if file is an extra backup of printer.cfg moonraker/klipper seems to like to make 4-5 of these sometimes no need to back them all up as well.
                elif [[ $(basename "$file") =~ ^printer-[0-9]+_[0-9]+\.cfg$ ]]; then
                echo "Skipping file: $file"
            else
                cp -r --parents "$file" "$backup_path/"
            fi
        done
    fi
done < <(grep -v '^#' "$parent_path/.env" | grep 'path_' | sed 's/^.*=//')

cp "$parent_path"/.gitignore "$backup_path/.gitignore"

# Create and add Readme to backup folder
echo -e "# klipper-backup 💾 \nKlipper backup script for manual or automated GitHub backups \n\nThis backup is provided by [klipper-backup](https://github.com/Staubgeborener/klipper-backup)." > "$backup_path/README.md"

# Individual commit message, if no parameter is set, use the current timestamp as commit message
timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ -n "$1" ]; then
    commit_message="$@"
    elif [[ "$timezone" == *"America"* ]]; then
    commit_message="New backup from $(date +"%m-%d-%y")"
else
    commit_message="New backup from $(date +"%d-%m-%y")"
fi

cd "$backup_path"
git add .
git commit -m "$commit_message"
# Check if HEAD still matches remote (Means there are no updates to push) and create a empty commit just informing that there are no new updates to push
if [[ $(git rev-parse HEAD) == $(git ls-remote $(git rev-parse --abbrev-ref @{u} 2>/dev/null | sed 's/\// /g') | cut -f1) ]]; then
    git commit --allow-empty -m "$commit_message - No new changes pushed"
fi
git push -u origin "$branch_name"

# Remove files except .git folder after backup so that any file deletions can be logged on next backup
find "$backup_path" -maxdepth 1 -mindepth 1 ! -name '.git' -exec rm -rf {} \;