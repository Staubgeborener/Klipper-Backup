**This is for users who have used Klipper-Backup before release 1.0.0**

## Manual Migration
The following covers manually migrating your old `.env` file to the new `.env` file.  

1. Go into your home directory: 
```
cd ~
```  
2. Backup your `.env` file: (you can use some of your old information later)  
```
cp ~/klipper-backup/.env .env.backup
```
3. Delete the old klipper-backup folder: 
```
sudo rm -rf ~/klipper-backup ~/config_backup
```  
4. Clone the new klipper-backup version:
```
git clone https://github.com/Staubgeborener/klipper-backup.git && chmod +x ./klipper-backup/script.sh && cp ./klipper-backup/.env.example ./klipper-backup/.env
```  
5. Now use the information from your old `.env.backup` backup file and edit the new `.env` file.
You can still use your old token, for example.
!!! warning
    **DON'T just copy the old `.env` file into the new folder, this will NOT work!**  
    Take a look at how the new paths are structured and read the documentation and notes inside of <a href="https://github.com/Staubgeborener/klipper-backup/blob/main/.env.example" target="_blank">.env.example</a> for more information.

## Semi-Manual Migration
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

The following [gist](https://gist.github.com/Staubgeborener/53be20d08afee07f50bed20ee4d229a4) can be ran with a one line command to perform the migration.

```shell
bash <(curl -sL https://gist.githubusercontent.com/Staubgeborener/53be20d08afee07f50bed20ee4d229a4/raw/0a455f891dc8c843b4964bbb3a0f835d3ad7b43a/klipper-backup-migration.sh)
```

!!!danger
    Be cautious and thoroughly evaluate scripts obtained from external sources. you should always check that the code you are executing is safe no matter who it comes from.