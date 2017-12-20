#!/bin/sh

##########################################################################################
# Activate Jenkins Task Scheduler
#
# Prerequisites
# 1. Server must installed Jenkins
# 2. Jenkins jobs configuration file must stored in "/var/lib/jenkins/jobs"
#
# Author:
#  Chua Chee Ann <chuaca@sg.ibm.com>
# Date:
#  2017-Nov-27
##########################################################################################

JENKINS_JOBS_DIR="/var/lib/jenkins/jobs/"
JENKINS_CONFIG="config.xml"

cd $JENKINS_JOBS_DIR
# ============= Check and edit the scheduler in every jobs config.xml (Start) ============= #

find -name "$JENKINS_CONFIG" | while read file; do
        echo "$file"
        sed -i 's/<triggers>/<!-- <triggers>/g' "$file"
        sed -i 's/<\/triggers>/<\/triggers> -->/g' "$file"
done

# ============= Check and edit the scheduler in every jobs config.xml (End) ============= #
sudo systemctl restart jenkins
echo "Deactivation Done"