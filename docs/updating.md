## Moonraker update manager
To add this repository to moonraker's update manager for easy updating, you need to add the following into ```moonraker.conf```
*This is just for these repositories updates, not updates of your config backups. Those do not get added to moonraker.
```yaml
[update_manager klipper-backup]
type: git_repo
path: ~/klipper-backup
origin: https://github.com/Staubgeborener/klipper-backup.git
managed_services: moonraker
primary_branch: main
```

## Update via shell/console

If the script is executed (e.g. with `./script.sh`) and a new update is available, you will be notified with the following message
> Klipper-backup is not up to date, consider making a git pull to update

To pull the update navigate to the klipper-backup folder and run `git pull`:
```shell
cd ~/klipper-backup && git pull
```

!!! warning "Keep in mind" 
    Editing most files (with the exception of .env) inside of the `klipper-backup` folder, can lead to a 'dirty' repository, which will cause moonraker or the local git repository to be unable to pull updates until resolved. See [How to contribute](contribute.md) for how you should setup your dev enviorment for creating a [pull request](https://github.com/Staubgeborener/klipper-backup/pulls) or you are welcome to open a [feature request](https://github.com/Staubgeborener/klipper-backup/issues).
