#!/bin/bash
#----------------------------------------------------------------#
# Author : Abdou Khadre D. GAYE                                  #
# Version : v1.0                                                 #
# Usage : ./install_jenkins.sh                                   #
# Description : This script install/uninstall  Jenkins on RHEL   #
#----------------------------------------------------------------#


function setproxy() {

    PROXY="http://10.153.151.4:8080/"
    export {HTTP,HTTPS}_PROXY=$PROXY

}

function unsetproxy() {
    unset {HTTP,HTTPS}_PROXY
}


readonly JENKINS_HOME="/var/lib/jenkins"
readonly CACHE_DIR="/var/cache/jenkins"
readonly LOG_DIR="/var/log/jenkins"
readonly REPO_FILE="/etc/yum.repos.d/jenkins.repo"

GREEN="\e[92m"
DEFAULT="\e[39m"
YELLOW="\e[33m"
RED="\e[31m"


function install {

    setproxy

    rm -rf $CACHE_DIR

    #curl -sSL -o /etc/yum.repos.d/jenkins.repo     https://pkg.jenkins.io/redhat-stable/jenkins.repo

    echo -en "[jenkins]\nname=Jenkins\nbaseurl=https://pkg.jenkins.io/redhat\ngpgcheck=1\n" > $REPO_FILE

    rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key

    yum upgrade -y

    # Add required dependencies for the jenkins package
    yum install -y java-11-openjdk jenkins

    if [ $? -eq 0 ]; then

        #firewall
        PORT=8080
        PERM="--permanent"
        SERV=" --service=jenkins"

        firewall-cmd  --new-service=jenkins
        firewall-cmd  --set-short="Jenkins ports"
        firewall-cmd  --set-description="Jenkins port exceptions"
        firewall-cmd  --add-port=/tcp
        firewall-cmd  --add-service=jenkins
        firewall-cmd --zone=public --add-service=http --permanent
        firewall-cmd --reload

        # changer user and group (jenkins by default)
        sed -i 's/User=jenkins/User=root/g' /usr/lib/systemd/system/jenkins.service
        sed -i 's/Group=jenkins/Group=root/g' /usr/lib/systemd/system/jenkins.service
        chown -R root:root /var/lib/jenkins

        #Start Jenkins
        systemctl daemon-reload
        systemctl enable jenkins
        systemctl start jenkins
        systemctl status jenkins -l

    else
      echo -en "$RED\tFailed to install jenkins.$DEFAULT\n"
    fi

}


function uninstall_jenkins {
    echo -en "stopping Jenkins...\n"
    systemctl stop jenkins
    sleep 10
    STATUS=$(systemctl status jenkins | grep -i Active)
    sts=$( echo $STATUS | awk '{print $2}' )
    if [ "$sts" = "inactive" -o "$sts" = "dead" ] ; then
        echo -en "$GREEN\tJenkins is successfully stopped...$DEFAULT\n"
        systemctl status jenkins
        echo -en "Removing old Jenkins files...\n"
        yum remove jenkins -y
        # remove jenkins from the system by excluding the 2 directories bellow
        find / -name jenkins ! -path /users/dosiadm/scripts/jenkins ! -path /outil/jenkins | xargs rm -rf
    elif [ "$sts" = "active" ]; then
        echo -en "$RED\tFailed to sop off Jenkins...$DEFAULT\n"
        systemctl status jenkins
        echo -en "$YELLOW\tForce to uninstall Jenkins in 10 seconds ...$DEFAULT\n"
        yum remove jenkins -y
        # remove jenkins from the system exclude the 2 directories bellow
        #find / -name jenkins ! -path /users/dosiadm/scripts/jenkins ! -path /outil/jenkins | xargs rm -rf

    else
        echo -en "$RED\tFailed to uninstall Jenkins...$DEFAULT\n"
        exit 1
    fi

}



function chek_install {
    systemctl daemon-reload
    STATUS=$(systemctl status jenkins | grep -i Active)
    sts=$( echo $STATUS | awk '{print $2}' )
    if [ "$sts" = "active" ] ; then
        echo -en "$GREEN\tJenkins already installed and up...$DEFAULT\n"
        systemctl status jenkins
        exit 0
    elif [ "$sts" = "inactive" -o "$sts" = "failed"]; then
        echo -en "$YELLOW\tjenkins is installed but not active.$DEFAULT\n"
        systemctl status jenkins
        systemctl start jenkins
        sleep 5 && systemctl status jenkins -l

        if [ $? -eq 0 ];then
            exit 0
        else
          echo -en "\tFailed to start jenkins...\n"
          systemctl status jenkins
          exit 5
        fi

    elif [ "$sts" != "active" ] && [ "$sts" != "inactive" ]; then
        echo -en "\tjenkins is not installed...\n"
        echo -en "\tInstalling jenkins...\n"
        install
        echo -en "\tjenkin status :\n"
        systemctl status jenkins
    else
        echo -en "$RED\tInstallation failed...Try to do it manually. $DEFAULT\n"
        systemctl status jenkins
        exit 10
    fi

    unsetproxy

}


case "$1" in
    install|-i)
        chek_install
        ;;
    uninstall|-r|remove)
        uninstall_jenkins
        ;;
    *)
        echo -en "$YELLOW\tUsage$DEFAULT: ./install_jenkins.sh [install|uninstall]\n"
        ;;

esac


