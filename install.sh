#!/usr/bin/env bash

set -e

parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)

# Create unique id for git email
unique_id=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 7 | head -n 1)

if [[ ! -f .env ]]; then
    cp $parent_path/.env.example $parent_path/.env
fi

wantsafter() {
    if dpkg -l | grep -q '^ii.*network-manager' && systemctl is-active --quiet "NetworkManager"; then
        echo "NetworkManager-wait-online.service"
    else
        echo"network-online.target"
    fi
}

loading_wheel() {
    local frames="/ - \\ |"
    local delay=0.1

    while :; do
        for frame in $frames; do
            echo -n -e "\r$1 $frame"
            sleep $delay
        done
    done
}

getcursor() {
    local pos

    IFS='[;' read -p $'\e[6n' -d R -a pos -rs || echo "failed with error: $? ; ${pos[*]}"
    echo "${pos[1]}"
}

run_command() {
    command=$1
    loading_wheel "   ${Y}●${NC} Running $command" &
    loading_pid=$!
    sudo $command >/dev/null 2>&1
    kill $loading_pid
    echo -e "\r\033[K   ${G}●${NC} Running $command ${G}Done!${NC}"
}

clearUp() {
    echo -e "\r\033[K\033[1A"
}

R=$'\e[1;91m' # Red ${R}
G=$'\e[1;92m' # Green ${G}
Y=$'\e[1;93m' # Yellow ${Y}
M=$'\e[1;95m' # Magenta ${M}
C=$'\e[96m'   # Cyan ${C}
NC=$'\e[0m'   # No Color ${NC}

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
    echo ""
    echo "==============================================================================================================="
    echo ""
}

ask_yn() {
    while true; do
        read -rp "$1 (yes/no, default is yes): " answer
        case $answer in
        [Yy]* | "") return 0 ;;
        [Nn]*) return 1 ;;
        *) ;;
        esac
    done
}

ask_token() {
    local prompt="$1: "
    local input=""
    echo -n "$prompt" >&2
    stty -echo # Disable echoing of characters
    while IFS= read -rs -n 1 char; do
        if [[ $char == $'\0' || $char == $'\n' ]]; then
            break
        fi
        input+=$char
        echo -n "*" >&2 # Explicitly echo asterisks to stderr
    done
    stty echo # Re-enable echoing
    echo >&2  # Move to a new line after user input
    echo "$input"
}

ask_textinput() {
    if [ -n "$2" ]; then
        read -rp "$1 (default is $2): " input
        echo "${input:-$2}"
    else
        read -rp "$1: " input
        echo "$input"
    fi
}

install_repo() {
    questionline=$(getcursor)
    if ask_yn "Do you want to proceed with the installation/(re)configuration?"; then
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
                        exec "$0"
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

pos1=""
configure() {
    questionline=$(getcursor)
    if ask_yn "Do you want to proceed with (re)configuring Klipper-Backup?"; then
        tput cup $(($questionline - 1)) 0
        clearUp
        pos1=$(getcursor)
        ghtoken=$(ask_token "Enter your github token")
        ghuser=$(ask_textinput "Enter your github username")
        ghrepo=$(ask_textinput "Enter your repository name")
        repobranch=$(ask_textinput "Enter your desired branch name" "main")
        commitname=$(ask_textinput "Enter desired commit username" "$(whoami)")
        commitemail=$(ask_textinput "Enter desired commit email" "$(whoami)@$(hostname --short)-$unique_id")
        #echo "Set token: $ghtoken"
        sed -i "s/^github_token=.*/github_token=$ghtoken/" "$HOME/klipper-backup/.env"
        #echo "Set Username: $ghuser"
        sed -i "s/^github_username=.*/github_username=$ghuser/" "$HOME/klipper-backup/.env"
        #echo "Set Repo Name: $ghrepo"
        sed -i "s/^github_repository=.*/github_repository=$ghrepo/" "$HOME/klipper-backup/.env"
        #echo "Set branch: $repobranch"
        sed -i "s/^branch_name=.*/branch_name=\"$repobranch\"/" "$HOME/klipper-backup/.env"
        #echo "Set commit username: $commitname"
        sed -i "s/^commit_username=.*/commit_username=\"$commitname\"/" "$HOME/klipper-backup/.env"
        #echo "Set commit email: $commitemail"
        sed -i "s/^commit_email=.*/commit_email=\"$commitemail\"/" "$HOME/klipper-backup/.env"
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
        if ask_yn "Would you like to add klipper-backup to moonraker update manager?"; then
            tput cup $(($questionline - 2)) 0
            tput ed
            pos1=$(getcursor)
            loading_wheel "${Y}●${NC} Adding klipper-backup to update manager" &
            loading_pid=$!
            if ! grep -Eq "^\[update_manager klipper-backup\]\s*$" "$HOME/printer_data/config/moonraker.conf"; then
                ### add new line to conf if it doesn't end with one
                if [[ $(tail -c1 "$HOME/printer_data/config/moonraker.conf" | wc -l) -eq 0 ]]; then
                    echo "" >>"$HOME/printer_data/config/moonraker.conf"
                fi

                if /usr/bin/env bash -c "cat >> $HOME/printer_data/config/moonraker.conf" <<MOONRAKER_CONF; then

[update_manager klipper-backup]
type: git_repo
path: ~/klipper-backup
origin: https://github.com/Staubgeborener/klipper-backup.git
managed_services: moonraker
primary_branch: main
MOONRAKER_CONF
                    sudo systemctl restart moonraker.service
                fi
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
        echo -e "${R}●${NC} Moonraker is not installed update manager configuration ${R}Skipped!${NC}\n${Y}● Please install moonraker then run the script again to update the moonraker configuration${NC}\n"
    fi
}

install_filewatch_service() {
    questionline=$(getcursor)
    if ask_yn "Would you like to install the filewatch backup service? (this will trigger a backup after changes are detected)"; then
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
        echo -e "\r\033[K${G}●${NC} Installing latest version of inotify-tools ${G}Done!${NC}"
        tput ed
        tput cup $(($pos1 - 1)) 0
        loading_wheel "${Y}●${NC} Installing filewatch service" &
        loading_pid=$!
        sudo /usr/bin/env bash -c "cat > /etc/systemd/system/klipper-backup-filewatch.service" <<KLIPPER_SERVICE
[Unit]
Description=Klipper Backup Filewatch Service
After=$(wantsafter)
Wants=$(wantsafter)

[Service]
User=$(whoami)
Type=simple
ExecStart=/usr/bin/env bash  -c ' \\
    watchlist=""; \\
    while IFS= read -r path; do \\
        for file in \$path; do \\
            if [ ! -h "\$file" ]; then \\
                file_dir=\$(dirname "\$file"); \\
                if [ "\$file_dir" = "." ]; then \\
                    watchlist+=" \$HOME/\$file"; \\
                else \\
                    watchlist+=" \$HOME/\$file_dir"; \\
                fi; \\
            fi; \\
        done; \\
    done < <(grep -v '^#' "\$HOME/klipper-backup/.env" | grep 'path_' | sed 's/^.*=//'); \\
    watchlist=\$(echo "\$watchlist" | tr \\' \\' \\'\n\\' | sort -u | tr \\'\n\\' \\' \\'); \\
    exclude_pattern=".swp|.tmp|printer-[0-9]*_[0-9]*.cfg|.bak|.bkp"; \\
    inotifywait -mrP -e close_write -e move -e delete --exclude "\$exclude_pattern" \$watchlist | \\
    while read -r path event file; do \\
        if [ -z \$file ]; then \\
            file=\$(basename "\$path"); \\
        fi; \\
        echo "Event Type: \$event, Watched Path: \$path, File Name: \$file"; \\
        file=\$file /usr/bin/env bash -c '\\''/usr/bin/env bash  $HOME/klipper-backup/script.sh "\$file modified - \$(date +\\"%%x - %%X\\")"'\\'' > /dev/null 2>&1; \
    done'

[Install]
WantedBy=default.target
KLIPPER_SERVICE
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
    if ask_yn "Would you like to install the on-boot backup service?"; then
        tput cup $(($questionline - 2)) 0
        tput ed
        pos1=$(getcursor)
        loading_wheel "${Y}●${NC} Installing on-boot service" &
        loading_pid=$!
        sudo /usr/bin/env bash -c "cat > /etc/systemd/system/klipper-backup-on-boot.service" <<KLIPPER_SERVICE
[Unit]
Description=Klipper Backup On-boot Service
After=$(wantsafter)
Wants=$(wantsafter)

[Service]
User=$(whoami)
Type=oneshot
ExecStart=/usr/bin/env bash  -c "/usr/bin/env bash $HOME/klipper-backup/script.sh \"New Backup on boot - \$(date +\"%%x - %%X\")\""

[Install]
WantedBy=default.target
KLIPPER_SERVICE
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
    if ask_yn "Would you like to install the cron task?"; then
        tput cup $(($questionline - 2)) 0
        tput ed
        pos1=$(getcursor)
        loading_wheel "${Y}●${NC} Installing cron task" &
        loading_pid=$!
        if ! (crontab -l 2>/dev/null | grep -q "$HOME/klipper-backup/script.sh"); then
            (
                crontab -l 2>/dev/null
                echo "0 */4 * * * $HOME/klipper-backup/script.sh \"Cron backup - \$(date +\"%%x - %%X\")\""
            ) | crontab -
        fi
        sleep .5
        kill $loading_pid
        echo -e "\r\033[K${G}●${NC} Installing cron task ${G}Done!${NC}\n"
    else
        tput cup $(($questionline - 2)) 0
        tput ed
        echo -e "\r\033[K${M}●${NC} Installing cron task ${M}Skipped!${NC}\n"
    fi
}

logo
install_repo
configure
patch_klipper-backup_update_manager
install_filewatch_service
install_backup_service
install_cron
echo -e "${G}●${NC} Installation Complete!\n"
