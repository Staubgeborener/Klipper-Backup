# klipper-backup
Klipper backup script for manual or automated backups

This is a backup script to create manual or automated klipper backups in a github repository. You can [see an example](https://github.com/Staubgeborener/3dprint) of what it looks like in the end.

## Installation
...

## Configuration
Initialize the .env file and make the script executable:
```shell
mv .env.example .env
chmod +x script.sh
```

Modify the `.env` file:
1. In GitHub click on the profile in the upper right corner
2. click "Settings"
3. click "Developer settings"
4. click "Personal access tokens"
5. Generate new token

Copy the new token into the `.env` file at `github_token`. Add your username in `github_username` and change the `github_repository` to your backup repository name in GitHub (in my case: [3dprint](https://github.com/Staubgeborener/3dprint/blob/main/.env.example#L3)).

Adjust the remaining paths in the `.env` file where your files are located or add even more file.  All files defined here (note the pattern! It must start with `path_` followed by the path) are considered in the backup. I am using the default paths.

Since i like to sort the files in appropriate folders i have adjusted the parameter `backup_folder` with `./klipper`. You could also use `backup_folder=.` for example.

#### Execute

Thats pretty much it. There are two ways to run the script:
1. Run the script when starting mainsailos respectively the 3d printer. Type `crontab -e` and add this line: `@reboot /home/pi/klipper-backup/script.sh`
2. I created a klipper macro `[gcode_macro update_git]` to run the backup manually in the mainsailos gui (see `printer.cfg`)
A klipper macro can look like this:
```gcode
[gcode_macro update_git]
gcode:
    RUN_SHELL_COMMAND CMD=update_git_script

[gcode_shell_command update_git_script]
command: bash /home/pi/klipper-backup/script.sh
timeout: 90.0
verbose: True
```