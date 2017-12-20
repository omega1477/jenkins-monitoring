#!/bin/bash

##########################################################################################
# Jenkins Master and Backup Server Monitoring
#
# Prerequisites
# 1. Current server must have the access for both Jenkins master and backup server
# 2. The listed shell script below must exist in both Jenkins master and backup server
#    i.  jenkins_sync.sh
#    ii. buildnumber_sync.sh
#    iii.activate_scheduler.sh
#    iv. deactivate_scheduler.sh
# 3. curl command tool must be installed
#
# Process
# 1. Determine which server is running as master Jenkins server
# 2. Check the default master Jenkins server status
# 3. Synchronize the setting to backup server if master server is in good health condition
# 4. Switch the role in between master and backup if the master server is dead
# 5. When master server respawn
#    i.  Safe exit Jenkins service at backup server
#    ii. Sychronize the setting from backup server to master server
#    iii.Switch the role in between master and backup
#    iv. Reactivate backup server in standby mode
# 6. Update status to log file
#
# Author:
#  Chua Chee Ann <chuaca@sg.ibm.com>
# Date:
#  2017-Dec-04
##########################################################################################

echo " "
echo "Checking Jenkins Status..."
lastTrack=$( tail -n 1 jenkins_monitoring.log )
IFS=' ' read -r -a array <<<"$lastTrack"
master=${array[-3]}
backup=${array[-2]}
swap=${array[-1]}
timestamp=$(date)
JENKINS_EMAIL=bpmbuild@sg.ibm.com
JENKINS_PASS=t3stc0balt1
JENKINS_URL=https://itaas-build.sby.ibm.com:9443/
JENKINS_DEFAULT_MASTER=9.45.126.230
JENKINS_DEFAULT_BACKUP=9.45.126.123

# Check the current running server
# $swap == false -> the role never swap, default master server is running
# $swap == true -> the role has been swapped, backup server is running

# If $swap == true, check default master server has respawned or not
# If Yes
# 1. Wait for backup server existing builds to be completed then stop the service
# 2. Remote access to default master jenkins server and synchronize with the backup server
# 3. Remote access to default backup jenkins server and restart the service, deactivate scheduler to turn it to standby mode
# 4. Change the role and update the status & log file
#
# If No
# 1. Update the current status to log file
#
# If $swap == false, check default master server is running Jenkins service
# If Yes
# 1. Remote access to default backup jenkins server and synchonize the latest setting
# 2. Deactivate default backup jenkins server scheduler to ensure it always on standby mode
# 3. Update the current status to log file
#
# If No
# 1. Remote access to default backup jenkins server and activate it
# 2. Change the role and update the status & log file

status=$(curl -s -o /dev/null -I -k -u "$JENKINS_EMAIL":"$JENKINS_PASS" -w "%{http_code}" $JENKINS_URL)
#status=404
if [ "$swap" = true ]; then
    if [[ $status -eq 200 ]]; then
        echo "Status=200"
        curl -X POST -k -u "$JENKINS_EMAIL":"$JENKINS_PASS"  https://itaas-build-2.sby.ibm.com:9443/safeExit
        status=$(curl -s -o /dev/null -I -k -u "$JENKINS_EMAIL":"$JENKINS_PASS" -w "%{http_code}" $JENKINS_URL)
        while [[[ $status -eq 200 ]]
        do
            status=$(curl -s -o /dev/null -I -k -u "$JENKINS_EMAIL":"$JENKINS_PASS" -w "%{http_code}" $JENKINS_URL)
        done
        ssh jenkins@$JENKINS_DEFAULT_MASTER <<-EOF
                sh jenkins_sync.sh
                sh buildnumber_sync.sh
                sudo systemctl restart jenkins
        EOF
        ssh jenkins@$JENKINS_DEFAULT_BACKUP <<-EOF
                sh deactivate_scheduler.sh
        EOF
        [ $swap = true ] &&  swap=false || swap=true
        tmp=$master
        master=$backup
        backup=$tmp
    fi
else
    if [[ $status -eq 200 ]]; then
        ssh jenkins@$JENKINS_DEFAULT_BACKUP <<-EOF
                sh jenkins_sync.sh
                sh buildnumber_sync.sh
                sh deactivate_scheduler.sh
        EOF
    else
        echo "Activate Backup Server"
        ssh jenkins@$JENKINS_DEFAULT_BACKUP <<-EOF
                sh activate_scheduler.sh
        EOF
        [ $swap = true ] &&  swap=false || swap=true
        tmp=$master
        master=$backup
        backup=$tmp
    fi
fi
echo $timestamp $master $backup $swap >> jenkins_monitoring.log
echo "Done"