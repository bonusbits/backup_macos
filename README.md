# Backup MacOS Scripts
A BASH script to backup a single user data and personal settings.
Another BASH script to backup all the applications.

## Prerequisites
* tee command
    * Should be pre-installed on MacOS

## Setup
1. Clone to system from Github.<br>
  ```git clone https://github.com/bonusbits/macos_backup_scripts.git ~/git/```
2. Make script executable<br>
  ```sudo chmod +x ~/git/macos_backup_scripts/*.sh```

## Parameters: backup_macos_user.sh
<table>
  <tr>
    <th>Option</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><tt>-u</tt></td>
    <td>Username or home folder name to backup. (Required)</td>
  </tr>
  <tr>
    <td><tt>-d</tt></td>
    <td>Destination backup folder. (Required)</td>
  </tr>
  <tr>
    <td><tt>-m</tt></td>
    <td>Max Space in Megabits. How much maximum space to allow in the destination directory. Default: (250000MB)</td>
  </tr>
  <tr>
    <td><tt>-r</tt></td>
    <td>Retention Days. How long to keep backups in the destination directory. Default: (14)</td>
  </tr>
</table>

## Examples
+ sudo backup_macos_user.sh -u jdoe -d /Volumes/usbdrive/Backups
+ sudo backup_macos_user.sh -u jdoe -d /Volumes/usbdrive/Backups -r 60 -m 500000

## Parameters: backup_macos_apps.sh
<table>
  <tr>
    <th>Option</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><tt>-d</tt></td>
    <td>Destination backup folder. (Required)</td>
  </tr>
  <tr>
    <td><tt>-m</tt></td>
    <td>Max Space in Megabits. How much maximum space to allow in the destination directory. Default: (250000MB)</td>
  </tr>
  <tr>
    <td><tt>-r</tt></td>
    <td>Retention Days. How long to keep backups in the destination directory. Default: (14)</td>
  </tr>
</table>

## Examples
+ sudo backup_macos_apps.sh -d /Volumes/usbdrive/Backups
+ sudo backup_macos_apps.sh -d /Volumes/usbdrive/Backups -r 60 -m 500000

---
