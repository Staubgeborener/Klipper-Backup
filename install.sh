#!/bin/bash
echo "Check for updates..."
LocalVersion=$(sed -n 1p version)
LatestVersion=$(curl -Lsk 'https://github.com/Staubgeborener/klipper-backup/raw/main/version')

if [[ $LatestVersion > $LocalVersion ]] ; then
    echo "New version $LatestVersion released! Start update"
    wget https://github.com/Staubgeborener/klipper-backup/releases/download/$LatestVersion/files.zip
    unzip -o files.zip
    cp -R ./files/* $pwd
    rm -rf files.zip files
    chmod +x *.sh
else
    echo "You are up-to-date"
fi