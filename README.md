# Backup MacOS Scripts
A BASH script to backup user home directories and Applications. 
Optional switch to only backup user home directories.

## Prerequisites
* tee command
    * Should be pre-installed on MacOS

## Setup
1. Clone to system from Github.

  ```git clone https://github.com/bonusbits/backup_macos.git /path/to/clone/```
2. Make script executable (if needed)

  ```sudo chmod +x /path/to/clone/backup_macos/backup_macos.sh```
3. Create Symlink and aliases for shell Scripts in bash profile

```bash
# Backup Scripts
if [ ! -h "/usr/local/bin/backupmacos" ]; then
   ln -s "/path/to/clone/backup_macos/backup_macos.sh" /usr/local/bin/backupmacos
fi
alias backupmacos-all="sudo backupmacos -d /Volumes/usbdrive/Backups -r 60 -m 500000"
alias backupmacos-users="sudo backupmacos -u -d /Volumes/usbdrive/Backups -r 60 -m 500000"
```

## Parameters
<table>
  <tr>
    <th>Option</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><tt>-u</tt></td>
    <td>Only backup Users</td>
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
  <tr>
    <td><tt>-v</tt></td>
    <td>Display Script Version</td>
  </tr>
  <tr>
    <td><tt>-h</tt></td>
    <td>Display Help</td>
  </tr>
</table>

## Examples
+ sudo backup_macos.sh -d /Volumes/usbdrive/Backups
+ sudo backup_macos.sh -u -d /Volumes/usbdrive/Backups -r 60 -m 500000


---
