## git
You need [git](https://git-scm.com/download/linux){:target="_blank"} for this script.

**Debian / Ubuntu based distributions**
```shell
sudo apt update && sudo apt install git
```

**Arch / Manjaro based distributions**
```shell
sudo pacman -Syu && sudo pacman -S git
```

## Prepare GitHub repository
1. Log in to GitHub
2. Click on the `+` in the upper right corner
3. Click on "New repository"

!!!danger 
    Don't create a `README.md` at this point! You can create your own later.

![create-github-repository](https://i.imgur.com/pMKBQWt.png)

The most important part in the next window is here to give the repository a name, you will need this later.

## Create GitHub token
1. In GitHub, click on the profile in the upper right corner
2. click `Settings`
3. click `Developer settings`
4. click `Personal access tokens` (you can choose a classic token or a fine-grained token, doesn't really matter)
5. `Generate new token`

Copy the new token, you will need this later.

## Download Klipper-Backup
```shell
curl -fsSL https://raw.githubusercontent.com/Staubgeborener/klipper-backup/download/get-klipper-backup.sh | bash
```

## Run installation
Start the installation: 
```shell
~/klipper-backup/install.sh
```

The installation script guides you through the essential steps. Have your [GitHub token](installation.md#create-github-token) ready for this. You can decide during the installation whether you want to install some features like [backup on boot](automation.md#backup-on-boot), [backup on file changes](automation.md#backup-on-file-changes), or even add the [moonraker entry](updating.md#moonraker-update-manager), etc (this can also be done afterwards).

!!! info
    You can run the `install.sh` script at any time to install any features!

[Now edit your `.env` file](configuration.md).
