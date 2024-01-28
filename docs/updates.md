## Installation
1. Clone the repo and copy .env.example to .env:
   ```shell
   git clone https://github.com/Staubgeborener/klipper-backup.git && chmod +x ./klipper-backup/script.sh && cp ./klipper-backup/.env.example ./klipper-backup/.env
   ```
2. Navigate into the klipper-backup folder `cd klipper-backup` and edit the .env file: `nano .env` inside .env, edit the following lines:
   ```ini
    github_token=ghp_xxxxxxxxxxxxxxxxxxxx
    github_username=USERNAME
    github_repository=REPOSITORY
   ```
    You will need to get a GitHub token (classic or Fine-grained, either works) just ensure you have set access to the repository and have push/pull & commit permissions.
    For more info on classic and fine-grained PATS, see the following: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens

!!! note "Keep in mind"
    Make sure you note down your access token, as once you close out of the window, you cannot retrieve it again and will have to make a new one.

## Configuration
Next, add your GitHub username and the name of the repository that you are going to create soon.
To save the changes made in nano do `ctrl + s` then `ctrl + x`

  4. Next to create the repository:
     - In the upper-right corner of any page in GitHub, select +, then click New repository.
     - Type a name for your repository, and an optional description.
     - Choose a repository visibility. (You can select either one)
     - Click Create repository.
  5. Run your first backup!
     Run `./script.sh` from within klipper-backup and check that you receive no errors and when checking the repository you should see a new commit.
  6. (Optional but obviously recommended) Automate the process! The most straightforward way will be using `crontab -e` (if it's your first time running the command you will be asked which editor you would like to use, nano is the easiest) once the editor is open for crontab at the very bottom add the line `@reboot $HOME/klipper-backup/script.sh` which will tell cron to run the backup script every system startup. You can find other options and examples here: https://crontab.guru/examples.html or in [this section](https://github.com/Staubgeborener/klipper-backup/wiki/Execute#cron).

## Moonraker update manager
To add this repository to moonraker's update manager for easy updating, you need to add the following into ```moonraker.conf```
*This is just for these repositories updates, not updates of your config backups. Those do not get added to moonraker.
```yaml
[update_manager klipper-backup]
type: git_repo
path: ~/klipper-backup
origin: https://github.com/Staubgeborener/klipper-backup.git
managed_services: klipper
primary_branch: main
```
cat: cat: Datei oder Verzeichnis nicht gefunden
## Moonraker Support
Add this section to your `moonraker.conf` to get latest updates:

```yaml
[update_manager klipper-backup]
type: git_repo
path: ~/klipper-backup
origin: https://github.com/Staubgeborener/klipper-backup.git
managed_services: klipper
primary_branch: main
```

A firmware/machine restart is always good at this point.

***

**How to use:** You can now update `klipper-backup` at any time via moonraker.

Mainsail example: `Machine > Update Manager`

![mainsail-update-manager](https://i.imgur.com/g9KVlN6.png)

## Manual Updates
In case you don't want to use the moonraker update manager, you can update the script by yourself.

If the script is executed (e.g. with `./script.sh`) and a new update is available, you will be notified with the following message
> NEW klipper-backup version available!

To do so:
```shell
cd ~/klipper-backup && git pull
```

!!! note "Keep in mind"
    Editing content inside the `klipper-backup` folder like the `script.sh` folder leads to git error messages which ask you to execute e.g. a `git push` command: Long story short, changing the `script.sh` could lead to problems (also with future updates), so don't do it. If you want a new feature, you are welcome to open a [pull request](https://github.com/Staubgeborener/klipper-backup/pulls) or a [feature request](https://github.com/Staubgeborener/klipper-backup/issues/new?assignees=&labels=feature+request&projects=&template=feature_request.yml&title=%5BFeature+request%5D%3A+).
