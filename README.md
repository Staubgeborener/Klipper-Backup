# klipper-backup 💾
Klipper backup script for manual or automated GitHub backups

This is a backup script to create manual or automated klipper backups in a github repository. You can [see an example](https://github.com/Staubgeborener/3dprint) of what it looks like in the end.

## Installation
  1. Glone the repo and copy .env.example to .env:
     `git clone https://github.com/Tylerjet/klipper-backup.git && cp ./klipper-backup/.env.example ./klipper-backup/.env`
  2. navigate into the klipper-backup folder `cd klipper-backup` and edit the .env file: `nano .env` inside of .env, edit the following lines:
     ```
      github_token=ghp_xxxxxxxxxxxxxxxxxxxx
      github_username=USERNAME
      github_repository=REPOSITORY
     ```
      You will need to get a github token (classic or Fine-grained, either works) just ensure you have set access to the repository and have push/pull & commit permissions.
      For more info on classic and fine grained PATS see the following: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens

     ### *Make sure you note down your access token as once you close out of the window, you cannot retrieve it again and will have to make a new one.

      Next, add your github username and the name of the repository that you are going to create soon.
      To save the changes made in nano do `ctrl + s` then `ctrl + x`

  4. Next to create the repository:
     - In the upper-right corner of any page in github, select +, then click New repository.
     - Type a name for your repository, and an optional description.
     - Choose a repository visibility. (You can select either one)
     - Click Create repository.
  5. Run your first backup!
     run `./script.sh` from within klipper-backup and check that you recieve no errors and when checking the repository you should see a new commit.
  6. (Optional but obviously recommended) Automate the process! The most straightforward way will be using `crontab -e` (if it's your first time running the command you will be asked which editor you would like to use, nano is the easiest) once the editor is open for crontab at the very bottom add the line `0 */6 * * * $HOME/klipper-backup/script.sh` which will tell cronitor to run the backup script every 6 hours. You can find other options and examples here: https://crontab.guru/examples.html

## Moonraker update manager
To add the repo to moonraker's update manager you need to add the following into ```moonraker.conf```
```
[update_manager client klipper-backup]
type: git_repo
path: ~/klipper-backup
origin: https://github.com/Tylerjet/klipper-backup.git
is_system_service: False
primary_branch: main
```

## YouTube
The user [Minimal 3DP](https://github.com/minimal3dp) has created a video about the initial setup and use of klipper-backup and made it available on YouTube. This and the wiki should explain many questions in advance.

[![The Ultimate Guide to Using Klipper Macros to Backup Your Configuration Files](https://img.youtube.com/vi/fR2jIegqv3A/0.jpg)](https://www.youtube.com/watch?v=fR2jIegqv3A "The Ultimate Guide to Using Klipper Macros to Backup Your Configuration Files")
