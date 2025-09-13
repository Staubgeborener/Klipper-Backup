#!/usr/bin/env bash

trap 'stty echo; exit' SIGINT

parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)

if [[ ! -f .env ]]; then
    cp $parent_path/.env.example $parent_path/.env
fi

source $parent_path/utils/utils.func

unique_id=$(getUniqueid)

main() {
    clear
    sudo -v
    commonDeps
    clear
    install_update
    configure
    promptOptional
    patch_klipper-backup_update_manager
    install_filewatch_service
    install_backup_service
    install_cron
    echo -e "${G}●${NC} Installation Complete!\n  For help or further information, read the docs: https://klipperbackup.xyz"
}

logo() {
    clear
    echo -e "${C}$(
        cat <<"EOF"
    __ __ ___                             ____             __                     ____           __        ____
   / //_// (_)___  ____  ___  _____      / __ )____ ______/ /____  ______        /  _/___  _____/ /_____ _/ / /
  / ,<  / / / __ \/ __ \/ _ \/ ___/_____/ __  / __ `/ ___/ //_/ / / / __ \______ / // __ \/ ___/ __/ __ `/ / /
 / /| |/ / / /_/ / /_/ /  __/ /  /_____/ /_/ / /_/ / /__/ ,< / /_/ / /_/ /_____// // / / (__  ) /_/ /_/ / / /
/_/ |_/_/_/ .___/ .___/\___/_/        /_____/\__,_/\___/_/|_|\__,_/ .___/     /___/_/ /_/____/\__/\__,_/_/_/
         /_/   /_/                                               /_/
EOF
    )${NC}"
    line
}

install_update() {
    # Need to add as Whiptail warning
    # if [[ $EUID -eq 0 || $USER == "root" ]]; then
    #     echo -e "${R}You are logged in as root. It is recommended that you cancel the installation with CTRL+C and log in as a non-privileged user first.\nInstalling as root can lead to problems and is not intended.${NC}\n"
    # fi

    promptInstall=$(whiptail --title "$TITLE Install" --backtitle "$updateMsg" --noitem --default-item "Yes" --menu "Do you want to proceed with installation/(re)configuration?" 15 75 3 \
        "Yes" "" \
        "No" "" \
        3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        clear
        echo -e "${R}●${NC} Installation aborted.\n"
        exit 1
    fi
    if [[ $promptInstall == "Yes" ]]; then
        cd "$HOME"
        if [ ! -d "klipper-backup" ]; then
            {
                echo 20
                sleep 0.1
                git clone https://github.com/Staubgeborener/klipper-backup.git 2>/dev/null
                echo 50
                sleep 0.1
                chmod +x ./klipper-backup/script.sh
                echo 70
                sleep 0.1
                cp ./klipper-backup/.env.example ./klipper-backup/.env
                echo 90
                sleep 0.1
                echo 100
                sleep 0.3
            } | whiptail --title "$TITLE Install" --backtitle "$updateMsg" --guage "Installing Klipper-Backup" 8 50 0
        else
            check_updates
        fi
    else
        clear
        echo -e "${R}●${NC} Installation aborted.\n"
        exit 1
    fi
}

check_updates() {
    cd ~/klipper-backup
    if [ "$(git rev-parse HEAD)" = "$(git ls-remote $(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1)" ]; then
        updateMsg="● Klipper-Backup is up to date."
    else
        updateMsg="● Update for klipper-backup Available!"
        promptUpdate=$(whiptail --title "$TITLE Install" --backtitle "$updateMsg" --noitem --default-item "Yes" --menu "Proceed with update?" 15 75 3 \
            "Yes" "" \
            "No" "" \
            3>&1 1>&2 2>&3)

        if [[ $promptUpdate == "Yes" ]]; then
            update_progress() {
                local progress=0
                while [ $progress -lt 100 ]; do
                    echo $progress
                    sleep 0.5
                    progress=$((progress + 10))
                done
            }

            update_progress | whiptail --title "$TITLE Install" --backtitle "$updateMsg" --gauge "Updating Klipper-Backup" 8 50 0
            progress_pid=$!

            if git pull >/dev/null 2>&1; then
                kill $progress_pid 2>/dev/null
                echo 100 | whiptail --title "$TITLE Install" --backtitle "$updateMsg" --gauge "Updating Klipper-Backup Done!\n Restarting script..." 8 50 0
                sleep 1
                exec $parent_path/install.sh
            else
                kill $progress_pid 2>/dev/null
                whiptail --title "$TITLE Install" --backtitle "$updateMsg" --infobox "Error Updating Klipper-Backup: Repository is dirty running git reset --hard then restarting script"
                sleep 1
                git reset --hard 2>/dev/null
                exec $parent_path/install.sh
            fi
        else
            whiptail --title "$TITLE Install" --msgbox "Klipper-Backup update Skipped!" 10 78
        fi
    fi
}

configure() {
    if grep -q "github_token=ghp_xxxxxxxxxxxxxxxx" "$parent_path"/.env; then # Check if the github token still matches the value when initially copied from .env.example
        message="Do you want to proceed with configuring the Klipper-Backup .env?"
    else
        message="Do you want to proceed with reconfiguring the Klipper-Backup .env?"
    fi

    configResult=$(whiptail --title "Klipper Backup Restore" --noitem --default-item "Yes" --menu "$message" 15 75 3 \
        "Yes" "" \
        "No" "" \
        3>&1 1>&2 2>&3)

    if [[ $configResult == "Yes" ]]; then
        whiptail --title "$TITLE Install" --msgbox "See the following for how to create your token: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens" 10 78
        while true; do
            if [ -z $ghtoken ]; then
                ghtoken=$(whiptail --title "$TITLE Install" --passwordbox "Enter your Github token:" 10 76 "" 3>&1 1>&2 2>&3)
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
                if [ -z "$ghusername" ] || [ $username -eq 1 ]; then
                    whiptail --msgbox "Invalid GitHub token or unable to contact GitHub API. Please check your connection and try again!" 10 76
                    unset ghtoken
                    continue
                fi
                sed -i "s/^github_token=.*/github_token=$ghtoken/" "$HOME/klipper-backup/.env"
                sed -i "s/^github_username=.*/github_username=$ghusername/" "$HOME/klipper-backup/.env"
            fi
            if [ -z $ghrepo ]; then
                ghrepo=$(whiptail --title "$TITLE Install" --inputbox "Enter your repository name:" 10 50 "" 3>&1 1>&2 2>&3)
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
                sed -i "s/^github_repository=.*/github_repository=$ghrepo/" "$HOME/klipper-backup/.env"
            fi
            if [ -z $ghbranch ]; then
                ghbranch=$(whiptail --title "$TITLE Install" --inputbox "Enter your desired branch name:" 10 50 "main" 3>&1 1>&2 2>&3)
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
                sed -i "s/^branch_name=.*/branch_name=\"$repobranch\"/" "$HOME/klipper-backup/.env"
            fi
            if [ -z $commitname ]; then
                commitname=$(whiptail --title "$TITLE Install" --inputbox "Enter your desired git commit username:" 10 50 "$(whoami)" 3>&1 1>&2 2>&3)
                check=$(checkExit $?)
                case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
                redo)
                    unset commitname
                    continue
                    ;;
                back)
                    unset ghbranch
                    unset commitname
                    continue
                    ;;
                quit) exit 1 ;;
                esac
                if [ -z "$commitname" ]; then
                    whiptail --msgbox "Git commit username cannot be empty!" 10 50
                    continue
                fi
                sed -i "s/^commit_username=.*/commit_username=\"$commitname\"/" "$HOME/klipper-backup/.env"
            fi
            if [ -z $commitemail ]; then
                commitemail=$(whiptail --title "$TITLE Install" --inputbox "Enter your desired git commit email:" 10 50 "$(whoami)@$(hostname --short)-$unique_id" 3>&1 1>&2 2>&3)
                check=$(checkExit $?)
                case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
                redo)
                    unset commitemail
                    continue
                    ;;
                back)
                    unset commitname
                    unset commitemail
                    continue
                    ;;
                quit) exit 1 ;;
                esac
                if [ -z "$commitemail" ]; then
                    whiptail --msgbox "Git commit email cannot be empty!" 10 50
                    continue
                fi
                sed -i "s/^commit_email=.*/commit_email=\"$commitemail\"/" "$HOME/klipper-backup/.env"
            fi
                echo -e "${UL}${BOLD}${G}Klipper Backup Install${NC}"
                echo -e "${CL}${G}●${NC} Configuration ${G}Done!${NC}"
            break
        done
    else
        echo -e "${UL}${BOLD}${G}Klipper Backup Install${NC}"
        echo -e "${CL}${M}●${NC} Configuration ${M}Skipped!${NC}"
    fi
}

promptOptional() {
    while true; do
        if [ -z $moonrakerManager ]; then
            if [[ -d $HOME/moonraker ]] && systemctl is-active moonraker >/dev/null 2>&1; then
                if ! grep -Eq "^\[update_manager klipper-backup\]\s*$" "$HOME/printer_data/config/moonraker.conf"; then
                    moonrakerManager=$(whiptail --title "Klipper Backup Restore" --noitem --default-item "Yes" --menu "Would you like to add klipper-backup to moonraker update manager?" 15 75 3 \
                        "Yes" "" \
                        "No" "" \
                        3>&1 1>&2 2>&3)
                    if [[ $moonrakerManager == "Yes" ]]; then
                        moonrakerMsg="${CL}${G}●${NC} Adding klipper-backup to update manager ${G}Done!${NC}"
                    else
                        moonrakerMsg="${CL}${M}●${NC} Adding klipper-backup to update manager ${M}Skipped!${NC}"
                    fi
                else
                    moonrakerMsg="${CL}${M}●${NC} Adding klipper-backup to update manager ${M}Skipped! (Already Added)${NC}"
                fi
            else
                moonrakerMsg="${R}●${NC} Moonraker is not installed. Update manager configuration ${R}Skipped!${NC}\n${Y}● Please install moonraker then run the script again to update the moonraker configuration${NC}"
            fi
        fi
        if [ -z $installFilewatch ]; then
            if service_exists klipper-backup-filewatch; then
                filewatchPrompt="Would you like to reinstall the filewatch backup service? (this will trigger a backup after changes are detected)"
            else
                filewatchPrompt="Would you like to install the filewatch backup service? (this will trigger a backup after changes are detected)"
            fi
            installFilewatch=$(whiptail --title "Klipper Backup Restore" --noitem --default-item "Yes" --menu "$filewatchPrompt" 15 75 3 \
                "Yes" "" \
                "No" "" \
                3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                unset installFilewatch
                continue
                ;;
            back)
                unset installFilewatch
                unset moonrakerManager
                continue
                ;;
            quit) exit 1 ;;
            esac
        fi
        if [ -z $installService ]; then
            if service_exists klipper-backup-on-boot; then
                servicePrompt="Would you like to reinstall the on-boot backup service?"
            else
                servicePrompt="Would you like to install the on-boot backup service?"
            fi
            installService=$(whiptail --title "Klipper Backup Restore" --noitem --default-item "Yes" --menu "$servicePrompt" 15 75 3 \
                "Yes" "" \
                "No" "" \
                3>&1 1>&2 2>&3)
            check=$(checkExit $?)
            case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
            redo)
                unset installService
                continue
                ;;
            back)
                unset installService
                unset installFilewatch
                continue
                ;;
            quit) exit 1 ;;
            esac
        fi
        if [ -z $installCron ]; then
            if ! (crontab -l 2>/dev/null | grep -q "$HOME/klipper-backup/script.sh"); then
                installCron=$(whiptail --title "Klipper Backup Restore" --noitem --default-item "Yes" --menu "Would you like to install the cron task? (automatic backup every 4 hours)" 15 75 3 \
                    "Yes" "" \
                    "No" "" \
                    3>&1 1>&2 2>&3)
                check=$(checkExit $?)
                case "$(echo "$check" | tr '[:upper:]' '[:lower:]')" in
                redo)
                    unset installCron
                    continue
                    ;;
                back)
                    unset installCron
                    unset installService
                    continue
                    ;;
                quit) exit 1 ;;
                esac
            else
                cronMsg="${CL}${M}●${NC} Installing cron task ${M}Skipped! (Already Installed)${NC}"
            fi
        fi
        break
    done
}

patch_klipper-backup_update_manager() {
    if [[ $moonrakerManager == "Yes" ]]; then
        loading_wheel "${Y}●${NC} Adding klipper-backup to update manager" &
        loading_pid=$!
        ### add new line to conf if it doesn't end with one
        if [[ $(tail -c1 "$HOME/printer_data/config/moonraker.conf" | wc -l) -eq 0 ]]; then
            echo "" >>"$HOME/printer_data/config/moonraker.conf"
        fi

        if /usr/bin/env bash -c "cat $parent_path/install-files/moonraker.conf >> $HOME/printer_data/config/moonraker.conf"; then
            sudo systemctl restart moonraker.service
        fi

        kill $loading_pid
    fi
    echo -e "$moonrakerMsg"
}

install_filewatch_service() {
    if [[ $installFilewatch == "Yes" ]]; then
        if ! checkinotify >/dev/null 2>&1; then # Checks if the version of inotify installed matches the latest release
            removeOldInotify
            echo -e "${Y}●${NC} Installing latest version of inotify-tools (This may take a few minutes)"
            sudo rm -rf inotify-tools/ # remove folder incase it for some reason still exists
            sudo rm -f /usr/bin/fsnotifywait /usr/bin/fsnotifywatch # remove symbolic links to keep error about file exists from occurring
            loading_wheel "   ${Y}●${NC} Clone inotify-tools repo" &
            loading_pid=$!
            git clone https://github.com/inotify-tools/inotify-tools.git 2>/dev/null
            kill $loading_pid
            echo -e "${CL}   ${G}●${NC} Clone inotify-tools repo ${G}Done!${NC}"
            sudo apt-get install autoconf autotools-dev automake libtool -y >/dev/null 2>&1

            cd inotify-tools/

            buildCommands=("./autogen.sh" "./configure --prefix=/usr" "make" "make install")
            for ((i = 0; i < ${#buildCommands[@]}; i++)); do
                run_command "${buildCommands[i]}"
            done

            cd ..
            sudo rm -rf inotify-tools
            echo -e "${CL}${G}●${NC} Installing latest version of inotify-tools ${G}Done!${NC}"
        fi
        loading_wheel "${Y}●${NC} Installing filewatch service" &
        loading_pid=$!
        if (
            !(
            sudo systemctl stop klipper-backup-filewatch.service 2>/dev/null
            sudo cp $parent_path/install-files/klipper-backup-filewatch.service /etc/systemd/system/klipper-backup-filewatch.service
            sudo sed -i "s/^After=.*/After=$(wantsafter)/" "/etc/systemd/system/klipper-backup-filewatch.service"
            sudo sed -i "s/^Wants=.*/Wants=$(wantsafter)/" "/etc/systemd/system/klipper-backup-filewatch.service"
            sudo sed -i "s/^User=.*/User=${SUDO_USER:-$USER}/" "/etc/systemd/system/klipper-backup-filewatch.service"
            sudo systemctl daemon-reload 2>/dev/null
            sudo systemctl enable klipper-backup-filewatch.service 2>/dev/null
            sudo systemctl start klipper-backup-filewatch.service 2>/dev/null
            sleep .5
            kill $loading_pid
        ) &

            start_time=$(date +%s)
            timeout_duration=20

            while [ "$(ps -p $! -o comm=)" ]; do
                # Calculate elapsed time
                end_time=$(date +%s)
                elapsed_time=$((end_time - start_time))

                # Check if the timeout has been reached
                if [ $elapsed_time -gt $timeout_duration ]; then
                    echo -e "${CL}${R}●${NC} Installing filewatch service took to long to complete!"
                    kill $!
                    kill $loading_pid
                    exit 1
                fi

                sleep 1
            done
        ); then
            echo -e "${CL}${G}●${NC} Installing filewatch service ${G}Done!${NC}"
        fi
    else
        echo -e "${CL}${M}●${NC} Installing filewatch service ${M}Skipped!${NC}"
    fi
}

install_backup_service() {
    if [[ $installService == "Yes" ]]; then
        loading_wheel "${Y}●${NC} Installing on-boot service" &
        loading_pid=$!
        if (
            !(
            sudo systemctl stop klipper-backup-on-boot.service 2>/dev/null
            sudo cp $parent_path/install-files/klipper-backup-on-boot.service /etc/systemd/system/klipper-backup-on-boot.service
            sudo sed -i "s/^After=.*/After=$(wantsafter)/" "/etc/systemd/system/klipper-backup-on-boot.service"
            sudo sed -i "s/^Wants=.*/Wants=$(wantsafter)/" "/etc/systemd/system/klipper-backup-on-boot.service"
            sudo sed -i "s/^User=.*/User=${SUDO_USER:-$USER}/" "/etc/systemd/system/klipper-backup-on-boot.service"
            sudo systemctl daemon-reload 2>/dev/null
            sudo systemctl enable klipper-backup-on-boot.service 2>/dev/null
            sudo systemctl start klipper-backup-on-boot.service 2>/dev/null
            kill $loading_pid
        ) &

            start_time=$(date +%s)
            timeout_duration=20

            while [ "$(ps -p $! -o comm=)" ]; do
                # Calculate elapsed time
                end_time=$(date +%s)
                elapsed_time=$((end_time - start_time))

                # Check if the timeout has been reached
                if [ $elapsed_time -gt $timeout_duration ]; then
                    echo -e "${CL}${R}●${NC} Installing on-boot service took to long to complete!"
                    kill $!
                    kill $loading_pid
                    exit 1
                fi

                sleep 1
            done
        ); then
            echo -e "${CL}${G}●${NC} Installing on-boot service ${G}Done!${NC}"
        fi
    else
        echo -e "${CL}${M}●${NC} Installing on-boot service ${M}Skipped!${NC}"
    fi
}

install_cron() {
    if [[ $installCron == "Yes" ]]; then
        loading_wheel "${Y}●${NC} Installing cron task" &
        loading_pid=$!
        (
            crontab -l 2>/dev/null
            echo "0 */4 * * * $HOME/klipper-backup/script.sh -c \"Cron backup - \$(date +'\\%x - \\%X')\""
        ) | crontab -
        sleep .5
        kill $loading_pid
        cronMsg="${CL}${G}●${NC} Installing cron task ${G}Done!${NC}"
    else
        cronMsg="${CL}${M}●${NC} Installing cron task ${M}Skipped!${NC}"
    fi
    echo -e "$cronMsg"
}

if [ "$1" == "check_updates" ]; then
    check_updates
elif [ "$1" == "--restore" ] || [ "$1" == "-r" ]; then
    exec $parent_path/utils/restore.sh
else
    main
fi
