## .env
Now you need your [GitHub token](installation#create-github-token).

1. Open the `.env` file inside your repository (for example with `vi`, `vim` or `nano`)
2. Copy the new token into the `.env` file at `github_token`
3. Add your username in `github_username`
4. Change the `github_repository` to your backup repository name in GitHub (which was called `repository-name`)
5. The parameter `commit_username=""` and `commit_email=""` are optional. You can change the commit username for the commit history here, for example `commit_username="backup user"`, if it is left empty, the script will use `whoami` for the current user

Adjust the remaining paths in the `.env` file where your files are located, or add even more file. All files defined here (**note the pattern!** It must start with `path_` followed by the path) are considered in the backup. I am using the default paths. You can also comment out content inside the `.env` file with `#`, for example this here will use `path_klipperdata` but ignores `path_macroscfg`:
```ini
path_klipperdata=printer_data/config/*
#path_macroscfg=printer_data/macros/*
```

For example: Since I like to sort the files in appropriate folders, I have adjusted the parameter `backup_folder` with `klipper`. In this case, all klipper files are stored inside a folder which is called `klipper`.

It's also possible to back up whole directories instead of single files. To do so, the part in the `.env` file has to look like this:
```ini
path_klipperdata=printer_data/config/*
```
This will back up all files inside the `printer_data` folder. If you are interested in subfolders, read [this Q&A](https://github.com/Staubgeborener/klipper-backup/wiki/Questions-and-Answers#question-i-want-to-push-folders-recursively-with-subfolders-how-does-it-work).

To back up a single file, use this syntax:
```ini
path_singlefile=printer_data/config/singlefile.cfg
```

## .gitignore
There is also another hidden file which is called `.gitignore`. All filenames mentioned here will not be included in the backup and thus not uploaded to GitHub. This is important because you do not want to have sensitive data like passwords, tokens, etc. in a public backup. This also means that this file prevents your token from being [revoked](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation#token-revoked-when-pushed-to-a-public-repository-or-public-gist).
By default, the `.env` file and the `secrets.conf` are included in the `.gitignore` and can be extended accordingly.

## How can I edit files in terminal?

So let's say you want to use `nano` as your editor of choice (you can use whatever editor you want, for example `vi`, `nvim`, `emacs`, etc) to edit the `.env` file with your personal information:
1. Move into the `klipper-backup` directory: `cd ~/klipper-backup`
2. Check if there is a hidden `.env` file inside this directory: `ls -la` (if not, pretty sure you didn't do what was described in the [wiki](https://github.com/Staubgeborener/klipper-backup/wiki/Installation#choose-the-way-of-implementation))
3. Edit `.env` content with `nano`: `nano .env`
4. Move with your arrow keys ↑ ← ↓ → to the important lines and copy/paste the important content inside (often the right mouse button is used to paste in ssh terminals)
5. Save content and exit `nano` with `^X` (which means `CTRL+X`) -> `(Y)ES` -> `[Enter]`

A small `nano` YouTube tutorial can be found [here](https://youtu.be/mE2YghYpBBE?t=57).

Next: [The update section](updating.md)
