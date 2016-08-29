#!/bin/bash

# region Default Variables

    default_max=250000
    default_retention=14
    script_version="1.0.0 (08/26/2016)"

# endregion Default Variables

# region Version

#function script_version () {
#versionmessage="$script_version"
#    echo "$versionmessage";
#}

# endregion Version

# region Usage

function usage () {
usagemessage="
usage: $0 -u [username] -d [destination] -r [retention] -m [max megabytes]

-u Username         :  (Required)
-d Destination      :  (Required)
-m Max Space (MB)   :  Default: (${default_max})
-r Retention (Days) :  Default: (${default_retention})
"
    echo "$usagemessage";
}

# endregion Usage

# region Help

function help_message () {
helpmessage="
-----------------------------------------------------------------------------------------------------------------------
|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-----------------------------------------------------------------------------------------------------------------------
AUTHOR:       Levon Becker
PURPOSE:      Backup MacOS User.
VERSION:      $script_version
DESCRIPTION:  This script is used to backup your user data and personal settings on a MacOS Devops system.
              It has been tested on MacOS 10.11.6, but should work on.
              It should be ran with sudo to have access to some system stuff.
-----------------------------------------------------------------------------------------------------------------------
PARAMETERS
-----------------------------------------------------------------------------------------------------------------------
-u Username or home folder name to backup. (Required)
-d Destination backup folder. (Required)
-m Max Space in Megabits. How much maximum space to allow in the destination directory. Default: (${default_max}MB)
-r Retention Days. How long to keep backups in the destination directory. Default: (${default_retention})
-----------------------------------------------------------------------------------------------------------------------
EXAMPLES
-----------------------------------------------------------------------------------------------------------------------
sudo $0 -u ${USER} -d /Volumes/usbdrive/backups/${USER}
sudo $0 -u ${USER} -d /Volumes/usbdrive/backups/${USER} -r 60 -m 500000
-----------------------------------------------------------------------------------------------------------------------
"
    echo "$helpmessage";
}

# endregion Help

# region Arguments

	while getopts "d:m:r:u:h" opts; do
	    case $opts in
			d ) destination=$OPTARG;;
			m ) max=$OPTARG;;
			r ) retention=$OPTARG;;
			u ) username=$OPTARG;;
	        h ) help_message; exit 0;;
	    esac
	done

	# Condition on Arguments Provided
	if [ -z $username ]
	then
		usage
		echo "ERROR: Username not Specified!"
		exit 1
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
log_file=${backup_path}/backup.log
#set -u
# read -p "Press any key to continue... " -n1 -s

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

# Create Backup Folder if Needed
## If path is not created, can't write to log file. Thus can't use functions that output to console and log.
## So outputting this step only to console.
echo -e "\n--------------------------------------------------------------------------------"
echo "BEGIN: Create Backup Folder"
echo "--------------------------------------------------------------------------------"
if [ ! -d ${backup_path} ]
then
	echo 'ACTION: Creating Backup Folder'
	mkdir -p ${backup_path}
	exit_check_nolog $? "Creating Backup Folder"
else
	echo "ERROR: Backup Folder Already Exists (${backup_path})"
	exit 1
fi
echo "REPORT: Backup Root Path ${backup_root_path}"
echo "REPORT: Backup Path ${backup_path}"
echo "--------------------------------------------------------------------------------"
echo "END:   Checking Backup Folder Exists"
echo "--------------------------------------------------------------------------------"

# Start Time
## Has to be after backup path is created for log file used by show_message
start_time=$(date +%s)
echo ''
show_message "STARTTIME: ($(date))"

# Check Space
task_title='Check Backup Space'
show_header "${task_title}"
used_space_mb=$(du -sm ${backup_root_path} | awk '{print $1}')
show_message "REPORT: Backup Destination Directory (${backup_path})"
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

# Run Backups
task_title='Run Backups'
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

# End Time
end_time=$(date +%s)
show_message ''
show_message "ENDTIME: ($(date))"

# Run Time
elapsed=$(( (${end_time} - ${start_time}) / 60 ))
show_message "RUNTIME: ${elapsed} minutes"
exit 0
