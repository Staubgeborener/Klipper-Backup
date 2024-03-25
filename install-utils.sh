# Create unique id for git email
unique_id=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 7 | head -n 1)

parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)

if [[ ! -f .env ]]; then
    cp $parent_path/.env.example $parent_path/.env
fi

wantsafter() {
    if dpkg -l | grep -q '^ii.*network-manager' && systemctl is-active --quiet "NetworkManager"; then
        echo "NetworkManager-wait-online.service"
    else
        echo "network-online.target"
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

# Move cursor up one line and clear the line
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

# Function to move the cursor to a specific position
function move_cursor() {
    echo -e "\033[${1};${2}H"
}

# Function to display the menu and return status codes
function menu() {
    choice=1
    while true; do
        # Highlight the current choice
        if [ $choice -eq 1 ]; then
            echo -e "\e[7m1. Confirm\e[0m"
            echo "2. Re-enter"
        else
            echo "1. Confirm"
            echo -e "\e[7m2. Re-enter\e[0m"
        fi

        read -sn 1 key

        case $key in
        [1-2]) # Number keys 1 and 2
            choice=$key
            ;;
        A) # Up arrow
            if [ $choice -eq 2 ]; then
                ((choice--))
            fi
            ;;
        B) # Down arrow
            if [ $choice -eq 1 ]; then
                ((choice++))
            fi
            ;;
        "") # Enter key
            case $choice in
            1)
                return 0
                ;;
            2)
                return 1
                ;;
            esac
            ;;
        esac

        move_cursor $pos2 0

    done
}

check_ghToken() {
    GITHUB_TOKEN="$1"
    API_URL="https://api.github.com/user"

    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" $API_URL)

    if [[ $response =~ "message" ]]; then
        ghtoken_username=""
        echo $ghtoken_username
    else
        ghtoken_username=$(echo $response | jq -r '.login')
        echo $ghtoken_username
    fi
}

service_exists() {
    if systemctl list-unit-files | grep -q "$1.service"; then
        return 0  # Service exists
    else
        return 1  # Service does not exist
    fi
}