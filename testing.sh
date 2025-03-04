#!/usr/bin/env bash

trap 'stty echo; exit' SIGINT

scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..
    pwd -P
)

confirmCancel() {
    optionMenu=$1
    optionDesc=$2
    choice=$(whiptail --title "Klipper Backup Restore" --menu "Please confirm your action?" 15 75 5 \
    "$1" "$2" \
    "Back" "Return to previous menu." \
    "Quit" "Stop Script." \
    3>&1 1>&2 2>&3)
    echo $choice
}

source "$scriptsh_parent_path"/klipper-backup/utils/utils.func

configure() {
    getToken() {
        ghtoken_username=""
        ghtoken=$(whiptail --title "Klipper Backup Restore" --passwordbox "Enter your GitHub token associated with the backup you want to restore:" 10 76 3>&1 1>&2 2>&3)

        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            if [ -z "$ghtoken" ]; then
                whiptail --msgbox "GitHub token cannot be empty!" 10 50
                getToken
            fi

            result=$(check_ghToken "$ghtoken") # Check GitHub Token using API

            if [ -n "$result" ]; then
                ghtoken_username=$result
                getUser
            else
                whiptail --title "Klipper Backup Restore" --msgbox "Invalid GitHub token or unable to contact GitHub API. Please check your connection and try again!" 10 60
                getToken
            fi
        else
            confirmCancel
            exit
        fi
    }

    getUser() {
        ghuser=$(whiptail --title "Klipper Backup Restore" --inputbox "Enter your GitHub username:" 10 50 "$ghtoken_username" 3>&1 1>&2 2>&3)

        exitstatus=$?
        if [ $exitstatus == 0 ]; then
            if [ -z "$ghuser" ]; then
                whiptail --msgbox "GitHub username cannot be empty!" 10 50
                getUser
            fi
            getRepo
        else
            exit
        fi
    }

    getRepo() {
        ghrepo=$(whiptail --title "Klipper Backup Restore" --inputbox "Enter your repository name:" 10 50 3>&1 1>&2 2>&3)

        exitstatus=$?
        if [ $exitstatus == 0 ]; then
            if [ -z "$ghrepo" ]; then
                whiptail --title "Klipper Backup Restore" --msgbox "Repository name cannot be empty!" 10 50
                getRepo
            fi
            getBranch
        else
            exit
        fi
    }

    getBranch() {
        repobranch=$(whiptail --title "Klipper Backup Restore" --inputbox "Enter your desired branch name:" 10 50 "main" 3>&1 1>&2 2>&3)

        exitstatus=$?
        if [ $exitstatus == 0 ]; then
            if [ -z "$repobranch" ]; then
                whiptail --title "Klipper Backup Restore" --msgbox "Branch name cannot be empty!" 10 50
                getBranch
            fi
            getCommit
        else
            exit
        fi
    }

    getCommit() {
        whiptail --title "Klipper Backup Restore" --yesno "Would you like to restore from a specific commit? (Default No)" --defaultno 10 50
        exitstatus=$?

        if [ $exitstatus = 0 ]; then
            commitHash
        else
            echo "TempFolder would run"
            #tempfolder
            if "$repobranch" == "test"; then #!(git ls-tree -r HEAD --name-only | grep -q "restore.config"); then
                whiptail --msgbox "The latest commit for this branch does not contain the necessary files to restore. Please choose another branch or specify a commit to restore from." 10 70
                getBranch
            fi
        fi
    }

    commitHash() {
        commit_hash=$(whiptail --inputbox "Enter the commit hash you would like to restore from:" 10 60 3>&1 1>&2 2>&3)

        if [ -z "$commit_hash" ]; then
            whiptail --msgbox "Commit ID cannot be empty!" 10 50
            commitHash
        fi

        #validate_commit "$commit_hash"
    }

    debug_info() {
        echo -e "DEBUG INFO:\n\n\
        GitHub Token: $ghtoken\n\
        GitHub Username: $ghuser\n\
        Repository Name: $ghrepo\n\
        Branch Name: $repobranch\n\
        Commit Hash: ${commit_hash:-N/A}"
    }

    getToken

}

configure
debug_info # Call debug after last input