The FAQ is based on tips and tricks as well as on the most frequently raised issues and questions.

## Fix git errors
We have found that most errors can be traced back to incorrect use of git and that deleting a special Klipper-Backup related folder (config_backup) can solve the problem. So if you encounter strange error messages, please run the script with the `--fix` parameter:

```shell
~/klipper-backup/script.sh --fix
```

## Klipper-Backup with multiple instances
If you use multiple Klipper instances on one device, you can also easily implement this with Klipper-Backup. Let's say you have set up several instances with [KIAUH](https://github.com/dw-0/kiauh):

During setup, KIAUH asks you which custom name you would like to give the respective instance. If you do not assign one, a consecutive index from '1' is simply assigned as the name.
Each instance then gets its own folder under `/home/{username}/`, which follows the syntax `printer_{instance_name}_data`. For example, if an instance is called "voron" the corresponding folder is `/home/{username}/printer_voron_data/`.

**Example**: If you have set up three instances with the names "voron", "prusa-mk4s" and "crealityPRINTER", your `.env` could contain the following section:

```shell
backupPaths=( \
"printer_voron_data/config/*" \
"printer_prusa-mk4s_data/config/*" \
"printer_crealityPRINTER_data/config/*"
)
```

*Hint:* If you don't quite know what the correct paths are: either look in the home directory with `ls ~`. Also the moonraker.conf has a `klippy_uds_address` section with the paths.

## Symolic links
It could be that you find a symbolic link in your GitHub repository (like [this](./images/symbolic_link_GitHub.png)). Or you might get the message `Skipping symbolic link: [...]”`.

**Brief explanation of what symbolic links (also known as symlinks) are:** A symbolic link is a link that leads to a file or folder without moving the original file. This is quite neet, as symbolic links save redundancies because they do not duplicate the actual file or folder, but only refer to the original.
[Long story short](https://github.com/Staubgeborener/Klipper-Backup/issues/69#issuecomment-1965839873): symbolic links are not included in the backup because they are read only.

What you can do now to backup those kind of files: There is a longer version [here](https://github.com/Staubgeborener/Klipper-Backup/issues/121#issuecomment-2345459135).

The tl;dr version:

For example, you could include the original files in the backup instead of the symbolic links. Navigate to the symbolic links and check with `ls -la` where they point to, the output could look like this, for example:
`mmu_leds.cfg -> /home/user/Happy-Hare/config/base/mmu_leds.cfg`

`mmu_leds.cfg` is the symbolic link which points to the original file `/home/user/Happy-Hare/config/base/mmu_leds.cfg`. Now you can include `/home/user/Happy-Hare/config/base/mmu_leds.cfg` directly in your `.env` file to backup the original file.
Messages like `Skipping symbolic link` can be ignored, as this is only of an informative nature. If this still bothers you, you can include the symbolic link in your `.env` file in the `exclude` section.
For more information on how to edit the `.env` exactly, just have a look at [this](./configuration/#paths) and [this](./configuration/#gitignore-do-not-upload-certain-files) article.

## Network / Server error
If you get an error when cloning the Klipper-Backup repository that looks something like this

```shell
remote: Internal Server Error
fatal: unable to access 'https://github.com/Staubgeborener/klipper-backup.git/': The requested URL returned error: XXX
```

Then there are only two reasons: GitHub itself has [issues](https://www.githubstatus.com/), or the reason lies in your internal network. Either way, this has nothing to do with this project.

## Still problems?
If there are still problems, simply open an [issue](https://github.com/Staubgeborener/klipper-backup/issues). Please be sure to use the `--debug` parameter, as it is written there, so that we can understand the error and help you. Also, use [markdown](https://docs.github.com/de/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) syntax to post readable code.
