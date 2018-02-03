#!/bin/bash

# Default Variables
default_max=100000
default_retention=14
script_version='1.1.0-20161101'
users_only=false
run_without_prompt=false

function version_message() {
versionmessage="Backup macOS: $script_version"
    echo "$versionmessage";
}

# TODO: Add Sync to Raw uncompressed folders and skip other logic? or put in another script? (Using rsync)

function usage () {
usagemessage="
usage: $0 -d [destination] -r [retention] -m [max megabytes]

-d Destination      :  (Required)
-m Max Space (MB)   :  Default: ($default_max)
-r Retention (Days) :  Default: ($default_retention)
-h Help
-v Display Version  :  $script_version
-u Users Only       :  Default: ($users_only)
-y Skip Prompt      :  Do not prompt
"
    echo "$usagemessage";
}

function help_message () {
helpmessage="
-----------------------------------------------------------------------------------------------------------------------
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-----------------------------------------------------------------------------------------------------------------------
AUTHOR:       Levon Becker
PURPOSE:      Backup MacOS Apps and User Home Directories.
VERSION:      $script_version
DESCRIPTION:  This script can be used to backup all Applications on a MacOS system.
              It has been tested on MacOS 10.11.6, but should work on most versions.
              It should be ran with sudo to have full access.
-----------------------------------------------------------------------------------------------------------------------
PARAMETERS
-----------------------------------------------------------------------------------------------------------------------
-d Destination backup folder. The full path will be created if missing. (Required)
-m Max Space in Megabits. How much maximum space to allow in the destination directory. Default: (${default_max}MB)
-r Retention Days. How long to keep backups in the destination directory. Default: (${default_retention})
-v Display Version
-u Switch to only backup user home directories and not applications directory
-y Backup without pausing at header
-----------------------------------------------------------------------------------------------------------------------
EXAMPLES
-----------------------------------------------------------------------------------------------------------------------
sudo $0 -d /Volumes/usbdrive/backups
sudo $0 -y -d /Volumes/usbdrive/backups -r 60 -m 500000
sudo $0 -y -u -d /Volumes/usbdrive/backups -r 60 -m 500000
-----------------------------------------------------------------------------------------------------------------------
"
    echo "$helpmessage";
}

# Argument Parser
while getopts "d:m:r:uyvh" opts; do
    case $opts in
        d ) destination=$OPTARG;;
        m ) max=$OPTARG;;
        r ) retention=$OPTARG;;
        u ) users_only=true; exit 0;;
        y ) run_without_prompt=true; exit 0;;
        v ) version_message; exit 0;;
        h ) help_message; exit 0;;
    esac
done

# Condition on Arguments Provided
if [ -z $destination ]; then
    usage
    echo "ERROR: Backup Destination Missing!"
    exit 1
fi
if [ -z $max_space ]; then max_space=$default_max; fi
if [ -z $retention ]; then retention=$default_retention; fi

function set_variables {
    date_time=$(date +%Y%m%d-%H%M)
    sourcehostname=$(uname -n | awk -F. '{ print $1 }')
    backup_root_path=${destination}/${sourcehostname}
    apps_backup_path=${backup_root_path}/Applications/${date_time}
    users_backup_path=${backup_root_path}/Users/${date_time}
    apps_log_file=${apps_backup_path}/backup.log
    users_log_file=${users_backup_path}/backup.log
    #set -u
    # read -p "Press any key to continue... " -n1 -s
}

# Functions
function show_header {
	echo -e "\n--------------------------------------------------------------------------------" | tee -a ${log_file}
	echo "BEGIN: $1" | tee -a ${log_file}
	echo "--------------------------------------------------------------------------------" | tee -a ${log_file}
}

function show_footer {
	echo "--------------------------------------------------------------------------------" | tee -a ${log_file}
	echo "END:   $1" | tee -a ${log_file}
	echo "--------------------------------------------------------------------------------" | tee -a ${log_file}
}

function show_message {
	printf "$1\n" | tee -a ${log_file}
}

function exit_check {
	if [ $1 -eq 0 ]
	then
		echo "SUCCESS: $2" | tee -a ${log_file}
	else
		echo "ERROR: Exit Code $1 for $2" | tee -a ${log_file}
		exit $1
	fi
}

function exit_check_nolog {
	if [ $1 -eq 0 ]
	then
		echo "SUCCESS: $2"
	else
		echo "ERROR: Exit Code $1 for $2"
		exit $1
	fi
}

function check_space {
    # Check Space
    task_title='Check Backup Space'
    show_header "${task_title}"
    used_space_mb=$(du -sm ${backup_root_path} | awk '{print $1}')
    show_message "REPORT: Backup Destination Directory (${apps_backup_path})"
    show_message "REPORT: Space Before Backup in MB: $used_space_mb"
    if [ ${used_space_mb} -le ${max_space} ]
    then
      show_message 'REPORT: Space OK'
      show_footer "${task_title}"
    else
      show_message 'ERROR: Over Space Limit!'
      show_footer "${task_title}"
      exit 1
    fi
    # read -p "Press any key to continue... " -n1 -s
}

function create_backup_folder {
    # Create Backup Folder if Needed
    ## If path is not created, can't write to log file.
    ## Thus can't use functions that output to console and log.
    ## So outputting this step only to console.
    echo -e "\n--------------------------------------------------------------------------------"
    echo "BEGIN: Create Backup Folder"
    echo "--------------------------------------------------------------------------------"
    if [ ! -d ${1} ]
    then
        echo 'ACTION: Creating Backup Folder'
        mkdir -p ${1}
        exit_check_nolog $? "Creating Backup Folder"
    else
        echo "ERROR: Backup Folder Already Exists ($1)"
        exit 1
    fi
    echo "REPORT: Backup Root Path $backup_root_path"
    echo "REPORT: Backup Path $1"
    echo "--------------------------------------------------------------------------------"
    echo "END:   Checking Backup Folder Exists"
    echo "--------------------------------------------------------------------------------"
}

function backup_data {
    task_title=${1}
    show_header "$task_title"
    show_message "ACTION: Backing up Applications ($2)"
    tar --totals -czf ${2}/apps_dir.tgz ${3} 2>&1 | tee -a ${4}
    # If a file changes while backing up then you get Exit Code 1 :\
    #exit_check ${PIPESTATUS[0]} 'Backing up Home Folder'
    du -h ${2}/apps_dir.tgz | tee -a ${4}
    show_message ''
    show_footer "$task_title"
}

function remove_old_backups {
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

# Start
set_variables
create_backup_folder ${users_backup_path}


# Start Time
## Has to be after backup path is created for log file used by show_message
start_time=$(date +%s)
show_header "Backup Process"
show_message ''
show_message "STARTTIME: ($(date))"

# Check Space
check_space

# Run Users Backup
backup_data 'Backing up Applications' ${users_backup_path} '/Users' ${users_log_file}

if [ "$users_only" = "false" ]; then
    # Run Applications Backup
    create_backup_folder ${apps_backup_path}
    backup_data 'Backing up Applications' ${apps_backup_path} '/Applications' ${app_log_file}
fi

# TODO: Set ownership on files and folders to current user on USB

# Remove Out-of-Date Backups
remove_old_backups

# End Time
end_time=$(date +%s)
show_message ''
show_message "ENDTIME: ($(date))"

# Results
elapsed=$(( (${end_time} - ${start_time}) / 60 ))
show_message "RUNTIME: ${elapsed} minutes"
show_footer "Backup Process"
exit 0
