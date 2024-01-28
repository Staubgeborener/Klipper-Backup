**This is for users who have used Klipper-Backup before release 1.0**

The steps are very clear:

1. Go into your home directory: `cd ~`

2. Backup you `.env`: `cp ~/klipper-backup/.env ~` (you can use some old information later)

3. Delete the old klipper-backup folder: `sudo rm -r ~/klipper-backup`

4. Clone the new klipper-backup version: `git clone https://github.com/Staubgeborener/klipper-backup.git && chmod +x ./klipper-backup/script.sh && cp ./klipper-backup/.env.example ./klipper-backup/.env`

5. Now use the information from your old `.env` backup file and edit the new `.env` file. You can still use your old token, for example. **But please be patient about the new `.env` syntax! DON'T just copy the old `.env` file into the new folder, this will NOT work!** Just look how your old `.env` looks `cat ~/.env`, the new one `cat ~/klipper-backup/.env` and read [this section](configuration.md/#env)

***

A simple script could be something like this
```shell
#!/bin/bash
cd ~
cp ~/klipper-backup/.env ~
sudo rm -r ~/klipper-backup
git clone https://github.com/Staubgeborener/klipper-backup.git && chmod +x ./klipper-backup/script.sh && cp ./klipper-backup/.env.example ./klipper-backup/.env

old_github_token=$(grep "^github_token=" ~/.env | cut -d '=' -f2)
old_github_username=$(grep "^github_username=" ~/.env | cut -d '=' -f2)
old_github_repository=$(grep "^github_repository=" ~/.env | cut -d '=' -f2)

sed -i "s/github_token=.*/github_token=$old_github_token/" ~/klipper-backup/.env
sed -i "s/github_username=.*/github_username=$old_github_username/" ~/klipper-backup/.env
sed -i "s/github_repository=.*/github_repository=$old_github_repository/" ~/klipper-backup/.env

echo -e "$(tput setaf 1)NOW EDIT THE PATH_ PARAMETERS IN YOUR NEW .env !$(tput sgr0)"
```
I have created a [gist](https://gist.github.com/Staubgeborener/53be20d08afee07f50bed20ee4d229a4) with this script, so you can run it automatically with the following command:
```shell
bash <(curl -sL https://gist.githubusercontent.com/Staubgeborener/53be20d08afee07f50bed20ee4d229a4/raw/0a455f891dc8c843b4964bbb3a0f835d3ad7b43a/klipper-backup-migration.sh)
```
