# Backup MacOS Scripts
A BASH script to backup a single user home directory, or installed apps or user home dot files.

## Prerequisites
* tee command
    * Should be pre-installed on MacOS

## Setup
1. Clone to system from Github.

  ```git clone https://github.com/bonusbits/backup_macos.git ~/git/```
2. Make script executable

  ```sudo chmod +x ~/git/backup_macos/*.sh```
3. Create Symlink and aliases for shell Scripts in bash profile

```bash
# Backup Scripts
if [ ! -h "/usr/local/bin/backup_macos" ]; then
   ln -s "/path/to/clone/backup_macos/backup.sh" /usr/local/bin/backup_macos
fi
# Examples
alias backupjoe="sudo backup_macos -b user -u jdoe -d /Volumes/usbdrive/Backups -r 60 -m 500000"
alias backupapps="sudo backup_macos -b apps -d /Volumes/usbdrive/Backups/ -r 60 -m 300000"
alias backupapps="sudo backup_macos -b dot -d /Volumes/usbdrive/Backups/ -r 60 -m 10000"
```

## Parameters: backup_macos_user.sh
<table>
  <tr>
    <th>Option</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><tt>-b</tt></td>
    <td>Backup Type. [user|dot|apps] (Required)</td>
  </tr>
  <tr>
    <td><tt>-u</tt></td>
    <td>Username or home folder name to backup. (Required - IF user type selected)</td>
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
    <td><tt>-h</tt></td>
    <td>Display Help</td>
  </tr>
  <tr>
    <td><tt>-v</tt></td>
    <td>Display Version</td>
  </tr>
</table>

## Examples
+ sudo backup_macos_user.sh -u jdoe -d /Volumes/usbdrive/Backups
+ sudo backup_macos_user.sh -u jdoe -d /Volumes/usbdrive/Backups -r 60 -m 500000

---
