#!/bin/bash

readonly BACKUP_DIR="/outil"
readonly ARC_NAME="jenkins_backup.tar.gz"
readonly ARC_NAME=$1
readonly JENKINS_CONF="/etc/sysconfig/jenkins"
readonly JENKINS_SRV="/etc/rc.d/init.d/jenkins"
readonly JENKINS_WAR_DIR="/usr/lib/jenkins"
readonly JENKINS_HOME="/var/lib/jenkins"
readonly CACHE_DIR="/var/cache/jenkins"
readonly LOG_DIR="/var/log/jenkins"


GREEN="\e[92m"
DEFAULT="\e[39m"
YELLOW="\e[33m"
RED="\e[31m"

function stop(){

    echo -en "Stopping jenkins...\n"
    /etc/init.d/jenkins stop
    sleep 5
    STATUS=$(systemctl status jenkins | grep -i Active)
    sts=$( echo $STATUS | awk '{print $2}' )

    if [ "$sts" = "inactive" -o "$sts" != "active" ] ; then
        echo -en "$GREEN\tJenkins is already stopped...$DEFAULT\n"
        systemctl status jenkins
        #exit 0
    else
        echo -en "$RED\tFailed to stop Jenkins...$DEFAULT\n"
        systemctl status jenkins
        #exit 5
    fi
}

function status(){
    STATUS=$(systemctl status jenkins | grep -i Active)
    sts=$( echo $STATUS | awk '{print $2}' )

    if [ "$sts" = "inactive" -o "$sts" != "active" ] ; then
        echo -en "$YELLOW\tJenkins is not running...$DEFAULT\n"
        systemctl status jenkins
    elif [  "$sts" = "active" ] ; then
        echo -en "$GREEN\tJenkins is up and running...$DEFAULT\n"
        systemctl status jenkins
    else
        echo -en "$RED\tJenkins status...$DEFAULT\n"
        systemctl status jenkins

    fi


}


function restore(){
    cd $BACKUP_DIR
    ARCH_NAME=$(ls -A jenkins-backup.tar.gz)
    if test -f "$ARCH_NAME" ;then
        stop
        tar xzvf $ARCH_NAME
        if [ $? -eq 0 ];then
            rsync -av $BACKUP_DIR/jenkins-backup/*  $JENKINS_HOME
            chown -R root:root $JENKINS_HOME $CACHE_DIR $CACHE_DIR
            echo "Restarting jenkins...\n"
            /etc/init.d/jenkins start
            sleep 5
            status
        else
            echo -en "$RED\tFailed to restore backup ....$DEFAULT"
            echo $?
        fi
    else
        echo -en "$RED\tArchive $ARCH_NAME $DEFAULT does not exist ...\n"
        exit 1
    fi

}


restore
