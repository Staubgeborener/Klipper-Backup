#!/usr/bin/env bash

parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)

if [[ ! -f .env ]]; then
    cp $parent_path/.env.example $parent_path/.env
fi

source $parent_path/install-utils.sh

set -e

main() {
    clear
    sudo -v
    check_dependencies
    logo
    install_repo
    configure
    patch_klipper-backup_update_manager
    install_filewatch_service
    install_backup_service
    install_cron
    echo -e "${G}●${NC} Installation Complete!\n"
}

check_dependencies() {
    if ! command -v jq &>/dev/null; then
        # Check the package manager and attempt a silent install
        if command -v apt-get &>/dev/null; then
            sudo apt-get update
            sudo apt-get install -y jq
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y jq
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm jq
        elif command -v apk &>/dev/null; then
            sudo apk add jq
        else
            echo "Unsupported package manager. Please install jq manually."
            return 1
        fi

        # Check if the installation was successful
        if command -v jq &>/dev/null; then
            echo "jq has been installed."
        else
            echo "Installation failed. Please install jq manually."
            return 1
        fi
    fi
}

install_repo() {
    questionline=$(getcursor)
    if ask_yn "Do you want to proceed with installation/(re)configuration?"; then
        tput cup $(($questionline - 1)) 0
        clearUp
        cd "$HOME"
        if [ ! -d "klipper-backup" ]; then
            loading_wheel "${Y}●${NC} Installing Klipper-Backup" &
            loading_pid=$!
            git clone https://github.com/Staubgeborener/klipper-backup.git 2>/dev/null
            chmod +x ./klipper-backup/script.sh
            cp ./klipper-backup/.env.example ./klipper-backup/.env
            sleep .5
            kill $loading_pid
            echo -e "\r\033[K${G}●${NC} Installing Klipper-Backup ${G}Done!${NC}\n"
        else
            cd klipper-backup
            if [ "$(git rev-parse HEAD)" = "$(git ls-remote $(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1)" ]; then
                echo -e "${G}●${NC} Klipper-Backup ${G}is up to date.${NC}\n"
            else
                echo -e "${Y}●${NC} Update for klipper-backup ${Y}Available!${NC}\n"
                questionline=$(getcursor)
                if ask_yn "Proceed with update?"; then
                    tput cup $(($questionline - 3)) 0
                    tput ed
                    loading_wheel "${Y}●${NC} Updating Klipper-Backup" &
                    loading_pid=$!
                    if git pull >/dev/null 2>&1; then
                        kill $loading_pid
                        echo -e "\r\033[K${G}●${NC} Updating Klipper-Backup ${G}Done!${NC}\n\n Restarting installation script"
                        sleep 1
                        exec $parent_path/install.sh
                    fi
                else
                    tput cup $(($questionline - 3)) 0
                    clearUp
                    echo -e "${M}●${NC} Klipper-Backup update ${M}Skipped!${NC}\n"
                fi
            fi
        fi
    else
        tput cup $(($questionline - 1)) 0
        clearUp
        echo -e "${R}●${NC} Installation aborted.\n"
        exit 1
    fi
}

configure() {
    ghtoken_username=""
    questionline=$(getcursor)
    if grep -q "github_token=ghp_xxxxxxxxxxxxxxxx" "$parent_path"/.env; then # Check if the github token still matches the value when initially copied from .env.example
        message="Do you want to proceed with configuring the Klipper-Backup .env?"
    else
        message="Do you want to proceed with reconfiguring the Klipper-Backup .env?"
    fi
    if ask_yn "$message"; then
        tput cup $(($questionline - 1)) 0
        clearUp
        pos1=$(getcursor)
        pos2=$(getcursor)

        getToken() {
            ghtoken=$(ask_token "Enter your GitHub token")
            result=$(check_ghToken "$ghtoken") # Check Github Token using github API to ensure token is valid and connection can be estabilished to github
            if [ "$result" != "" ]; then
                sed -i "s/^github_token=.*/github_token=$ghtoken/" "$HOME/klipper-backup/.env"
                ghtoken_username=$result
            else
                tput cup $(($pos2 - 1)) 0
                tput ed
                echo "Invalid Github token or Unable to contact github API, Please re-enter your token and check for valid connection to github.com then try again!"
                pos2=$(getcursor)
                getToken
            fi
        }
        getUser() {
            pos2=$(getcursor)
            ghuser=$(ask_textinput "Enter your github username" "$ghtoken_username")

            menu
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                sed -i "s/^github_username=.*/github_username=$ghuser/" "$HOME/klipper-backup/.env"
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

            menu
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                sed -i "s/^github_repository=.*/github_repository=$ghrepo/" "$HOME/klipper-backup/.env"
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

            menu
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                sed -i "s/^branch_name=.*/branch_name=\"$repobranch\"/" "$HOME/klipper-backup/.env"
                tput cup $pos2 0
                tput ed
            else
                tput cup $(($pos2 - 1)) 0
                tput ed
                getBranch
            fi
        }
        getCommitName() {
            pos2=$(getcursor)
            commitname=$(ask_textinput "Enter desired commit username" "$(whoami)")

            menu
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                sed -i "s/^commit_username=.*/commit_username=\"$commitname\"/" "$HOME/klipper-backup/.env"
                tput cup $pos2 0
                tput ed
            else
                tput cup $(($pos2 - 1)) 0
                tput ed
                getCommitName
            fi
        }
        getCommitEmail() {
            pos2=$(getcursor)
            commitemail=$(ask_textinput "Enter desired commit email" "$(whoami)@$(hostname --short)-$unique_id")

            menu
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                sed -i "s/^commit_email=.*/commit_email=\"$commitemail\"/" "$HOME/klipper-backup/.env"
                tput cup $pos2 0
                tput ed
            else
                tput cup $(($pos2 - 1)) 0
                tput ed
                getCommitEmail
            fi
        }

        while true; do
            set +e
            getToken
            getUser
            getRepo
            getBranch
            getCommitName
            getCommitEmail
            set -e
            break
        done

        tput cup $(($pos1 - 1)) 0
        tput ed
        echo -e "\r\033[K${G}●${NC} Configuration ${G}Done!${NC}\n"
        pos1=$(getcursor)
    else
        tput cup $(($questionline - 1)) 0
        clearUp
        echo -e "\r\033[K${M}●${NC} Configuration ${M}Skipped!${NC}\n"
        pos1=$(getcursor)
    fi
}

patch_klipper-backup_update_manager() {
    questionline=$(getcursor)
    if [[ -d $HOME/moonraker ]] && systemctl is-active moonraker >/dev/null 2>&1; then
        if ! grep -Eq "^\[update_manager klipper-backup\]\s*$" "$HOME/printer_data/config/moonraker.conf"; then
            if ask_yn "Would you like to add klipper-backup to moonraker update manager?"; then
                tput cup $(($questionline - 2)) 0
                tput ed
                pos1=$(getcursor)
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
                echo -e "\r\033[K${G}●${NC} Adding klipper-backup to update manager ${G}Done!${NC}\n"
            else
                tput cup $(($questionline - 2)) 0
                tput ed
                echo -e "\r\033[K${M}●${NC} Adding klipper-backup to update manager ${M}Skipped!${NC}\n"
            fi
        else
            tput cup $(($questionline - 2)) 0
            tput ed
            echo -e "\r\033[K${M}●${NC} Adding klipper-backup to update manager ${M}Skipped! (Already Added)${NC}\n"
        fi
    else
        tput cup $(($questionline - 2)) 0
        tput ed
        echo -e "${R}●${NC} Moonraker is not installed update manager configuration ${R}Skipped!${NC}\n${Y}● Please install moonraker then run the script again to update the moonraker configuration${NC}\n"
    fi
}

install_filewatch_service() {
    questionline=$(getcursor)
    tput cup $(($questionline - 2)) 0
    tput ed
    pos1=$(getcursor)
    loading_wheel "${Y}●${NC} Checking for filewatch service" &
    loading_pid=$!
    if service_exists klipper-backup-filewatch; then
        echo -e "\r\033[K"
        kill $loading_pid
        message="Would you like to reinstall the filewatch backup service? (this will trigger a backup after changes are detected)"
    else
        echo -e "\r\033[K"
        kill $loading_pid
        message="Would you like to install the filewatch backup service? (this will trigger a backup after changes are detected)"
    fi
    if ask_yn "$message"; then
        tput cup $(($questionline - 2)) 0
        tput ed
        pos1=$(getcursor)
        echo -e "${Y}●${NC} Installing latest version of inotify-tools (This may take a few minutes)"
        sudo rm -rf inotify-tools/                              # remove folder incase it for some reason still exists
        sudo rm -f /usr/bin/fsnotifywait /usr/bin/fsnotifywatch # remove symbolic links to keep error about file exists from occurring
        loading_wheel "   ${Y}●${NC} Clone inotify-tools repo" &
        loading_pid=$!
        git clone https://github.com/inotify-tools/inotify-tools.git 2>/dev/null
        kill $loading_pid
        echo -e "\r\033[K   ${G}●${NC} Clone inotify-tools repo ${G}Done!${NC}"
        sudo apt-get install autoconf autotools-dev automake libtool -y >/dev/null 2>&1

        cd inotify-tools/

        buildCommands=("./autogen.sh" "./configure --prefix=/usr" "make" "make install")
        for ((i = 0; i < ${#buildCommands[@]}; i++)); do
            run_command "${buildCommands[i]}"
        done

        cd ..
        sudo rm -rf inotify-tools
        pos2=$(getcursor)
        tput cup $(($pos1 - 1)) 0
        tput ed
        echo -e "\r\033[K${G}●${NC} Installing latest version of inotify-tools ${G}Done!${NC}"
        loading_wheel "${Y}●${NC} Installing filewatch service" &
        loading_pid=$!
        sudo cp $parent_path/install-files/klipper-backup-filewatch.service /etc/systemd/system/klipper-backup-filewatch.service
        sudo sed -i "s/^After=.*/After=$(wantsafter)/" "/etc/systemd/system/klipper-backup-filewatch.service"
        sudo sed -i "s/^Wants=.*/Wants=$(wantsafter)/" "/etc/systemd/system/klipper-backup-filewatch.service"
        sudo sed -i "s/^User=.*/User=${SUDO_USER:-$USER}/" "/etc/systemd/system/klipper-backup-filewatch.service"
        sudo systemctl daemon-reload
        sudo systemctl enable klipper-backup-filewatch.service
        sudo systemctl start klipper-backup-filewatch.service
        sleep .5
        kill $loading_pid
        echo -e "\r\033[K${G}●${NC} Installing filewatch service ${G}Done!${NC}\n"
    else
        tput cup $(($questionline - 2)) 0
        tput ed
        echo -e "\r\033[K${M}●${NC} Installing filewatch service ${M}Skipped!${NC}\n"

    fi
}

install_backup_service() {
    questionline=$(getcursor)
    tput cup $(($questionline - 2)) 0
    tput ed
    pos1=$(getcursor)
    loading_wheel "${Y}●${NC} Checking for on-boot service" &
    loading_pid=$!
    if service_exists klipper-backup-on-boot; then
        echo -e "\r\033[K"
        kill $loading_pid
        message="Would you like to reinstall the on-boot backup service?"
    else
        echo -e "\r\033[K"
        kill $loading_pid
        message="Would you like to install the on-boot backup service?"
    fi
    if ask_yn "$message"; then
        tput cup $(($questionline - 2)) 0
        tput ed
        pos1=$(getcursor)
        loading_wheel "${Y}●${NC} Installing on-boot service" &
        loading_pid=$!
        sudo cp $parent_path/install-files/klipper-backup-on-boot.service /etc/systemd/system/klipper-backup-on-boot.service
        sudo sed -i "s/^After=.*/After=$(wantsafter)/" "/etc/systemd/system/klipper-backup-on-boot.service"
        sudo sed -i "s/^Wants=.*/Wants=$(wantsafter)/" "/etc/systemd/system/klipper-backup-on-boot.service"
        sudo sed -i "s/^User=.*/User=${SUDO_USER:-$USER}/" "/etc/systemd/system/klipper-backup-on-boot.service"
        sudo systemctl daemon-reload
        sudo systemctl enable klipper-backup-on-boot.service
        sudo systemctl start klipper-backup-on-boot.service
        sleep .5
        kill $loading_pid
        echo -e "\r\033[K${G}●${NC} Installing on-boot service ${G}Done!${NC}\n"
    else
        tput cup $(($questionline - 2)) 0
        tput ed
        echo -e "\r\033[K${M}●${NC} Installing on-boot service ${M}Skipped!${NC}\n"
    fi
}

install_cron() {
    questionline=$(getcursor)
    if ! (crontab -l 2>/dev/null | grep -q "$HOME/klipper-backup/script.sh"); then
        if ask_yn "Would you like to install the cron task?"; then
            tput cup $(($questionline - 2)) 0
            tput ed
            pos1=$(getcursor)
            loading_wheel "${Y}●${NC} Installing cron task" &
            loading_pid=$!
            (
                crontab -l 2>/dev/null
                echo "0 */4 * * * $HOME/klipper-backup/script.sh \"Cron backup - \$(date +\"%%x - %%X\")\""
            ) | crontab -
            sleep .5
            kill $loading_pid
            echo -e "\r\033[K${G}●${NC} Installing cron task ${G}Done!${NC}\n"
        else
            tput cup $(($questionline - 2)) 0
            tput ed
            echo -e "\r\033[K${M}●${NC} Installing cron task ${M}Skipped!${NC}\n"
        fi
    else
        tput cup $(($questionline - 2)) 0
        tput ed
        echo -e "\r\033[K${M}●${NC} Installing cron task ${M}Skipped! (Already Installed)${NC}\n"
    fi
}

main
