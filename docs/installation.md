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

## Install klipper-backup
```shell
cd ~ && git clone https://github.com/Staubgeborener/klipper-backup.git && chmod +x ./klipper-backup/script.sh && cp ./klipper-backup/.env.example ./klipper-backup/.env
```

[Now edit your `.env` file](configuration.md).
