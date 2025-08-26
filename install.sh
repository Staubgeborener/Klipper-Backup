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
set -e

main() {
    clear
    sudo -v
    dependencies
    logo
    install_repo
    configure
    configure_printer_paths
    patch_klipper-backup_update_manager
    install_filewatch_service
    install_backup_service
    install_cron
    echo -e "${G}●${NC} Installation Complete!\n  For help or further information, read the docs: https://klipperbackup.xyz"
}

dependencies() {
    loading_wheel "${Y}●${NC} Checking for installed dependencies" &
    loading_pid=$!
    check_dependencies "jq" "curl" "rsync"
    kill $loading_pid
    echo -e "\r\033[K${G}●${NC} Checking for installed dependencies ${G}Done!${NC}\n"
    sleep 1
}

install_repo() {
    if [[ $EUID -eq 0 || $USER == "root" ]]; then
        echo -e "${R}You are logged in as root. It is recommended that you cancel the installation with CTRL+C and log in as a non-privileged user first.\nInstalling as root can lead to problems and is not intended.${NC}\n"
    fi

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
            check_updates
        fi
    else
        tput cup $(($questionline - 1)) 0
        clearUp
        echo -e "${R}●${NC} Installation aborted.\n"
        exit 1
    fi
}

check_updates() {
    cd ~/klipper-backup
    if [ "$(git rev-parse HEAD)" = "$(git ls-remote $(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1)" ]; then
        echo -e "${G}●${NC} Klipper-Backup ${G}is up to date.${NC}\n"
    else
        echo -e "${Y}●${NC} Update for Klipper-Backup ${Y}Available!${NC}\n"
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
            else
                kill $loading_pid
                echo -e "\r\033[K${R}●${NC} Error Updating Klipper-Backup: Repository is dirty running git reset --hard then restarting script"
                sleep 1
                git reset --hard 2>/dev/null
                exec $parent_path/install.sh
            fi
        else
            tput cup $(($questionline - 3)) 0
            clearUp
            echo -e "${M}●${NC} Klipper-Backup update ${M}skipped!${NC}\n"
        fi
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
            echo -e "See the following for how to create your token: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens (Ensure you set access to the backup repository and have push/pull & commit permissions for the token) \n"
            ghtoken=$(ask_token "Enter your GitHub token")
            result=$(check_ghToken "$ghtoken") # Check Github Token using github API to ensure token is valid and connection can be estabilished to github
            if [ "$result" != "" ]; then
                sed -i "s/^github_token=.*/github_token=$ghtoken/" "$HOME/klipper-backup/.env"
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

        tput cup $(($questionline - 1)) 0
        tput ed
        echo -e "\r\033[K${G}●${NC} Configuration ${G}Done!${NC}\n"
        pos1=$(getcursor)
    else
        tput cup $(($questionline - 1)) 0
        clearUp
        echo -e "\r\033[K${M}●${NC} Configuration ${M}skipped!${NC}\n"
        pos1=$(getcursor)
    fi
}

configure_printer_paths() {
    questionline=$(getcursor)

    printer_dirs=()
    if [ -d "$HOME/printer_data" ]; then
        printer_dirs+=("$HOME/printer_data")
    fi

    for dir in "$HOME"/printer_*_data; do
        if [ -d "$dir" ]; then
            printer_dirs+=("$dir")
        fi
    done

    if [ ${#printer_dirs[@]} -eq 0 ]; then
        echo -e "${Y}●${NC} No Klipper instances found, ${Y}skipping path configuration.${NC}\n"
        return
    fi

    if ask_yn "Configure printer data backup? (Found ${#printer_dirs[@]} directories)"; then
        tput cup $(($questionline - 1)) 0
        clearUp

        sed -i '/^backupPaths=(/,/^)/d' "$HOME/klipper-backup/.env"

        echo "backupPaths=( \\" >> "$HOME/klipper-backup/.env"

        selected_paths=()

        for dir in "${printer_dirs[@]}"; do
            dir_name=$(basename "$dir")
            pos1=$(getcursor)

            if ask_yn "Include ${dir_name} in backup? This will default to backing up $dir/config/, but can be modified in the .env file"; then
                tput cup $(($pos1 - 1)) 0
                clearUp
                echo -e "${G}●${NC} Including ${dir_name} ${G}in backup${NC}"
                selected_paths+=("$dir")

                # Add the path to .env file
                echo "\"$dir/config/*\" \\" >> "$HOME/klipper-backup/.env"
            else
                tput cup $(($pos1 - 1)) 0
                clearUp
                echo -e "${M}●${NC} Excluding ${dir_name} ${M}from backup${NC}"
            fi
        done

        # Remove trailing backslash from last entry and close array
        if [ ${#selected_paths[@]} -gt 0 ]; then
            sed -i '$ s/ \\$//' "$HOME/klipper-backup/.env"
        fi
        echo ")" >> "$HOME/klipper-backup/.env"

        echo -e "\n${G}●${NC} Klipper data backup configuration ${G}Done!${NC} (${#selected_paths[@]} directories selected)\n"

        # Store selected paths for moonraker configuration
        export SELECTED_PRINTER_PATHS=("${selected_paths[@]}")
    else
        tput cup $(($questionline - 1)) 0
        clearUp
        echo -e "${M}●${NC} Printer data backup configuration ${M}skipped!${NC}\n"
    fi
}

get_moonraker_instances() {
    moonraker_instances=()

    if [[ -d $HOME/moonraker ]] && systemctl is-active moonraker >/dev/null 2>&1; then
        moonraker_instances+=("moonraker:$HOME/printer_data/config/moonraker.conf")
    fi

    for service_file in /etc/systemd/system/moonraker-*.service; do
        if [[ -f "$service_file" ]]; then
            service_name=$(basename "$service_file" .service)
            instance_name=${service_name#moonraker-}

            if systemctl is-active "$service_name" >/dev/null 2>&1; then
                if [[ -f "$HOME/printer_${instance_name}_data/config/moonraker.conf" ]]; then
                    moonraker_instances+=("$service_name:$HOME/printer_${instance_name}_data/config/moonraker.conf")
                elif [[ -f "$HOME/printer_data_${instance_name}/config/moonraker.conf" ]]; then
                    moonraker_instances+=("$service_name:$HOME/printer_data_${instance_name}/config/moonraker.conf")
                fi
            fi
        fi
    done
}

patch_klipper-backup_update_manager() {
    questionline=$(getcursor)
    get_moonraker_instances

    if [ ${#moonraker_instances[@]} -eq 0 ]; then
        tput cup $(($questionline - 2)) 0
        tput ed
        echo -e "${R}●${NC} No active moonraker instances found, update manager configuration ${R}skipped!${NC}\n${Y}● Please install moonraker then run the script again to update the moonraker configuration${NC}\n"
        return
    fi

    if ask_yn "Configure Klipper-Backup for moonraker update manager? (Found ${#moonraker_instances[@]} instances)"; then
        tput cup $(($questionline - 1)) 0
        clearUp

        selected_instances=()

        for instance in "${moonraker_instances[@]}"; do
            service_name="${instance%%:*}"
            config_path="${instance##*:}"

            pos1=$(getcursor)

            if grep -Eq "^\[update_manager klipper-backup\]\s*$" "$config_path" 2>/dev/null; then
                echo -e "${M}●${NC} ${service_name} ${M}already configured, skipping${NC}"
                continue
            fi

            if ask_yn "Add Klipper-Backup to ${service_name} update manager?"; then
                tput cup $(($pos1 - 1)) 0
                clearUp
                echo -e "${G}●${NC} Selected ${service_name} ${G}for update manager${NC}"
                selected_instances+=("$instance")
            else
                tput cup $(($pos1 - 1)) 0
                clearUp
                echo -e "${M}●${NC} Skipped ${service_name} ${M}update manager${NC}"
            fi
        done

        if [ ${#selected_instances[@]} -gt 0 ]; then
            pos1=$(getcursor)
            loading_wheel "${Y}●${NC} Adding Klipper-Backup to update manager" &
            loading_pid=$!

            for instance in "${selected_instances[@]}"; do
                service_name="${instance%%:*}"
                config_path="${instance##*:}"

                if [[ $(tail -c1 "$config_path" 2>/dev/null | wc -l) -eq 0 ]]; then
                    echo "" >> "$config_path"
                fi

                cat "$parent_path/install-files/moonraker.conf" >> "$config_path"

                sudo systemctl restart "$service_name.service"
            done

            kill $loading_pid
            echo -e "\r\033[K${G}●${NC} Adding Klipper-Backup to update manager ${G}Done!${NC} (${#selected_instances[@]} instances configured)\n"
        else
            echo -e "${M}●${NC} No instances selected for update manager configuration\n"
        fi
    else
        tput cup $(($questionline - 1)) 0
        clearUp
        echo -e "${M}●${NC} Update manager configuration ${M}skipped!${NC}\n"
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
        set +e

        if ! checkinotify >/dev/null 2>&1; then # Checks if the version of inotify installed matches the latest release
            removeOldInotify
            echo -e "${Y}●${NC} Installing latest version of inotify-tools (This may take a few minutes)"
            sudo rm -rf inotify-tools/ # remove folder incase it for some reason still exists
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
            set -e
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
                    echo -e "\r\033[K${R}●${NC} Installing filewatch service took to long to complete!\n"
                    kill $!
                    kill $loading_pid
                    exit 1
                fi

                sleep 1
            done
        ); then
            echo -e "\r\033[K${G}●${NC} Installing filewatch service ${G}Done!${NC}\n"
        fi
    else
        tput cup $(($questionline - 2)) 0
        tput ed
        echo -e "\r\033[K${M}●${NC} Installing filewatch service ${M}skipped!${NC}\n"

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
                    echo -e "\r\033[K${R}●${NC} Installing on-boot service took to long to complete!\n"
                    kill $!
                    kill $loading_pid
                    exit 1
                fi

                sleep 1
            done
        ); then
            echo -e "\r\033[K${G}●${NC} Installing on-boot service ${G}Done!${NC}\n"
        fi
    else
        tput cup $(($questionline - 2)) 0
        tput ed
        echo -e "\r\033[K${M}●${NC} Installing on-boot service ${M}skipped!${NC}\n"
    fi
}

install_cron() {
    questionline=$(getcursor)
    if [ -x "$(command -v cron)" ]; then
        if ! (crontab -l 2>/dev/null | grep -q "$HOME/klipper-backup/script.sh"); then
            if ask_yn "Would you like to install the cron task? (automatic backup every 4 hours)"; then
                tput cup $(($questionline - 2)) 0
                tput ed
                pos1=$(getcursor)
                loading_wheel "${Y}●${NC} Installing cron task" &
                loading_pid=$!
                (
                    crontab -l 2>/dev/null
                    echo "0 */4 * * * $HOME/klipper-backup/script.sh -c \"Cron backup - \$(date +'\\%x - \\%X')\""
                ) | crontab -
                sleep .5
                kill $loading_pid
                echo -e "\r\033[K${G}●${NC} Installing cron task ${G}Done!${NC}\n"
            else
                tput cup $(($questionline - 2)) 0
                tput ed
                echo -e "\r\033[K${M}●${NC} Installing cron task ${M}skipped!${NC}\n"
            fi
        else
            tput cup $(($questionline - 2)) 0
            tput ed
            echo -e "\r\033[K${M}●${NC} Installing cron task ${M}skipped! (already Installed)${NC}\n"
        fi
    else
        tput cup $(($questionline - 2)) 0
        tput ed
        echo -e "\r\033[K${M}●${NC} Installing cron task ${M}skipped! (cron is not installed on system)${NC}\n"
    fi
}

if [ "$1" == "check_updates" ]; then
    check_updates
else
    main
fi
