#!/usr/bin/env bash

# === Initialization === #
init() {
    # set dotglob so that bash treats hidden files/folders starting with . correctly when copying them
    shopt -s dotglob

    # Set parent directory path
    parent_path=$(
        cd "$(dirname "${BASH_SOURCE[0]}")"
        pwd -P
    )

    source "$parent_path"/.env
    source "$parent_path"/utils/utils.func

    backup_folder="$branch_name-backup"
    backup_path="$HOME/$backup_folder"
    allow_empty_commits=${allow_empty_commits:-false}
    git_protocol=${git_protocol:-"https"}
    git_host=${git_host:-"github.com"}
    ssh_user=${ssh_user:-"git"}

    if [[ $git_protocol == "ssh" ]]; then
        full_git_url=$git_protocol"://"$ssh_user"@"$git_host"/"$github_username"/"$github_repository".git"
    else
        full_git_url=$git_protocol"://"$github_token"@"$git_host"/"$github_username"/"$github_repository".git"
    fi
    exclude=${exclude:-"*.swp" "*.tmp" "*.bak" "*.bkp" "*.csv" "*.zip"}
    commit_message_used=false
    debug_output=false
    args="$@"

    # Check parameters
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -f | --fix)
            fix
            shift
            ;;
        -c | --commit_message)
            if [[ -z "$2" || "$2" =~ ^- ]]; then
                echo -e "${CL}${R}Error: commit message expected after $1${NC}" >&2
                exit 1
            else
                commit_message="$2"
                commit_message_used=true
                shift 2
            fi
            ;;
        -d | --debug)
            debug_output=true
            shift
            ;;
        *)
            echo -e "${CL}${R}Unknown option: $1${NC}"
            exit 1
            ;;
        esac
    done

    [[ "$debug_output" == true ]] && source "$parent_path"/utils/debug.func
}

# === Functions === #
checkUpdates() {
    [ $(git -C "$parent_path" rev-parse HEAD) = $(git -C "$parent_path" ls-remote $(git -C "$parent_path" rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ] && echo -e "Up to date\n" || echo -e "${Y}●${NC} Update ${Y}Available!${NC}\n"
}

createBackupFolder() {
    if [ ! -d "$backup_path" ]; then
        mkdir -p "$backup_path"
    fi

    gotoBackupFolder

    if [ ! -d ".git" ]; then
        mkdir .git
        echo "[init]
    defaultBranch = "$branch_name"" >>.git/config #Add desired branch name to config before init
        git init
        git config pull.rebase false # configure default reconciliation when pulling
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
        find "$backup_path" -maxdepth 1 -mindepth 1 ! -name '.git' ! -name '.gitmodules' ! -name 'README.md' -exec rm -rf {} \;
    fi
}

checkEnv() {
    # # Check if .env is v1 version
    if [[ ! -v backupPaths ]]; then
        echo ".env file is not using version 2 config, upgrading to V2"
        if bash $parent_path/utils/v1convert.sh; then
            echo "Upgrade complete restarting script.sh"
            sleep 2.5
            exec "$parent_path/script.sh" "$args"
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
}

copyFiles() {
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
                elif [ -n "$(find $file -regex '.*/\.git*')" ]; then
                    echo ".git folder: $file detected, don't add back to backup"
                else
                    file=$(readlink -e "$file") # Get absolute path before copy (Allows usage of .. in filepath eg. ../../etc/fstab resovles to /etc/fstab )
                    echo "Backing up: $file"
                    rsync -Rr "${file##"$HOME"/}" "$backup_path"
                fi
            done
        fi
    done

    # # Debug output: $backup_path content after running rsync
    # if [ "$debug_output" = true ]; then
    #     debug_backuppathafter
    # fi

    cp "$parent_path"/.gitignore "$backup_path/.gitignore"

    # utilize gits native exclusion file .gitignore to add files that should not be uploaded to remote.
    # Loop through exclude array and add each element to the end of .gitignore
    for i in ${exclude[@]}; do
        # add new line to end of .gitignore if there is not one
        [[ $(tail -c1 "$backup_path/.gitignore" | wc -l) -eq 0 ]] && echo "" >>"$backup_path/.gitignore"
        echo $i >>"$backup_path/.gitignore"
    done
}

pre-commitCleanup() {
    git rm -r --cached . >/dev/null 2>&1
}

pushCommit() {
    # Individual commit message, if no parameter is set, use the current timestamp as commit message
    if ! $commit_message_used; then
        commit_message="New backup from $(date +"%x - %X")"
    fi
    git add .
    git commit -m "$commit_message"
    # Check if HEAD still matches remote (Means there are no updates to push) and create a empty commit just informing that there are no new updates to push
    if $allow_empty_commits && [[ $(git rev-parse HEAD) == $(git ls-remote $(git rev-parse --abbrev-ref @{u} 2>/dev/null | sed 's/\// /g') | cut -f1) ]]; then
        git commit --allow-empty -m "$commit_message - No new changes pushed"
    fi
    git push -u origin "$branch_name"
}

cleanUp() {
    find "$backup_path" -maxdepth 1 -mindepth 1 ! -name '.git' ! -name '.gitmodules' ! -name 'README.md' -exec rm -rf {} \;
}

# === Main === #
init "$@"
commonDeps
checkUpdates
createBackupFolder
checkEnv
gotoHome
copyFiles
gotoBackupFolder
pre-commitCleanup
pushCommit
cleanUp
