#!/bin/bash

LatestVersion=$(curl -Lsk 'https://github.com/Staubgeborener/klipper-backup-staging/raw/main/version')
color=$'\e[1;36m'
end=$'\e[0m'

Klipper-Backup-Logo() {
    echo -e "${color}
 _    _  _                           _              _                  ________
| |_ | ||_| ___  ___  ___  ___  ___ | |_  ___  ___ | |_  _ _  ___     | |____| |
| '_|| || || . || . || -_||  _||___|| . || .'||  _|| '_|| | || . |    |  (__)  |
|_,_||_||_||  _||  _||___||_|       |___||__,||___||_,_||___||  _|    |        |
           |_|  |_|                                          |_|      |________|
    ${end}"
}

installation() {
    wget https://github.com/Staubgeborener/klipper-backup-staging/releases/download/$LatestVersion/klipper-backup-main.zip
    unzip -o klipper-backup-main.zip
    cp -R ./klipper-backup-main/* $(pwd)
    rm -rf klipper-backup-main klipper-backup-main.zip README.md
    chmod +x *.sh
    echo -e "\n${color}Finished! Now edit the .env file. You can find more details in the README.md file on Github: https://github.com/Staubgeborener/klipper-backup#configuration${end}"
}

updates() {
    LocalVersion=$(sed -n 1p version)
    if [[ $LatestVersion > $LocalVersion ]] ; then
        echo -e "${color}New version $LatestVersion released! Start update${end}\n"
        installation
    else
        echo "You are up-to-date"
    fi
}

Klipper-Backup-Logo
if [[ ! -e "version" ]]; then
    echo -e "${color}Start installation...${end}\n"
    installation
else
    echo "Check for updates..."
    updates
fi