#!/bin/bash
echo "Check for updates..."
LocalVersion=$(sed -n 1p version)
LatestVersion=$(curl -Lsk 'https://github.com/Staubgeborener/klipper-backup/raw/main/version')

if [[ $LatestVersion > $LocalVersion ]] ; then
    echo "New version $LatestVersion released! Start update"
    wget https://github.com/Staubgeborener/klipper-backup/releases/download/$LatestVersion/klipper-backup-main.zip
    unzip -o klipper-backup-main.zip
    cp -R ./klipper-backup-main/* $pwd
    rm -rf klipper-backup-main.zip klipper-backup-main
    chmod +x *.sh
else
    echo "You are up-to-date"
fi