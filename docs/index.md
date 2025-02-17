<h1 style="margin-bottom:0;">Welcome to Klipper-Backup wiki</h1>
<h6 style="margin-top:0;">Klipper-Backup is a script for manual or automated Klipper GitHub backups. It's lightweight, pragmatic and comfortable.</h6>  

This documentation provides a complete step-by-step guide to set up [Klipper-Backup 💾](https://github.com/Staubgeborener/klipper-backup). This guide is specified for the implementation on a Unix system.

## Getting started
To get started with Klipper-Backup, please jump to the [installation section](installation.md) to see detailed instructions.

```shell
curl -fsSL get.klipperbackup.xyz | bash
~/klipper-backup/install.sh
```
!!! warning 
    There is currently **NO** restore functionality on the release/main branch of klipper-backup. That feature is work in progress. Running script.sh on a brand new machine will not restore files.

## Features
- The script does the most complex work in the background automatically
- Works perfectly with [gcode macros](manual.md/#klipper-macro)
- Can also be executed [manually in the terminal](manual.md/#shell)
- Supports [Command-Line Arguments](alternative-methods.md/#command-line-arguments)
- Automatic backups with [cron](automation.md/#cron) or a service that [reacts to file changes](automation.md/#backup-on-file-changes)
- Switch between repositories and branches at any time
- Fully customizable with [parameters](configuration.md)

## FAQ
Before you open an issue on GitHub or ask somewhere: Please take a quick look at the [FAQ](faq.md). For example, there is [this article](faq.md/#fix-git-errors) that solves most of the problems directly.

## Media
![type:video](https://www.youtube.com/embed/47qV9BE2n_Y)

![type:video](https://www.youtube.com/embed/J4_dlCtZY48)

## Contributors
<p>Thank you to everyone who has contributed to the project!</p>
<a href="https://github.com/staubgeborener/klipper-backup/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=staubgeborener/klipper-backup" />
</a>

Made with [contrib.rocks](https://contrib.rocks).
