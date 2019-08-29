#!/bin/bash

default_max=250000
default_retention=14
script_version="1.0.1"

function version_message() {
versionmessage="MacOS Backup v$script_version"
    echo "$versionmessage";
}

function usage () {
usagemessage="usage: $0 -b [user|dot|apps] -u [username] -d [destination] -r [retention] -m [max megabytes]

Options:
    -b Backup Type      :  (Required)
    -u Username         :  (Required if User Home Picked)
    -d Destination      :  (Required)
    -m Max Space (MB)   :  Default: (${default_max})
    -r Retention (Days) :  Default: (${default_retention})
    -h Help             :  Displays Help Information
    -v Version          :  Displays Script Version
"
    version_message
    echo "$usagemessage";
}

function help_message () {
helpmessage="
-----------------------------------------------------------------------------------------------------------------------
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-----------------------------------------------------------------------------------------------------------------------
AUTHOR:       Levon Becker
PURPOSE:      Backup MacOS User Home, Dot files in User Home or Apps.
VERSION:      $script_version
DESCRIPTION:  This script is used to backup your user home and personal settings on a MacOS Devops system,
              or installed Apps, or user dot files and folders
              It has been tested on MacOS 10.14.5, but should work on.
              It should be ran with sudo to have access to some system stuff.
-----------------------------------------------------------------------------------------------------------------------
PARAMETERS
-----------------------------------------------------------------------------------------------------------------------
-b Backup Type (user, dot or apps)
-u Username or home folder name to backup. (Required)
-d Destination backup folder. (Required)
-m Max Space in Megabits. How much maximum space to allow in the destination directory. Default: (${default_max}MB)
-r Retention Days. How long to keep backups in the destination directory. Default: (${default_retention})
-----------------------------------------------------------------------------------------------------------------------
EXAMPLES
-----------------------------------------------------------------------------------------------------------------------
sudo $0 -b apps -d /Volumes/usbdrive/backups/${USER}
sudo $0 -b dot -d /Volumes/usbdrive/backups/${USER}
sudo $0 -b user -u ${USER} -d /Volumes/usbdrive/backups/${USER}
sudo $0 -b user -u ${USER} -d /Volumes/usbdrive/backups/${USER} -r 60 -m 500000
-----------------------------------------------------------------------------------------------------------------------
"
    echo "$helpmessage";
}

while getopts "b:d:m:r:uhv" opts; do
    case $opts in
		b ) backup_type=$OPTARG;;
		d ) destination=$OPTARG;;
		m ) max=$OPTARG;;
		r ) retention=$OPTARG;;
		u ) username=$OPTARG;;
        h ) help_message; exit 0;;
        v ) version_message; exit 0;;
    esac
done

# Condition on Arguments Provided
if [ -z $backup_type ]; then
	usage
	echo "ERROR: Backup Type Missing!"
	exit 1
fi
if [ $backup_type == "user" ]; then
    if [ -z $username ]
    then
        usage
        echo "ERROR: Username not Specified!"
        exit 1
    fi
fi
if [ -z $destination ]; then
	usage
	echo "ERROR: Backup Destination Missing!"
	exit 1
fi
if [ -z $max_space ]; then max_space=$default_max; fi
if [ -z $retention ]; then retention=$default_retention; fi

# endregion Arguments

# Variables
date_time=$(date +%Y%m%d-%H%M)
sourcehostname=$(uname -n | awk -F. '{ print $1 }')
backup_root_path=${destination}/${sourcehostname}
backup_path=${backup_root_path}/${username}/${date_time}
log_file=${backup_path}/${backup_type}_backup.log
#set -u
# read -p "Press any key to continue... " -n1 -s

source ./lib/shared_functions.sh

function backup_apps {
    # Run Backups
    task_title='Backups Apps'
    show_header "${task_title}"

    ## User Directory
    show_message "ACTION: Backing up Home Directory (${backup_path})"
    tar --totals -czf ${backup_path}/user_dir.tgz /Users/${username} 2>&1 | tee -a ${log_file}
    # If a file changes while backing up then you get Exit Code 1 :\
    #exit_check ${PIPESTATUS[0]} 'Backing up Home Folder'
    du -h ${backup_path}/user_dir.tgz | tee -a ${log_file}
    show_message ''

    show_footer "${task_title}"

    # Remove Out-of-Date Backups
    task_title='Removing Out-of-Date Backups and Logs'
    show_header "${task_title}"

    backup_count=$(find ${backup_root_path}/* -mtime +${retention} -type d -exec ls -df {} \; | wc -l)
    if [ ${backup_count} -gt 0 ]
    then
        show_message "REPORT: Found (${backup_count}) out-of-date folders to delete"
        # List Folders That will be Removed
        backup_folders=$(find ${backup_root_path}/* -mtime +${retention} -type d)
        show_message "ACTION: Attempting to Remove the Following Backup Folders:\n${backup_folders}"
        # Remove Old Backups
        find ${backup_root_path}/* -mtime +${retention} -type d -exec rm -vrf {} \;
        # Determine Success
        exit_check $? 'Remove Out-of-Date Folders'
    else
        show_message "REPORT: No Out-of-Date Backups Found"
    fi

    show_footer "${task_title}"
}

function backup_user {
    # Run Backups
    task_title='Backup User Home'
    show_header "${task_title}"

    ## User Directory
    show_message "ACTION: Backing up Home Directory (${backup_path})"
    tar --totals -czf ${backup_path}/user_dir.tgz /Users/${username} 2>&1 | tee -a ${log_file}
    # If a file changes while backing up then you get Exit Code 1 :\
    #exit_check ${PIPESTATUS[0]} 'Backing up Home Folder'
    du -h ${backup_path}/user_dir.tgz | tee -a ${log_file}
    show_message ''

    show_footer "${task_title}"

    # Remove Out-of-Date Backups
    task_title='Removing Out-of-Date Backups and Logs'
    show_header "${task_title}"

    backup_count=$(find ${backup_root_path}/* -mtime +${retention} -type d -exec ls -df {} \; | wc -l)
    if [ ${backup_count} -gt 0 ]
    then
    show_message "REPORT: Found (${backup_count}) out-of-date folders to delete"
    # List Folders That will be Removed
    backup_folders=$(find ${backup_root_path}/* -mtime +${retention} -type d)
    show_message "ACTION: Attempting to Remove the Following Backup Folders:\n${backup_folders}"
    # Remove Old Backups
    find ${backup_root_path}/* -mtime +${retention} -type d -exec rm -vrf {} \;
    # Determine Success
    exit_check $? 'Remove Out-of-Date Folders'
    else
    show_message "REPORT: No Out-of-Date Backups Found"
    fi

    show_footer "${task_title}"
}

function backup_dot_files {
    # Run Backups
    task_title='Backup User Dot Files (WIP)'
    show_header "${task_title}"

    ## User Dot Files
    show_message "ACTION: Backing up Home Directory Dot Files (${backup_path})"
    find $HOME -maxdepth 1 -name ".*" | sort | grep -v .DS_Store | grep -v .Trash | grep -v .cache | grep -v .local | grep -v .Xauthority | tar --totals -czf ${backup_path}/user_dot_files.tgz -T - 2>&1 | tee -a ${log_file}
    # If a file changes while backing up then you get Exit Code 1 :\
    #exit_check ${PIPESTATUS[0]} 'Backing up Home Folder'
    du -h ${backup_path}/user_dot_files.tgz | tee -a ${log_file}
    show_message ''

    show_footer "${task_title}"

    # Remove Out-of-Date Backups
    task_title='Removing Out-of-Date Backups and Logs'
    show_header "${task_title}"

    backup_count=$(find ${backup_root_path}/* -mtime +${retention} -type d -exec ls -df {} \; | wc -l)
    if [ ${backup_count} -gt 0 ]
    then
    show_message "REPORT: Found (${backup_count}) out-of-date folders to delete"
    # List Folders That will be Removed
    backup_folders=$(find ${backup_root_path}/* -mtime +${retention} -type d)
    show_message "ACTION: Attempting to Remove the Following Backup Folders:\n${backup_folders}"
    # Remove Old Backups
    find ${backup_root_path}/* -mtime +${retention} -type d -exec rm -vrf {} \;
    # Determine Success
    exit_check $? 'Remove Out-of-Date Folders'
    else
    show_message "REPORT: No Out-of-Date Backups Found"
    fi

    show_footer "${task_title}"
}

# Run
start_time
create_backup_folder
check_space
if [ $backup_type == "user" ]; then
    backup_user
elif [ $backup_type == "apps" ]; then
    backup_apps
elif [ $backup_type == "dot" ]; then
    backup_dot_files
else
    echo "Error: Missing Backup Type!"
    exit 1
fi
end_time
run_time
exit 0
