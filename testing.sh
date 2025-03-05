#!/usr/bin/env bash

trap 'stty echo; exit' SIGINT

scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..
    pwd -P
)

debug_info() {
    echo -e "DEBUG INFO:\n\n\
        GitHub Token: $ghtoken\n\
        GitHub Username: $ghuser\n\
        Repository Name: $ghrepo\n\
        Branch Name: $repobranch\n\
        Commit Hash: ${commit_hash:-N/A}"
}

source "$scriptsh_parent_path/klipper-backup/utils/utils.func"

prompt_with_cancel() {
    local type=$1      # "input" or "password"
    local msg=$2
    local default=$3
    local result

    if [ "$type" = "password" ]; then
        result=$(whiptail --title "Klipper Backup Restore" --passwordbox "$msg" 10 76 "$default" 3>&1 1>&2 2>&3)
    else
        result=$(whiptail --title "Klipper Backup Restore" --inputbox "$msg" 10 50 "$default" 3>&1 1>&2 2>&3)
    fi
    local status=$?
    if [ $status -ne 0 ]; then
        result=$(whiptail --title "Klipper Backup Restore" --menu "Select an option:" 15 75 3 \
            "Redo" "| Retry current prompt" \
            "Back" "| Go back to previous prompt" \
            "Quit" "| Quit the script" 3>&1 1>&2 2>&3)
    fi
    echo "$result"
}

configure() {
    local step=0

    while [ $step -le 4 ]; do
        case $step in
            0)
                ghtoken=$(prompt_with_cancel "password" "Enter your GitHub token:" "")
                case "$(echo "$ghtoken" | tr '[:upper:]' '[:lower:]')" in
                    redo) continue ;;
                    back) ;;
                    quit) exit 1 ;;
                esac
                if [ -z "$ghtoken" ]; then
                    whiptail --msgbox "GitHub token cannot be empty!" 10 50
                    continue
                fi
                gh_username=$(check_ghToken "$ghtoken")
                if [ -z "$gh_username" ]; then
                    whiptail --msgbox "Invalid token or API error!" 10 50
                    continue
                fi
                ((step++))
                ;;
            1)
                ghuser=$(prompt_with_cancel "input" "Enter your GitHub username:" "$gh_username")
                case "$(echo "$ghuser" | tr '[:upper:]' '[:lower:]')" in
                    redo) continue ;;
                    back) ((step--)); continue ;;
                    quit) exit 1 ;;
                esac
                if [ -z "$ghuser" ]; then
                    whiptail --msgbox "Username cannot be empty!" 10 50
                    continue
                fi
                ((step++))
                ;;
            2)
                ghrepo=$(prompt_with_cancel "input" "Enter your repository name:" "")
                case "$(echo "$ghrepo" | tr '[:upper:]' '[:lower:]')" in
                    redo) continue ;;
                    back) ((step--)); continue ;;
                    quit) exit 1 ;;
                esac
                if [ -z "$ghrepo" ]; then
                    whiptail --msgbox "Repository name cannot be empty!" 10 50
                    continue
                fi
                ((step++))
                ;;
            3)
                repobranch=$(prompt_with_cancel "input" "Enter your branch name:" "")
                case "$(echo "$repobranch" | tr '[:upper:]' '[:lower:]')" in
                    redo) continue ;;
                    back) ((step--)); continue ;;
                    quit) exit 1 ;;
                esac
                if [ -z "$repobranch" ]; then
                    whiptail --msgbox "Branch name cannot be empty!" 10 50
                    continue
                fi
                ((step++))
                ;;
            4)
                commit_option=$(whiptail --title "Klipper Backup Restore" --default-item "No" --menu "Restore from specific commit? (Default No)" 15 75 3 \
                    "Yes" "| Enter a commit hash" \
                    "No" "| Continue without specifying a commit" \
                    "Back" "| Go back" 3>&1 1>&2 2>&3)
                case "$(echo "$commit_option" | tr '[:upper:]' '[:lower:]')" in
                    back) ((step--)); continue ;;
                    no) commit_hash=""; ((step++)); continue ;;
                    yes) ;;
                    *) ((step++)); continue ;;
                esac
                commit_hash=$(prompt_with_cancel "input" "Enter the commit hash:" "")
                case "$(echo "$commit_hash" | tr '[:upper:]' '[:lower:]')" in
                    redo) continue ;;
                    back) continue ;;
                    quit) exit 1 ;;
                esac
                if [ -z "$commit_hash" ]; then
                    whiptail --msgbox "Commit hash cannot be empty!" 10 50
                    continue
                fi
                ((step++))
                ;;
        esac
    done

    export ghtoken ghuser ghrepo repobranch commit_hash
}

configure
echo "test"
debug_info