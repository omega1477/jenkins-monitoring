# Project Title: Jenkins Monitoring and Synchronization
---
## Introduction
This project is to prevent the situation that the master Jenkins server is down for whatever reason, the backup Jenkins server can replace the role immediately.
In order to achieve this purpose, some action and setup need to be done to ensure the backup server can run with exactly same configuration with master server when it is needed

## Getting Started
These instuctions will guide you on:
1. Configure a backup repository and synchronization
2. Configure both master and backup Jenkins server 
3. How to use the shell scripts
wwww
### Prerequisitesiiii
---
Certain criterias must be fulfilled:
- Must have at least 3 servers for Jenkins Master, Jenkins Backup, and Jenkins Monitoring
- Must have Git repository for doing Jenkins backup operation
- 3 server must have SSH access to each otherttttt
- 3 server must be able to use SSH, Git, sed, rsync commands
- Jenkins installation path is same as default

### Installation
---
Jenkins provided a plugin which allows to bind the Jenkins server to a Git repository and perform synchronization whenever the configuration change in Jenkins.

1. Go to Jenkins administration panel from browser
2. Select “Manage Jenkins” from the left navigation bar
3. Select “Manage Plugins” and choose “Available” tab
4. Search “SCM Sync Configuration Plugin” and click install
5. Restart Jenkins server

### Configuration
---
1. Go to Jenkins administration panel from browser
2. Select “Manage Jenkins” from the left navigation bar
3. Select “Configure System” and scroll to the “SCM Sync configuration” section
4. Select “Git” and fill in the “Repository URL”
5. Check the Git repository to ensure the setup is done in a correct way. 

Please refer to official [Jenkins Wiki][jenkins_scm_sync_wiki] for more details about the SCM Sync Configuration Plugin.

### Setup
---
Until this step, the Jenkins server should be able to commit the configuration setting to the git repository.

Please copy the shell script from [Jenkins Master][jenkins_master_shellscript] to the master Jenkins server and 
copy the shell script from [Jenkins Backup][jenkins_backup_shellscript] to the backup Jenkins server

Each set of the shell script are same, only some of the variable was changed to match with corresponding configuration.


## Documentation
All the variables used in the shell script are listed below:

*jenkins_sync.sh
```
JENKINS_HOME_DIR='/var/lib/jenkins/'
JENKINS_PLUGINS_DIR='/var/lib/jenkins/plugins/'
JENKINS_MASTER='9.45.126.123'
JENKINS_CLI='./jenkins-cli.jar'
JENKINS_SCM_CONFIG='/var/lib/jenkins/scm-sync-configuration.xml'
JENKINS_MAILER='/var/lib/jenkins/hudson.tasks.Mailer.xml'
JENKINS_LOCATION='/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml'
BUILDNUMBER_SYNC_SS='/home/jenkins/buildnumber_sync.sh'
DEACTIVATOR_SS='/home/jenkins/deactivate_scheduler.sh'
GIT='git@github.ibm.com:chuaca/jenkins-backup.git'
MAIL_HOST='https:\/\/itaas-build.sby.ibm.com:9443\/'
```

*activate_scheduler.sh & deactivate_scheduler
```
JENKINS_JOBS_DIR="/var/lib/jenkins/jobs/"
JENKINS_CONFIG="config.xml"
```
1. JENKINS_JOBS_DIR is the default directory that store created project configuration and build information
2. JENKINS_BUILDNUMBER is the file name where the next build number store

*buildnumber_sync.sh
```
JENKINS_JOBS_DIR="/var/lib/jenkins/jobs/"
JENKINS_BUILDNUMBER="nextBuildNumber"
JENKINS_MASTER="9.45.126.123"
JENKINS_BUILD_DIR="/home/jenkins/buildList/"
```
1. JENKINS_JOBS_DIR is the default directory that store created project configuration and build information
2. JENKINS_BUILDNUMBER is the file name where the next build number store
3. JENKINS_MASTER is the master Jenkins server
4. JENKINS_BUILD_DIR is a self created directory used for rsync 


*monitor_jenkins.sh
```
JENKINS_EMAIL=bpmbuild@sg.ibm.com
JENKINS_PASS=t3stc0balt1
JENKINS_URL=https://itaas-build.sby.ibm.com:9443/
JENKINS_DEFAULT_MASTER=9.45.126.230
JENKINS_DEFAULT_BACKUP=9.45.126.123
```
1. JENKINS_EMAIL and JENKINS_PASS are the user account used to access Jenkins
2. JENKINS_URL is the FQDN of master Jenkins server
3. JENKINS_DEFAULT_MASTER is the master Jenkins server
4. JENKINS_DEFAULT_BACKUP is the backup Jenkins server

## Authors
* Chua Chee Ann - Initial work

## License
N.A.

## Acknowledgments
N.A.


[jenkins_scm_sync_wiki]: <https://wiki.jenkins.io/display/JENKINS/SCM+Sync+configuration+plugin>
[jenkins_master_shellscript]:<https://github.ibm.com/gts-sla/jenkins-monitoring/tree/master/Jenkins-Master>
[jenkins_backup_shellscript]:<https://github.ibm.com/gts-sla/jenkins-monitoring/tree/master/Jenkins-Backup>

