#!/bin/sh

#########################################################################################
# Sync Jenkins Build Number
#
# Prerequisites
# 1. Must have the access to 2 servers (Master & Backup)
# 2. Jenkins jobs configuration file must stored in "/var/lib/jenkins/jobs"
#
# Author:
#  Chua Chee Ann <chuaca@sg.ibm.com>
# Date:
#  2017-Dec-04
##########################################################################################

JENKINS_JOBS_DIR="/var/lib/jenkins/jobs/"
JENKINS_CONFIG="config.xml"
JENKINS_BUILDNUMBER="nextBuildNumber"
JENKINS_MASTER="9.45.126.123"
JENKINS_BUILD_DIR="/home/jenkins/buildList/"

mkdir -p $JENKINS_BUILD_DIR
cd $JENKINS_BUILD_DIR
# ============= Check scheduler in every jobs config.xml (Start) ============= #

find $JENKINS_BUILD_DIR -name "*" -delete
#rm -R *
rsync -avR jenkins@$JENKINS_MASTER:${JENKINS_JOBS_DIR}**/nextBuildNumber $JENKINS_BUILD_DIR
mv ${JENKINS_BUILD_DIR}var/lib/jenkins/jobs/* $JENKINS_BUILD_DIR
find ${JENKINS_BUILD_DIR}var/ -delete
#rm -R ${JENKINS_BUILD_DIR}var/

#cd $JENKINS_JOBS_DIR
find -name "$JENKINS_BUILDNUMBER" | while read file; do

        backupBuild=$(cat "$JENKINS_JOBS_DIR$file")
#       echo $backupBuild
#       check=$( ssh -n $JENKINS_MASTER [[ -f "$JENKINS_JOBS_DIR$file" ]] && echo "EXIST" || echo "NOPE" )
#       masterBuild=$( [[ -f "$JENKINS_BUILD_DIR$file" ]] &&  cat "$JENKINS_BUILD_DIR$file" )
        masterBuild=$( [[ -f "$file" ]] &&  cat "$file" )
        echo $(( $backupBuild > $masterBuild ? $backupBuild:$masterBuild ))> $file
done

rsync -avr --include="**/$JENKINS_BUILDNUMBER" $JENKINS_BUILD_DIR $JENKINS_JOBS_DIR

# ============= Check scheduler in every jobs config.xml (End) ============= #
# sudo systemctl restart jenkins
echo "Build Number Synchronization Finished"
