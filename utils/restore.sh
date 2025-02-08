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
    check_klipper_installed
    configure
    line
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

check_klipper_installed() {
    if ! (service_exists "klipper" && service_exists "moonraker"); then
        echo -e "${R}●${NC} Klipper and Moonraker services not found, please ensure Klipper and Moonraker are installed and running!"
        exit 1
    fi
}

dependencies() {
    loading_wheel "${Y}●${NC} Checking for installed dependencies" &
    loading_pid=$!
    check_dependencies "jq" "curl" "rsync"
    kill $loading_pid
    echo -e "${CL}${G}●${NC} Checking for installed dependencies ${G}Done!${NC}\n"
    sleep 1
}

configure() {
    ghtoken_username=""
    questionline=$(getcursor)

    tput cup $(($questionline - 1)) 0
    clearUp
    pos2=$(getcursor)

    getToken() {
        pos2=$(getcursor)
        ghtoken=$(ask_token "${C}●${NC} Enter your GitHub token associated with the backup you want to restore")
        result=$(check_ghToken "$ghtoken") # Check Github Token using github API to ensure token is valid and connection can be estabilished to github
        if [ "$result" != "" ]; then
            ghtoken_username=$result
        else
            tput cup $(($pos2 - 2)) 0
            tput ed
            echo -e "${Y}●${NC} Invalid Github token or Unable to contact github API, Please re-enter your token and check for valid connection to github.com then try again!"
            getToken
        fi
    }
    getUser() {
        pos2=$(getcursor)
        ghuser=$(ask_textinput "${C}●${NC} Enter your github username" "$ghtoken_username")

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
        ghrepo=$(ask_textinput "${C}●${NC} Enter your repository name")
        if [ "$ghrepo" == "" ]; then
            tput cup $(($pos2 - 2)) 0
            tput ed
            echo -e "${Y}●${NC} Repository name cannot be empty!"
            getRepo
        fi
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
        repobranch=$(ask_textinput "${C}●${NC} Enter your desired branch name" "main")

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
        if ask_yn "${C}●${NC} Would you like to restore from a specific commit?" "no"; then
            commitHash
        else
            tempfolder
        fi
    }

    commitHash() {
        pos2=$(getcursor)
        commit_hash=$(ask_textinput "${C}●${NC} Enter the commit hash you would like to restore from")

        menu $pos2
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            tput cup $pos2 0
            tput ed
            validate_commit $commit_hash $pos2
        else
            tput cup $(($pos2 - 1)) 0
            tput ed
            commitHash
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
    tempfolder
    git fetch origin $repobranch
    if git cat-file -e $commit_hash^{commit}; then
        #echo "Commit $commit_hash exists."
        if git ls-tree -r $commit_hash --name-only | grep -q "restore.config"; then
            #echo "Commit $commit_hash contains the necessary files."
            git -c advice.detachedHead=false checkout $commit_hash
        else
            tput cup $(($pos - 2)) 0
            tput ed
            echo "${R}●${NC} Commit ${R}$commit_hash${NC} does not contain the necessary files."
            commitHash
        fi
    else
        tput cup $(($pos - 2)) 0
        tput ed
        echo "${R}●${NC} Commit ${R}$commit_hash${NC} does not exist."
        commitHash
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
    git init >/dev/null 2>&1
    git config pull.rebase false >/dev/null 2>&1
    git remote add origin "$full_git_url" >/dev/null 2>&1
    git pull origin "$repobranch" >/dev/null 2>&1
}

copyRestoreConfig() {
    #echo -e "Restore config token, username, repo, branch name"
    loading_wheel "${Y}●${NC} Creating new .env" &
    loading_pid=$!
    sed -i "s/^github_token=.*/github_token=$ghtoken/" $temprestore
    sed -i "s/^github_username=.*/github_username=$ghuser/" $temprestore
    sed -i "s/^github_repository=.*/github_repository=$ghrepo/" $temprestore
    sed -i "s/^branch_name=.*/branch_name=\"$repobranch\"/" $temprestore
    cp $temprestore $envpath
    kill $loading_pid
    echo -e "${CL}${G}●${NC} Creating new .env ${G}Done!${NC}"
}

restoreBackupFiles() {
    loading_wheel "${Y}●${NC} Restoring files" &
    loading_pid=$!
    for path in "${backupPaths[@]}"; do
        for file in $path; do
            #echo $file
            rsync -r --mkpath "$tempfolder/$file" "$HOME/$file"
        done
    done
    kill $loading_pid
    echo -e "${CL}${G}●${NC} Restoring files ${G}Done!${NC}"
}

restoreMoonrakerDB() {
    #echo -e "Restore Moonraker Database"
    loading_wheel "${Y}●${NC} Restore Moonraker Database" &
    loading_pid=$!
    if [ -f "$tempfolder/moonraker-db-klipperbackup.db" ]; then
        mkdir -p "$HOME/printer_data/backup/database"
        cp $tempfolder/moonraker-db-klipperbackup.db "$HOME/printer_data/backup/database/moonraker-db-klipperbackup.db"
        MOONRAKER_URL="http://localhost:7125"
        data='{ "filename": "moonraker-db-klipperbackup.db" }'
        curl -X POST "$MOONRAKER_URL/server/database/restore" \
            -H "Content-Type: application/json" \
            -d "$data" >/dev/null 2>&1
    fi
    kill $loading_pid
    echo -e "${CL}${G}●${NC} Restore Moonraker Database ${G}Done!${NC}"
}

copyTheme() {
    loading_wheel "${Y}●${NC} Restoring Theme" &
    loading_pid=$!
    if [[ $theme_url ]]; then
        #echo -e "Restore Theme"
        cd "$HOME"/printer_data/config/
        if [[ -d ".theme" ]]; then
            rm -rf .theme
        fi
        git clone $theme_url .theme
        if [ -f "$tempfolder/klipper-backup-restore/theme_changes.patch" ]; then
            cd .theme
            git apply --whitespace=nowarn "$tempfolder"/klipper-backup-restore/theme_changes.patch
        fi
        kill $loading_pid
        echo -e "${CL}${G}●${NC} Restoring Theme ${G}Done!${NC}\n"
    else
        kill $loading_pid
        echo -e "${CL}${M}●${NC} No Theme to restore - Skipped ${M}Skipped!${NC}\n"
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
