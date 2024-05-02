G=$'\e[1;92m' # Green
R=$'\e[1;91m' # Red ${R}
NC=$'\e[0m'   # No Color

if [ -d "~/klipper-backup" ]; then
    echo -e "\n${R}●${NC} Klipper-Backup directory already exists. You can run it with ~/klipper-backup/install.sh"
    exit 1
else
    git clone https://github.com/Staubgeborener/klipper-backup.git ~/klipper-backup
    if [ $? -ne 0 ]; then
        echo -e "\n${R}●${NC} Error when cloning the repository. Maybe Klipper-Backup already exists. You can run it with ~/klipper-backup/install.sh.
        exit 1
    fi

    # !!! REMOVE THIS LINE LATER !!!
    git -C ~/klipper-backup checkout installer-beta

    echo -e "\n${G}●${NC} Klipper backup was downloaded successfully! You can now start the installation: ~/klipper-backup/install.sh"
fi
