# Planning out script process:
# Prompt for repository name, token, branch (optional)
# Prompt for default main branch with last commit date, as well prompt if other branches exist (branch prompt skipped if branch supplied in initial steps)
# pull contents of branch to a temp folder, extract paths from restore.config
# shut down instances of klipper, moonraker etc..
# copy files from temp folder to the respective paths, along with repatching .theme git repo (if applicable)

# Note:
  # use this when creating the restore script to add .theme changes back:
  # git apply $HOME/printer_data/config/klipper-backup-restore/theme_changes.patch