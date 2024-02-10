There are a couple different methods for automating backups you can choose to use one/both or none its up to you.

## Backup on boot
1. Create the service file in systemd
```shell 
sudo nano /etc/systemd/system/klipper-backup.service
```  
2. Copy and paste the below text (be sure to uncomment the correct `after=` and `wants=` lines based on if your linux install is using network manager)  
```shell
[Unit]
Description=Klipper Backup Service
#Uncomment below lines if using network manager
#After=NetworkManager-wait-online.service
#Wants=NetworkManager-wait-online.service
#Uncomment below lines if not using network manager
#After=network-online.target
#Wants=network-online.target

[Service]
User={replace with your username}
Type=oneshot
ExecStart=/bin/bash -c 'bash $HOME/klipper-backup/script.sh "New Backup on boot $(date +%%D)"'

[Install]
WantedBy=default.target
```
3. Reload the service daemon, enable the service and start the service
```
sudo systemctl daemon-reload
sudo systemctl enable klipper-backup.service
sudo systemctl start klipper-backup.service
```

## Cron
You can also use cron jobs for scheduling backups.
!!! note
    While there is a `@reboot` option for cron jobs, creating the service from [above](#backup-on-boot) is a better approach for backups on boot. The service can be set to wait for your network to be online before attemping a backup where the cronjob will not and you will need to add a sleep command based on how long it takes for the network to become available.  

1. Edit the crontab file using:
```
crontab -e
```  

    !!! info
        if it's your first time running the command you will be asked which editor you would like to use, nano is the easiest  

2. Once the editor is open, at the very bottom of the file add the line:
```
0 */4 * * * $HOME/klipper-backup/script.sh
```
This tells cron to run the backup script every 4 hours. You can find other cron examples here: <a href="https://crontab.guru/examples.html" target="_blank">https://crontab.guru/examples.html</a>
