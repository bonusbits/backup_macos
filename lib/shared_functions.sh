#!/bin/bash

# Shared Functions
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

function start_time {
  # Start Time
  ## Has to be after backup path is created for log file used by show_message
  start_time=$(date +%s)
  echo ''
  show_message "STARTTIME: ($(date))"
}

function end_time {
  # End Time
  end_time=$(date +%s)
  show_message ''
  show_message "ENDTIME: ($(date))"
}

function run_time {
  # Run Time
  elapsed=$(( (${end_time} - ${start_time}) / 60 ))
  show_message "RUNTIME: ${elapsed} minutes"
}

function create_backup_folder {
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
}

function check_space {
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
}
