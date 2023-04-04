#!/bin/bash

shopt -s extglob  # enable extglob

LatestVersion=$(curl -Lsk 'https://github.com/Staubgeborener/klipper-backup/raw/main/version')
if [[ ! -e "version" ]]; then
    version="Latest release: v"${LatestVersion}
else
    LocalVersion=$(sed -n 1p version)
    version="v"${LocalVersion}
fi

color=$'\e[1;36m'
end=$'\e[0m'

Klipper-Backup-Logo() {
    echo -e "${color}
 _    _  _                           _              _                  ________
| |_ | ||_| ___  ___  ___  ___  ___ | |_  ___  ___ | |_  _ _  ___     | |____| |
| '_|| || || . || . || -_||  _||___|| . || .'||  _|| '_|| | || . |    |  (__)  |
|_,_||_||_||  _||  _||___||_|       |___||__,||___||_,_||___||  _|    |        |
           |_|  |_|                                          |_|      |________|
    ${version}${end}"
}

installation() {
    cd ~
    wget https://github.com/Staubgeborener/klipper-backup/releases/download/$LatestVersion/klipper-backup-main.zip
    unzip -o klipper-backup-main.zip
    if [ -d ~/klipper-backup ]; then
        cp ./klipper-backup-main/!(.env) ./klipper-backup
    else
        mv klipper-backup-main klipper-backup
        cp ./klipper-backup/.env.example ./klipper-backup/.env
    fi
    cd ./klipper-backup && chmod +x *.sh
    rm -rf ../klipper-backup-main ../klipper-backup-main.zip README.md
}

updates() {
    if [[ $LatestVersion > $LocalVersion ]] ; then
        echo -e "${color}New version $LatestVersion released! Start update:${end}\n"
        installation
    else
        echo "You are up-to-date"
    fi
}

Klipper-Backup-Logo

if [[ ! -e "version" ]]; then
    echo -e "\n${color}Start installation...${end}\n"
    installation
    echo -e "\n${color}Finished! Now edit the .env file. You can find more details in the README.md file on Github: https://github.com/Staubgeborener/klipper-backup#configuration${end}"
else
    echo "Check for updates..."
    updates
fi
