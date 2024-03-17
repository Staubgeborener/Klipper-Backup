## Shell
Just start the script manually via the shell.

```shell
~/klipper-backup/script.sh
```

The script automatically uses the current timestamp as the commit message and automatic determines the format for the timestamp based on the timezone (America: month/day/year, otherwise: day/month/year). If you want to customize this, you can call the script as follows `~/klipper-backup/script.sh "my commit message"`.

## Klipper macro
I created a klipper macro `[gcode_macro update_git]` to run the backup manually in the mainsailos gui. This requires the [G-Code Shell Command Extension](https://github.com/th33xitus/kiauh/blob/master/docs/gcode_shell_command.md) which you can get very easily through [KIAUH](https://github.com/th33xitus/kiauh).
A klipper macro can look like this:
```yaml
[gcode_macro update_git]
gcode:
    {% if params.MESSAGE|default("") != "" %}
        RUN_SHELL_COMMAND CMD=update_git_script PARAMS="{params.MESSAGE}"
    {% else %}
        RUN_SHELL_COMMAND CMD=update_git_script
    {% endif %}

[gcode_shell_command update_git_script]
# replace /home/pi/ with your actual directory.

command: bash /home/pi/klipper-backup/script.sh
timeout: 90.0
verbose: True

```

For a custom commit message using the klipper macro in console, type `update_git MESSAGE="YourMessage"`.
***
![klipper-backup-macro-image](https://i.imgur.com/UglWf6t.png)
