G=$'\e[1;92m' # Green
R=$'\e[1;91m' # Red ${R}
C=$'\e[96m'   # Cyan ${C}
NC=$'\e[0m'   # No Color

echo -e "${C}$(
    cat <<"EOF"
    __ __ ___                             ____             __
   / //_// (_)___  ____  ___  _____      / __ )____ ______/ /____  ______
  / ,<  / / / __ \/ __ \/ _ \/ ___/_____/ __  / __ `/ ___/ //_/ / / / __ \
 / /| |/ / / /_/ / /_/ /  __/ /  /_____/ /_/ / /_/ / /__/ ,< / /_/ / /_/ /
/_/ |_/_/_/ .___/ .___/\___/_/        /_____/\__,_/\___/_/|_|\__,_/ .___/
         /_/   /_/                                               /_/
EOF
)${NC}"
echo ""
echo "==============================================================================================================="
echo ""

if [ -d ~/klipper-backup ]; then
    echo -e "\n${R}●${NC} Klipper-Backup directory already exists. You can run it with ~/klipper-backup/install.sh"
    exit 1
else
    git clone https://github.com/Staubgeborener/klipper-backup.git ~/klipper-backup
    if [ $? -ne 0 ]; then
        echo -e "\n${R}●${NC} Error when cloning the repository. Maybe Klipper-Backup already exists. You can run it with ~/klipper-backup/install.sh"
        exit 1
    fi

    # !!! REMOVE THIS LINE LATER !!!
    git -C ~/klipper-backup checkout installer-beta

    echo -e "\n${G}●${NC} Klipper backup was downloaded successfully! You can now start the installation: ~/klipper-backup/install.sh"
fi
