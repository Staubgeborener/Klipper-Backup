#!/usr/bin/env bash

# Set parent directory path
parent_path=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)

# Initialize variables from .env file
source "$parent_path"/.env

backup_folder="config_backup"
backup_path="$HOME/$backup_folder"

# Check for updates
[ $(git -C "$parent_path" rev-parse HEAD) = $(git -C "$parent_path" ls-remote $(git -C "$parent_path" rev-parse --abbrev-ref @{u} | \
sed 's/\// /g') | cut -f1) ] && echo -e "Klipper-backup is up to date\n" || echo -e "NEW klipper-backup version available!\n"

# Check if backup folder exists, create one if it does not
if [ ! -d "$backup_path" ]; then
  mkdir -p "$backup_path"
fi

# cd to $HOME location, this keeps the script from adding /home/{username} to the folder structure when using --parents
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
done < <(grep -v '^#' "$parent_path/.env" | grep 'path_' | sed 's/^.*=//')

cp "$parent_path"/.gitignore "$backup_path/.gitignore"

# Create and add Readme to backup folder
echo -e "# klipper-backup 💾 \nKlipper backup script for manual or automated GitHub backups \n\nThis backup is provided by [klipper-backup](https://github.com/Staubgeborener/klipper-backup)." > "$backup_path/README.md"

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
  git config user.email "$(whoami)@$(hostname --long)-$(git rev-parse --short HEAD)"
  sed -i "s/^commit_email=.*/commit_email=\"$(whoami)@$(hostname --long)-$(git rev-parse --short HEAD)\"/" "$parent_path"/.env
fi

# Check if remote origin already exists and create if one does not
if [ -z "$(git remote get-url origin 2>/dev/null)" ]; then
    git remote add origin https://"$github_token"@github.com/"$github_username"/"$github_repository".git
fi

# Check if remote origin changed and update when it is
if [[ "$github_repository" != $(git remote get-url origin | sed 's/https:\/\/.*@github.com\///' | sed 's/\.git$//' | xargs basename) ]]; then
    git remote set-url origin https://"$github_token"@github.com/"$github_username"/"$github_repository".git
fi

git config advice.skippedCherryPicks false
git add .
git commit -m "$commit_message"

# Only attempt to pull or push when actual changes were commited. cleaner output then pulling and pushing when already up to date.
if [[ $(git rev-parse HEAD) != $(git ls-remote $(git rev-parse --abbrev-ref @{u} 2>/dev/null | sed 's/\// /g') | cut -f1) ]]; then
  #check if branch exists on remote (newly created repos will not yet have a remote)
  if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
    git pull origin "$branch_name" --rebase
  fi

  # Check if a rebase is in progress
  if [ -f .git/REBASE_HEAD ]; then
    # Rebase error occurred, list conflicted files and add them
    for file in $(git diff --name-only --diff-filter=U); do
      git add "$file"
    done

    # Continue with the rebase
    git rebase --continue
  fi

  git push -u origin "$branch_name"
fi

# Remove files except .git folder after backup so that any file deletions can be logged on next backup
find "$backup_path" -maxdepth 1 -mindepth 1 ! -name '.git' -exec rm -rf {} \;