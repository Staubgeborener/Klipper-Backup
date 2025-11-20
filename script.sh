#!/usr/bin/env bash

# set dotglob so that bash treats hidden files/folders starting with . correctly when copying them (ex. .themes from mainsail)
shopt -s dotglob

# Set parent directory path
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)

# Initialize variables from .env file
source "$parent_path"/.env
source "$parent_path"/utils/utils.func

loading_wheel "${Y}●${NC} Checking for installed dependencies" &
loading_pid=$!
check_dependencies "jq" "curl" "rsync"
kill $loading_pid
echo -e "\r\033[K${G}●${NC} Checking for installed dependencies ${G}Done!${NC}\n"

# Do not touch these variables, the .env file and the documentation exist for this purpose
backup_folder="config_backup"
backup_path="$HOME/$backup_folder"
allow_empty_commits=${allow_empty_commits:-true}
use_filenames_as_commit_msg=${use_filenames_as_commit_msg:-false}
git_protocol=${git_protocol:-"https"}
git_host=${git_host:-"github.com"}
ssh_user=${ssh_user:-"git"}

if [[ $git_protocol == "ssh" ]]; then
    full_git_url=$git_protocol"://"$ssh_user"@"$git_host"/"$github_username"/"$github_repository".git"
else
    full_git_url=$git_protocol"://"$github_token"@"$git_host"/"$github_username"/"$github_repository".git"
fi
exclude=${exclude:-"*.swp" "*.tmp" "printer-[0-9]*_[0-9]*.cfg" "*.bak" "*.bkp" "*.csv" "*.zip"}

# Required for checking the use of the commit_message and debug parameter
commit_message_used=${commit_message_used:-false}
debug_output=${debug_output:-false}
# Collect args before they are consumed by getopts
args="$@"

# Check parameters
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -f|--fix)
      fix
      shift
      ;;
    -c|--commit_message)
      if  [[ -z "$2" || "$2" =~ ^- ]]; then
          echo -e "\r\033[K${R}Error: commit message expected after $1${NC}" >&2
          exit 1
      else
          commit_message="$2"
          commit_message_used=true
          shift 2
      fi
      ;;
    -d|--debug)
      debug_output=true
      shift
      ;;
    *)
      echo -e "\r\033[K${R}Unknown option: $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

# Check for updates
[ $(git -C "$parent_path" rev-parse HEAD) = $(git -C "$parent_path" ls-remote $(git -C "$parent_path" rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ] && echo -e "Klipper-Backup is up to date\n" || echo -e "${Y}●${NC} Update for Klipper-Backup ${Y}Available!${NC}\n"

# Check if .env is v1 version
if [[ ! -v backupPaths ]]; then
    echo ".env file is not using version 2 config, upgrading to V2"
    if bash $parent_path/utils/v1convert.sh; then
        echo "Upgrade complete restarting script.sh"
        sleep 2.5
        exec "$parent_path/script.sh" "$args"
    fi
fi

if [ "$debug_output" = true ]; then
    # Debug output: Show last command
    begin_debug_line
    if [[ "$SHELL" == */bash* ]]; then
        echo -e "Command: $0 $args"
    fi
    end_debug_line

    # Debug output: .env file with hidden token
    begin_debug_line
    shopt -s nocaseglob
    while IFS= read -r line; do
        if [[ $line == github_token=* ]]; then
            echo "github_token=**********"
        elif [[ $line == commit_email=* ]]; then
            echo "commit_email==**********"
        else
            echo "$line"
        fi
    done < $HOME/klipper-backup/.env
    shopt -u nocasematch
    end_debug_line

    # Debug output: Check git repo
    if [[ $git_host == "github.com" ]]; then
        begin_debug_line
        if curl -fsS "https://api.github.com/repos/${github_username}/${github_repository}" >/dev/null; then
            echo "The GitHub repo ${github_username}/${github_repository} exists (public)"
        else
            echo "Error: no GitHub repo ${github_username}/${github_repository} found (maybe private)"
        fi
        end_debug_line
    fi
fi

# Check if backup folder exists, create one if it does not
if [ ! -d "$backup_path" ]; then
    mkdir -p "$backup_path"
fi

cd "$backup_path"

# Debug output: $HOME
[ "$debug_output" = true ] && begin_debug_line && echo -e "\$HOME: $HOME" && end_debug_line

# Debug output: $backup_path - (current) path and content
[ "$debug_output" = true ] && begin_debug_line && echo -e "\$backup_path: $PWD" && echo -e "\nContent of \$backup_path:" && echo -ne "$(ls -la $backup_path)\n" && end_debug_line

# Debug output: $backup_path/.git/config content
if [ "$debug_output" = true ]; then
    begin_debug_line
    echo -e "\$backup_path/.git/config:\n"
    while IFS= read -r line; do
        if [[ $line == *"url ="*@* ]]; then
            masked_line=$(echo "$line" | sed -E 's/(url = https:\/\/)[^@]*(@.*)/\1********\2/')
            echo "$masked_line"
        else
            echo "$line"
        fi
    done < "$backup_path/.git/config"
    end_debug_line
fi

# Check if .git exists else init git repo
if [ ! -d ".git" ]; then
    mkdir .git
    echo "[init]
    defaultBranch = "$branch_name"" >>.git/config #Add desired branch name to config before init
    git init
# Check if the current checked out branch matches the branch name given in .env if not branch listed in .env
elif [[ $(git symbolic-ref --short -q HEAD) != "$branch_name" ]]; then
    echo -e "Branch: $branch_name in .env does not match the currently checked out branch of: $(git symbolic-ref --short -q HEAD)."
    # Create branch if it does not exist
    if git show-ref --quiet --verify "refs/heads/$branch_name"; then
        git checkout "$branch_name" >/dev/null
    else
        git checkout -b "$branch_name" >/dev/null
    fi
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
    unique_id=$(date +%s%N | md5sum | head -c 7)
    user_email=$(whoami)@$(hostname --short)-$unique_id
    git config user.email "$user_email"
    sed -i "s/^commit_email=.*/commit_email=\"$user_email\"/" "$parent_path"/.env
fi

# Check if remote origin already exists and create if one does not
if [ -z "$(git remote get-url origin 2>/dev/null)" ]; then
    git remote add origin "$full_git_url"
fi

# Check if remote origin changed and update when it is
if [[ "$full_git_url" != $(git remote get-url origin) ]]; then
    git remote set-url origin "$full_git_url"
fi

# Check if branch exists on remote (newly created repos will not yet have a remote) and pull any new changes
if git ls-remote --exit-code --heads origin $branch_name >/dev/null 2>&1; then
    git pull origin "$branch_name"
    # Delete the pulled files so that the directory is empty again before copying the new backup
    # The pull is only needed so that the repository nows its on latest and does not require rebases or merges
    find "$backup_path" -maxdepth 1 -mindepth 1 ! -name '.git' ! -name 'README.md' ! -name '.gitmodules' -exec rm -rf {} \;
fi

cd "$HOME"
# Iterate through backupPaths array and copy files to the backup folder while ignoring symbolic links
for path in "${backupPaths[@]}"; do
    fullPath="$HOME/$path"
    if [[ -d "$fullPath" && ! -f "$fullPath" ]]; then
        # Check if the directory path ends with only a '/'
        if [[ "$path" =~ /$ ]]; then
            # If it ends with '/', replace it with '/*'
            backupPaths[$i]="$path*"
        elif [[ -d "$path" ]]; then
            # If it's a directory without '/', add '/*' at the end
            backupPaths[$i]="$path/*"
        fi
    fi

    if compgen -G "$fullPath" >/dev/null; then
        # Iterate over every file in the path
        for file in $path; do
            # Skip if file is symbolic link
            if [ -h "$file" ]; then
                echo "Skipping symbolic link: $file"
            else
                file=$(readlink -e "$file") # Get absolute path before copy (Allows usage of .. in filepath eg. ../../etc/fstab resovles to /etc/fstab )
                rsync -Rr  --filter "- /.git/" --filter "- /.github/" "${file##"$HOME"/}" "$backup_path"
            fi
        done
    fi
done

# Debug output: $backup_path content after running rsync
[ "$debug_output" = true ] && begin_debug_line && echo -e "Content of \$backup_path after rsync:" && echo -ne "$(ls -la $backup_path)\n" && end_debug_line

cp "$parent_path"/.gitignore "$backup_path/.gitignore"

# utilize gits native exclusion file .gitignore to add files that should not be uploaded to remote.
# Loop through exclude array and add each element to the end of .gitignore
for i in ${exclude[@]}; do
    # add new line to end of .gitignore if there is not one
    [[ $(tail -c1 "$backup_path/.gitignore" | wc -l) -eq 0 ]] && echo "" >>"$backup_path/.gitignore"
    echo $i >>"$backup_path/.gitignore"
done

# Individual commit message, if no parameter is set, use the current timestamp as commit message
if ! $commit_message_used; then
    commit_message="New backup from $(date +"%x - %X")"
fi

cd "$backup_path"
# Create and add Readme to backup folder if it doesn't already exist
if ! [ -f "README.md" ]; then
    echo -e "# Klipper-Backup 💾 \nKlipper backup script for manual or automated GitHub backups \n\nThis backup is provided by [Klipper-Backup](https://github.com/Staubgeborener/Klipper-Backup)." >"$backup_path/README.md"
fi

# Show in commit message which files have been changed
if $use_filenames_as_commit_msg; then
    commit_message=$(git diff --name-only "$branch_name" | xargs -n 1 basename | tr '\n' ' ')
fi

# Untrack all files so that any new excluded files are correctly ignored and deleted from remote
git rm -r --cached . >/dev/null 2>&1
git add .
git commit -m "$commit_message"
# Check if HEAD still matches remote (Means there are no updates to push) and create a empty commit just informing that there are no new updates to push
if $allow_empty_commits && [[ $(git rev-parse HEAD) == $(git ls-remote $(git rev-parse --abbrev-ref @{u} 2>/dev/null | sed 's/\// /g') | cut -f1) ]]; then
    git commit --allow-empty -m "$commit_message - No new changes pushed"
fi
git push -u origin "$branch_name"

# Remove files except .git folder after backup so that any file deletions can be logged on next backup
find "$backup_path" -maxdepth 1 -mindepth 1 ! -name '.git' ! -name 'README.md' ! -name '.gitmodules' -exec rm -rf {} \;
