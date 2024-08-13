## Moonraker update manager
To add this repository to moonraker's update manager for easy updating, you need to add the following section into ```moonraker.conf```.  
    
!!! warning "Important Note"
    This is just for these repositories updates, not updates of your config backups. Those do not get added to moonraker.

```yaml
[update_manager klipper-backup]
type: git_repo
path: ~/klipper-backup
origin: https://github.com/Staubgeborener/klipper-backup.git
managed_services: moonraker
primary_branch: main
```

Nor you can simply use the Moonraker API which is supplied with Mainsail or Fluidd, for example, to update the Klipper-Backup. Simple one-click update in the browser UI, as easy as it sounds.

## Update via shell/console
If the script is executed (e.g. with `./script.sh`) and a new update is available, you will be notified with the following message
> ● Update for Klipper-Backup available!

The recommended update variant is to start the installation script, which installs the update on request:
```shell
~/klipper-backup/install.sh
```

Otherwise you can `git pull` the latest Klipper-Backup version:
```shell
cd ~/klipper-backup && git pull
```

!!! warning "Important Note" 
    Editing most files (with the exception of .env) inside of the `klipper-backup` folder, can lead to a ['dirty' repository](https://docs.mainsail.xyz/setup/updates/update-manager#dirty){:target="_blank"}, which will cause moonraker or the local git repository to be unable to pull updates until resolved. For Pull requests see [pull request](https://github.com/Staubgeborener/klipper-backup/pulls){:target="_blank"} or you are welcome to open a [feature request](https://github.com/Staubgeborener/klipper-backup/issues){:target="_blank"}.

There are different ways to start your backup, either [manually](manual.md) or [automatically](automation.md).
