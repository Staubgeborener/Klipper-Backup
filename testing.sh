#!/usr/bin/env bash

trap 'stty echo; exit' SIGINT

scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..
    pwd -P
)

source "$scriptsh_parent_path/utils/utils.func"

debug_info() {
    echo -e "DEBUG INFO:\n\n\
        GitHub Token: $ghtoken\n\
        GitHub Username: $ghusername\n\
        Repository Name: $ghrepo\n\
        Branch Name: $ghbranch\n\
        Commit Hash: ${ghcommithash:-N/A}"
}

checkExit() {
    if [ $1 -ne 0 ]; then
        result=$(whiptail --title "Klipper Backup Restore" --menu "Select an option:" 15 75 3 \
            "Redo" "| Retry current prompt" \
            "Back" "| Go back to previous prompt" \
            "Quit" "| Quit the script" 3>&1 1>&2 2>&3)
        echo $result
    fi
}

main() {
    while true; do
        if [ -z $ghtoken ]; then
            ghtoken=$(whiptail --title "Klipper Backup Restore" --passwordbox "Enter your Github token:" 10 76 "" 3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                ghtoken=""
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
        fi
        if [ -z $ghusername ]; then
            username=$(check_ghToken "$ghtoken")
            if [ -z "$username" ]; then
                whiptail --msgbox "Invalid token or API error!" 10 50
                ghtoken=""
                continue
            fi
            ghusername=$(whiptail --title "Klipper Backup Restore" --inputbox "Enter your GitHub username:" 10 50 "$username" 3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                ghusername=""
                continue
                ;;
            back)
                ghtoken=""
                ghusername=""
                continue
                ;;
            quit) exit 1 ;;
            esac
        fi
        if [ -z $ghrepo ]; then
            ghrepo=$(whiptail --title "Klipper Backup Restore" --inputbox "Enter your repository name:" 10 50 "" 3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                ghrepo=""
                continue
                ;;
            back)
                ghusername=""
                ghrepo=""
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
            ghbranch=$(whiptail --title "Klipper Backup Restore" --inputbox "Enter your branch name:" 10 50 "" 3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                ghbranch=""
                continue
                ;;
            back)
                ghrepo=""
                ghbranch=""
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
            commit_option=$(whiptail --title "Klipper Backup Restore" --default-item "No" --menu "Restore from specific commit? (Default No)" 15 75 3 \
                "Yes" "| Enter a commit hash" \
                "No" "| Continue without specifying a commit" \
                3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                ghcommithash=""
                continue
                ;;
            back)
                ghbranch=""
                ghcommithash=""
                continue
                ;;
            quit) exit 1 ;;
            esac
            case "$(echo "$commit_option" | tr '[:upper:]' '[:lower:]')" in
            no)
                ghcommithash=""
                break
                ;;
            yes) ;;
            esac
        fi
        if [ -z $ghcommithash ]; then
            ghcommithash=$(whiptail --title "Klipper Backup Restore" --inputbox "Enter the commit hash:" 10 50 "" 3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                ghcommithash=""
                continue
                ;;
            back)
                commit_option=""
                ghcommithash=""
                continue
                ;;
            quit) exit 1 ;;
            esac
            if [ -z "$ghcommithash" ]; then
                whiptail --msgbox "Commit hash cannot be empty!" 10 50
                continue
            fi
        fi
        break
    done
}

main
debug_info
