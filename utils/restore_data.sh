# Planning out script process:
# Prompt for repository name, token, branch (optional)
# Prompt for default main branch with last commit date, as well prompt if other branches exist (branch prompt skipped if branch supplied in initial steps)
# pull contents of branch to a temp folder, extract paths from restore.config
# shut down instances of klipper, moonraker etc..
# copy files from temp folder to the respective paths, along with repatching .theme git repo (if applicable)

# Note:
# use this when creating the restore script to add .theme changes back:
# git apply $HOME/printer_data/config/klipper-backup-restore/theme_changes.patch

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
# restore_folder="$HOME"/printer_data/klipper-backup-restore
# restore_config="$restore_folder"/restore.config
# theme_path="$HOME"/printer_data/config/.theme

main() {
    clear
    sudo -v
    dependencies
    logo
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