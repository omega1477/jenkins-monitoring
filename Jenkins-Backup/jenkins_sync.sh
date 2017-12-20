#!/bin/sh

##########################################################################################
# Jenkins Master and Backup Server Synchronization
#
# Prerequisites
# 1. Jenkins master server must installed SCM Sync Configuration Plugin
# 2. The repository (GitLab or GitHub) must be accessible by both Jenkins master and Jenkins backup server
# 3. Jenkins backup server must have ssh access to Jenkins master server
#
# Process
# 1. Jenkins master server backup to GitLab via SCM Sync Configuration Plugin
# 2. Jenkins backup server pull from the GitLab repository
# 3. Sync the file with the Jenkins home directory
# 4. Rsync the plugins from Jenkins master to Jenkins backup server
# 5. Update all available Jenkins plugins
#
# Author:
#  Chua Chee Ann <chuaca@sg.ibm.com>
# Date:
#  2017-Nov-24
##########################################################################################

JENKINS_HOME_DIR='/var/lib/jenkins/'
JENKINS_PLUGINS_DIR='/var/lib/jenkins/plugins/'
JENKINS_MASTER='9.45.126.230'
JENKINS_CLI='./jenkins-cli.jar'
JENKINS_SCM_CONFIG='/var/lib/jenkins/scm-sync-configuration.xml'
JENKINS_MAILER='/var/lib/jenkins/hudson.tasks.Mailer.xml'
JENKINS_LOCATION='/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml'
BUILDNUMBER_SYNC_SS='/home/jenkins/buildnumber_sync.sh'
DEACTIVATOR_SS='/home/jenkins/deactivate_scheduler.sh'
GIT='git@github.ibm.com:gts-sla/jenkins-backup-main.git'
MAIL_HOST='https:\/\/itaas-build-2.sby.ibm.com:9443\/'

# ============= Sychronize with the GitLab (Start) ============= #
cd $WORKSPACE
# Run git pull to sync local file with GitLab
mkdir -p ./jenkins-backup
cd ./jenkins-backup
git ls-remote $GIT -q
if [ $? -eq 0 ]
then
        echo -e "Start pulling file from GitLab ..."
        git pull
else
        echo -e "Git clone repository from GitLab ..."
        git clone $GIT
fi

# Sync Jenkins home directory via rsyn command
# -a: For recursion and want to preserve everything
# -v: This  option  increases  the amount of information you are given during the transfer
# -z: Rsync compresses the file data as it is sent to the destination machine
# -h: Output numbers in a more human-readable format.
rsync -avzh ./ $JENKINS_HOME_DIR
cd $WORKSPACE
# ============= Sychronize with the GitLab (End) ============= #

# ============= Sychronize Plugins with the Jenkins Master Server (Start) ============= #
# Sync the plugin with Jenkins master server via rsyn command
rsync -avzh jenkins@$JENKINS_MASTER:$JENKINS_PLUGINS_DIR $JENKINS_PLUGINS_DIR

# Sync the SSH Remote Hosts setting
rsync -avzh jenkins@$JENKINS_MASTER:/var/lib/jenkins/jenkins.plugins.publish_over_ssh.BapSshPublisherPlugin.xml /var/lib/jenkins/jenkins.plugins.publish_over_ssh.BapSshPublisherPlugin.xml

# Sync the Global Passwords setting
rsync -avzh jenkins@$JENKINS_MASTER:/var/lib/jenkins/envInject.xml /var/lib/jenkins/envInject.xml

# Sync the Encryption setting
rsync -avzh jenkins@$JENKINS_MASTER:/var/lib/jenkins/secrets/hudson.util.Secret /var/lib/jenkins/secrets/hudson.util.Secret
rsync -avzh jenkins@$JENKINS_MASTER:/var/lib/jenkins/secrets/master.key /var/lib/jenkins/secrets/master.key


# ============= Update All Available Jenkins Plugins ============= #
# 1. Using jenkins-cli.jar to find out all update available plugins
# 2. Save those plugins in UPDATE_LIST and update it one by one
# 3. Restart Jenkins server after update

if [ -f "$JENKINS_CLI" ]
then
        echo "$JENKINS_CLI exist."
else
        echo "$JENKINS_CLI not found."
        wget --no-check-certificate https://itaas-build-2.sby.ibm.com:9443/jnlpJars/jenkins-cli.jar
fi
UPDATE_LIST=$( java -jar jenkins-cli.jar -s https://itaas-build-2.sby.ibm.com:9443/ -noCertificateCheck  list-plugins --username "bpmbuild@sg.ibm.com" --password "t3stc0balt1" | grep -e ')$' | awk '{ print $1 }' );
if [ ! -z "${UPDATE_LIST}" ]; then
    echo Updating Jenkins Plugins: ${UPDATE_LIST};
    java -jar jenkins-cli.jar -s https://itaas-build-2.sby.ibm.com:9443/ -noCertificateCheck  install-plugin ${UPDATE_LIST} --username "bpmbuild@sg.ibm.com" --password "t3stc0balt1";
    java -jar jenkins-cli.jar -s https://itaas-build-2.sby.ibm.com:9443/ -noCertificateCheck  safe-restart --username "bpmbuild@sg.ibm.com" --password "t3stc0balt1";
fi

#sed -i 's/<scm class="hudson.plugins.scm_sync_configuration.scms.ScmSyncGitSCM"\/>/<scm class="hudson.plugins.scm_sync_configuration.scms.ScmSyncNoSCM"\/>/g' "$JENKINS_SCM_CONFIG"
sed -i 's/git@github.ibm.com:gts-sla\/jenkins-backup-main.git/git@github.ibm.com:gts-sla\/jenkins-backup-standby.git/g' "$JENKINS_SCM_CONFIG"
sed -i 's/https:\/\/itaas-build.sby.ibm.com:9443\//https:\/\/itaas-build-2.sby.ibm.com:9443\//g' "$JENKINS_MAILER"
sed -i 's/https:\/\/itaas-build.sby.ibm.com:9443\//https:\/\/itaas-build-2.sby.ibm.com:9443\//g' "$JENKINS_LOCATION"

sh $BUILDNUMBER_SYNC_SS
sh $DEACTIVATOR
# ============= Sychronize Plugins with the Jenkins Master Server (End) ============= #
#sudo systemctl restart jenkins
echo "Synchronization Done"