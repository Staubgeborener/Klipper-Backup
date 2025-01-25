# Planning out script process:
# Prompt for repository name, token, branch - Done!
# Prompt if user would like to restore from specific commit, if yes, prompt for commit hash
# pull contents of branch to a temp folder, extract paths from restore.config - Done!
# shut down instances of klipper, moonraker etc.. - Done!
# copy files from temp folder to the respective paths, along with repatching .theme git repo (if applicable) - Done!
# cleanup including using sed to remove theme_url from the generated .env - Done!

##########################################################################################

#!/usr/bin/env bash

trap 'stty echo; exit' SIGINT

scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..
    pwd -P
)

source "$scriptsh_parent_path"/utils/utils.func
envpath="$scriptsh_parent_path"/.env
tempfolder="/tmp/klipper-backup-restore-tmp"
temprestore="$tempfolder/klipper-backup-restore/restore.config"
restore_folder="$HOME"/klipper-backup-restore
restore_config="$restore_folder"/restore.config

main() {
    clear
    sudo -v
    dependencies
    logo
    configure
    tempfolder
    copyRestoreConfig
    source $temprestore
    sudo systemctl stop klipper.service
    restoreBackupFiles
    restoreMoonrakerDB
    copyTheme
    cleanup
}

logo() {
    clear
    echo -e "${C}$(
        cat <<"EOF"
    __ __ ___                             ____             __                     ____            __                
   / //_// (_)___  ____  ___  _____      / __ )____ ______/ /____  ______        / __ \___  _____/ /_____  ________ 
  / ,<  / / / __ \/ __ \/ _ \/ ___/_____/ __  / __ `/ ___/ //_/ / / / __ \______/ /_/ / _ \/ ___/ __/ __ \/ ___/ _ \
 / /| |/ / / /_/ / /_/ /  __/ /  /_____/ /_/ / /_/ / /__/ ,< / /_/ / /_/ /_____/ _, _/  __(__  ) /_/ /_/ / /  /  __/
/_/ |_/_/_/ .___/ .___/\___/_/        /_____/\__,_/\___/_/|_|\__,_/ .___/     /_/ |_|\___/____/\__/\____/_/   \___/ 
         /_/   /_/                                               /_/                                                
EOF
    )${NC}"
    echo ""
    echo "==============================================================================================================="
    echo ""
}

dependencies() {
    loading_wheel "${Y}●${NC} Checking for installed dependencies" &
    loading_pid=$!
    check_dependencies "jq" "curl" "rsync"
    kill $loading_pid
    echo -e "\r\033[K${G}●${NC} Checking for installed dependencies ${G}Done!${NC}\n"
    sleep 1
}

configure() {
    ghtoken_username=""
    questionline=$(getcursor)

    tput cup $(($questionline - 1)) 0
    clearUp
    pos1=$(getcursor)
    pos2=$(getcursor)

    getToken() {
        ghtoken=$(ask_token "Enter your GitHub token associated with the backup you want to restore")
        result=$(check_ghToken "$ghtoken") # Check Github Token using github API to ensure token is valid and connection can be estabilished to github
        if [ "$result" != "" ]; then
            ghtoken_username=$result
        else
            tput cup $(($pos2 - 2)) 0
            tput ed
            pos2=$(getcursor)
            echo "Invalid Github token or Unable to contact github API, Please re-enter your token and check for valid connection to github.com then try again!"
            getToken
        fi
    }
    getUser() {
        pos2=$(getcursor)
        ghuser=$(ask_textinput "Enter your github username" "$ghtoken_username")

        menu $pos2
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            tput cup $pos2 0
            tput ed
        else
            tput cup $(($pos2 - 1)) 0
            tput ed
            getUser
        fi
    }
    getRepo() {
        pos2=$(getcursor)
        ghrepo=$(ask_textinput "Enter your repository name")

        menu $pos2
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            tput cup $pos2 0
            tput ed
        else
            tput cup $(($pos2 - 1)) 0
            tput ed
            getRepo
        fi
    }
    getBranch() {
        pos2=$(getcursor)
        repobranch=$(ask_textinput "Enter your desired branch name" "main")

        menu $pos2
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            tput cup $pos2 0
            tput ed
        else
            tput cup $(($pos2 - 1)) 0
            tput ed
            getBranch
        fi
    }

    getCommit() {
        pos1=$(getcursor)
        if ask_yn "Would you like to restore from a specific commit?" "no"; then
            commit_hash=$(ask_textinput "Enter the commit hash you would like to restore from")

            menu $pos1
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                tput cup $pos1 0
                tput ed
                validate_commit $commit_hash $pos1
            else
                tput cup $(($pos1 - 1)) 0
                tput ed
                getCommit
            fi

        fi
    }

    while true; do
        set +e
        getToken
        getUser
        getRepo
        getBranch
        getCommit
        set -e
        break
    done
}

validate_commit() {
    local pos=$2
    local commit_hash=$1
    git fetch origin $repobranch
    if git cat-file -e $commit_hash^{commit}; then
        echo "Commit $commit_hash exists."
        if git ls-tree -r $commit_hash --name-only | grep -q "restore.config"; then
            echo "Commit $commit_hash contains the necessary files."
            export COMMIT_HASH=$commit_hash
        else
            tput cup $(($pos - 2)) 0
            tput ed
            echo "Commit $commit_hash does not contain the necessary files."
            getCommit
        fi
    else
        tput cup $(($pos - 1)) 0
        tput ed
        echo "Commit $commit_hash does not exist."
        getCommit
    fi
}

tempfolder() {
    if [ -d "$tempfolder" ]; then
        rm -rf $tempfolder
    fi
    mkdir $tempfolder
    git_protocol=${git_protocol:-"https"}
    git_host=${git_host:-"github.com"}
    full_git_url=$git_protocol"://"$ghtoken"@"$git_host"/"$ghuser"/"$ghrepo".git"

    cd $tempfolder

    mkdir .git
    echo "[init]
    defaultBranch = "$repobranch"" >>.git/config #Add desired branch name to config before init
    git init
    git config pull.rebase false
    git remote add origin "$full_git_url"
    git pull origin "$repobranch"

    if [ -n "$COMMIT_HASH" ]; then
        git checkout $COMMIT_HASH
    fi
}

copyRestoreConfig() {
    echo -e "Restore config token, username, repo, branch name"
    sed -i "s/^github_token=.*/github_token=$ghtoken/" $temprestore
    sed -i "s/^github_username=.*/github_username=$ghuser/" $temprestore
    sed -i "s/^github_repository=.*/github_repository=$ghrepo/" $temprestore
    sed -i "s/^branch_name=.*/branch_name=\"$repobranch\"/" $temprestore
    cp $temprestore $envpath
}

restoreBackupFiles() {
    echo -e "Restore Backup Files"
    for path in "${backupPaths[@]}"; do
        for file in $path; do
            echo $file
            rsync -r --mkpath "$tempfolder/$file" "$HOME/$file"
        done
    done
}

restoreMoonrakerDB() {
    echo -e "Restore Moonraker Database"
    if [ -f "$tempfolder/moonraker-db-klipperbackup.db" ]; then
        cp $tempfolder/moonraker-db-klipperbackup.db "$HOME/printer_data/backup/database/moonraker-db-klipperbackup.db"
        MOONRAKER_URL="http://localhost:7125"
        data='{ "filename": "moonraker-db-klipperbackup.db" }'
        curl -X POST "$MOONRAKER_URL/server/database/restore" \
            -H "Content-Type: application/json" \
            -d "$data" >/dev/null 2>&1
    fi
}

copyTheme() {
    if [[ $theme_url ]]; then
        echo -e "Restore Theme"
        cd "$HOME"/printer_data/config/
        if [[ -d ".theme" ]]; then
            rm -rf .theme
        fi
        git clone $theme_url .theme
        if [ -f "$tempfolder/klipper-backup-restore/theme_changes.patch" ]; then
            cd .theme
            git apply --whitespace=nowarn "$tempfolder"/klipper-backup-restore/theme_changes.patch
        fi
    else
        echo -e "No Theme to restore"
    fi
}

cleanup() {
    sed -i "s/^theme_url.*//" $envpath
    sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' $envpath
    sudo systemctl restart moonraker.service
    sleep 3
    sudo systemctl start klipper.service
}

main
