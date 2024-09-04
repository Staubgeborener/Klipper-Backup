This is a section for alternative methods for running the script and automating/manual backups

## Command-Line Arguments
If `script.sh` is executed in the terminal, Command-Line Arguments are available:

| Argument                 | Description                                                                                 | Example                                                                                |
| ------------------------ | ------------------------------------------------------------------------------------------- |--------------------------------------------------------------------------------------- |
| `-h`, `--help`           | Display the help page and exit                                                              | `script.sh --help` or `script.sh -h`                                                   |
| `-c`, `--commit_message` | Use your own commit message for the git push                                                | `script.sh --commit_message "my commit message"` or `script.sh -c "my commit message"` |
| `-f`, `--fix`            | Delete the config_backup folder. This can help to solve the vast majority of error messages | `script.sh --fix` or `script.sh -f`                                                    |
| `-d`, `--debug`          | Output debugging information                                                                | `script.sh --debug` or `script.sh -d`                                                  |

## Timed Backups using systemd
For those with distros that may not include cron in the base packages you can use the following to setup timed backups instead

1. Create a timer unit file at `/etc/systemd/system/klipper-backup.timer` with the following:
```shell
[Unit]
Description=Run klipper backup script every 4 hours

[Timer]
OnBootSec=300s
OnUnitActiveSec=4hr

[Install]
WantedBy=timers.target
```

2. Create a service file at ```/etc/systemd/system/klipper-backup.service``` with the following:
```shell
[Unit]
Description=Klipper Backup On-boot Service
#Uncomment below lines if using network manager
After=NetworkManager-wait-online.service
Wants=NetworkManager-wait-online.service
#Uncomment below lines if not using network manager
#After=network-online.target
#Wants=network-online.target

[Service]
User=<REPLACE_WITH_YOUR_USERNAME>
Type=oneshot
ExecStart=/bin/bash -c 'bash $HOME/klipper-backup/script.sh -c "New Backup on timer - $(date +"%%x - %%X")"'

[Install]
WantedBy=default.target
```
3. Run `sudo systemctl daemon-reload` once both files have been created.
4. Enable the systemd timer `sudo systemctl enable --now klipper-backup.timer`. The timer will run the service file every 4 hours. 
!!! note
    if you would like to edit the time between backups you can edit line 5 `OnUnitActiveSec=` to your specified time.
