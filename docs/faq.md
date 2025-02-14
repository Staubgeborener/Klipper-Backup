## Klipper Backup with multiple instances
If you use multiple Klipper instances on one device, you can also easily implement this with Klipper backup. Let's say you have set up several instances with [KIAUH](https://github.com/dw-0/kiauh):

During setup, KIAUH asks you which custom name you would like to give the respective instance. If you do not assign one, a consecutive index from '1' is simply assigned as the name.
Each instance then gets its own folder under `/home/{username}/`, which follows the syntax `printer_{instance_name}_data`. For example, if an instance is called "voron" the corresponding folder is `/home/{username}/printer_voron_data/`.

**Example**: If you have set up three instances with the names "voron", "prusa-mk4s" and "crealityPRINTER", your `.env` could contain the following section:

```
backupPaths=( \
"printer_voron_data/config/*" \
"printer_prusa-mk4s_data/config/*" \
"printer_crealityPRINTER_data/config/*"
)
```

*Hint:* If you don't quite know what the correct paths are: either look in the home directory with `ls ~`. Also the moonraker.conf has a `klippy_uds_address` section with the paths.

## Troubleshooting
### Fix git errors
We have found that most errors can be traced back to incorrect use of git and that deleting a special Klipper-Backup related folder (config_backup) can solve the problem. So if you encounter strange error messages, please run the script with the `--fix` parameter:
```shell
~/klipper-backup/script.sh --fixfix-giut
```

### Still problems?
If there are still problems, simply open an [issue](https://github.com/Staubgeborener/klipper-backup/issues). Please be sure to use the `--debug` parameter, as it is written there, so that we can understand the error and help you. Also, use [markdown](https://docs.github.com/de/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) syntax to post readable code.
