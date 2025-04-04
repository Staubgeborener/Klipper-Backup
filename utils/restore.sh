#!/usr/bin/env bash

trap 'stty echo; exit' SIGINT

scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..``
    pwd -P
)

# Initialize functions from utils
source "$scriptsh_parent_path"/utils/utils.func
#

envpath="$scriptsh_parent_path"/.env
tempfolder="/tmp/klipper-backup-restore-tmp"
temprestore="$tempfolder/klipper-backup-restore/restore.config"
restore_folder="$HOME"/klipper-backup-restore
restore_config="$restore_folder"/restore.config

main() {
    clear
    sudo -v
    commonDeps
    check_klipper_installed
    clear
    configure
    logo
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
    line
}

check_klipper_installed() {
    if ! (service_exists "klipper" && service_exists "moonraker"); then
        echo -e "${R}●${NC} Klipper and Moonraker services not found, please ensure Klipper and Moonraker are installed and running!"
        exit 1
    fi
}

validate_commit() {
    local commit_hash=$1
    {
        tempfolder
        echo 10
        sleep 0.1
        git fetch origin $ghbranch 2>/dev/null
        echo 30
        sleep 0.1
        if git cat-file -e $commit_hash^{commit} 2>/dev/null; then
            echo 50
            sleep 0.1
            if git ls-tree -r $commit_hash --name-only | grep -q "restore.config" 2>/dev/null; then
                git -c advice.detachedHead=false checkout $commit_hash 2>/dev/null
                echo 80
                sleep 0.1
                echo 100
                sleep 0.3
            fi
        fi
    } | whiptail --gauge "Checking for Commit $commit_hash..." 8 50 0
    if [[ "$commit_hash" =~ ^[0-9a-f]{7,40}$ ]] && git cat-file -e $commit_hash^{commit} 2>/dev/null; then
        if git ls-tree -r $commit_hash --name-only | grep -q "restore.config" 2>/dev/null; then
            return 0
        else
            return 1
        fi
    else
        return 2
    fi
}

configure() {
    while true; do
        if [ -z $ghtoken ]; then
            ghtoken=$(whiptail --title "$TITLE Restore" --passwordbox "Enter your Github token:" 10 76 "" 3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                unset ghtoken
                continue
                ;;
            back)
                continue
                ;;
            quit) exit 1 ;;
            esac
            if [ -z "$ghtoken" ]; then
                whiptail --msgbox "GitHub token cannot be empty!" 10 50
                continue
            fi
            ghusername=$(getUsername "$ghtoken")
            if [ -z "$ghusername" ]; then
                whiptail --msgbox "Invalid GitHub token or unable to contact GitHub API. Please check your connection and try again!" 10 76
                unset ghtoken
                continue
            fi
        fi
        if [ -z $ghrepo ]; then
            ghrepo=$(whiptail --title "$TITLE Restore" --inputbox "Enter your repository name:" 10 50 "" 3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                unset ghrepo
                continue
                ;;
            back)
                unset ghtoken
                unset ghrepo
                continue
                ;;
            quit) exit 1 ;;
            esac
            if [ -z "$ghrepo" ]; then
                whiptail --msgbox "Repository name cannot be empty!" 10 50
                continue
            fi
        fi
        if [ -z $ghbranch ]; then
            ghbranch=$(whiptail --title "$TITLE Restore" --inputbox "Enter the branch name:" 10 50 "" 3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                unset ghbranch
                continue
                ;;
            back)
                unset ghrepo
                unset ghbranch
                continue
                ;;
            quit) exit 1 ;;
            esac
            if [ -z "$ghbranch" ]; then
                whiptail --msgbox "Branch name cannot be empty!" 10 50
                continue
            fi
        fi
        if [ -z $commit_option ]; then
            commit_option=$(whiptail --title "$TITLE Restore" --default-item "No" --menu "Restore from specific commit? (Default No)" 15 75 3 \
                "Yes" "| Enter a commit hash" \
                "No" "| Continue without specifying a commit" \
                3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                unset ghcommithash
                continue
                ;;
            back)
                unset ghbranch
                unset ghcommithash
                continue
                ;;
            quit) exit 1 ;;
            esac
            case "$(echo "$commit_option" | tr '[:upper:]' '[:lower:]')" in
            no)
                unset ghcommithash
                tempfolder
                if !(git ls-tree -r HEAD --name-only | grep -q "restore.config"); then
                    whiptail --msgbox "The latest commit for this branch does not contain the necessary files to restore. Please choose another branch or specify a commit to restore from." 10 76
                    unset ghbranch
                    unset commit_option
                    unset ghcommithash
                    continue
                fi
                break
                ;;
            yes) ;;
            esac
        fi
        if [ -z $ghcommithash ]; then
            ghcommithash=$(whiptail --title "$TITLE Restore" --inputbox "Enter the commit hash:" 10 50 "" 3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                unset ghcommithash
                continue
                ;;
            back)
                unset commit_option
                unset ghcommithash
                continue
                ;;
            quit) exit 1 ;;
            esac
            if [ -z "$ghcommithash" ]; then
                whiptail --msgbox "Commit hash cannot be empty!" 10 50
                continue
            fi
            validate_commit $ghcommithash
            result=$?
            if [ $result -eq 1 ]; then
                whiptail --msgbox "Commit: $ghcommithash found! However, this commit does not contain the necessary files to restore.\n Please choose another branch or specify a different commit hash to restore from." 10 76
                    unset ghbranch
                    unset commit_option
                    unset ghcommithash
                continue
            elif [ $result -eq 2 ]; then
                whiptail --msgbox "Commit: $ghcommithash does not exist.\n Please choose another branch or specify a different commit hash to restore from." 10 76
                    unset ghbranch
                    unset commit_option
                    unset ghcommithash
                continue
            else
                whiptail --msgbox "Commit Found! Using: $ghcommithash for restore\n  Commit Message: $(git show -s --format='%s')" 10 76
            fi
        fi
        break
    done
}

tempfolder() {
    if [ -d "$tempfolder" ]; then
        rm -rf $tempfolder 2>/dev/null
    fi
    mkdir $tempfolder
    git_protocol=${git_protocol:-"https"}
    git_host=${git_host:-"github.com"}
    full_git_url=$git_protocol"://"$ghtoken"@"$git_host"/"$ghusername"/"$ghrepo".git"

    cd $tempfolder
    mkdir .git
    echo "[init]
    defaultBranch = "$ghbranch"" >>.git/config #Add desired branch name to config before init
    git init >/dev/null 2>&1
    git config pull.rebase false >/dev/null 2>&1
    git remote add origin "$full_git_url" >/dev/null 2>&1
    git pull origin "$ghbranch" >/dev/null 2>&1
}

copyRestoreConfig() {
    #echo -e "Restore config token, username, repo, branch name"
    loading_wheel "${Y}●${NC} Creating new .env" &
    loading_pid=$!
    sed -i "s/^github_token=.*/github_token=$ghtoken/" $temprestore
    sed -i "s/^github_username=.*/github_username=$ghusername/" $temprestore
    sed -i "s/^github_repository=.*/github_repository=$ghrepo/" $temprestore
    sed -i "s/^branch_name=.*/branch_name=\"$ghbranch\"/" $temprestore
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
    if [ -f "$tempfolder/moonraker-db-klipperbackup.db" ]; then
        loading_wheel "${Y}●${NC} Restore Moonraker Database" &
        loading_pid=$!
        mkdir -p "$HOME/printer_data/backup/database"
        cp $tempfolder/moonraker-db-klipperbackup.db "$HOME/printer_data/backup/database/moonraker-db-klipperbackup.db"
        MOONRAKER_URL="http://localhost:7125"
        data='{ "filename": "moonraker-db-klipperbackup.db" }'
        curl -X POST "$MOONRAKER_URL/server/database/restore" \
            -H "Content-Type: application/json" \
            -d "$data" >/dev/null 2>&1
        kill $loading_pid
        echo -e "${CL}${G}●${NC} Restore Moonraker Database ${G}Done!${NC}"
    else
        echo -e "${CL}${M}●${NC} Restore Moonraker Database ${M}Skipped! (No database backup found)${NC}"
    fi
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
        echo -e "${CL}${M}●${NC} No Theme to restore - Skipped ${M}Skipped!${NC}"
    fi
}

cleanup() {
    loading_wheel "${Y}●${NC} Cleaning Up" &
    loading_pid=$!
    sed -i "s/^theme_url.*//" $envpath
    sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' $envpath
    sudo systemctl restart moonraker.service
    sleep 5
    sudo systemctl restart klipper.service
    kill $loading_pid
    echo -e "${CL}${G}●${NC} Cleaning Up ${G}Done!${NC}\n"
}

main
