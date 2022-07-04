#!/bin/bash
#----------------------------------------------------------------#
# Author : Abdou Khadre D. GAYE                                  #
# Version : v1.0                                                 #
# Usage : ./run-jenkins-backup.sh                                #
#----------------------------------------------------------------#


GREEN="\e[92m"
DEFAULT="\e[39m"
YELLOW="\e[33m"


CUR_DATE=$(date +"%d%m%Y")
ARCH_NAME=$(ls -A /tmp/jenkins_backup_*)
ARCH_DATE=$(echo "$ARCH_NAME" | grep -oE '[0-9]{8}')

# Checck if a backup has already been made today
if [ $CUR_DATE -eq $ARCH_DATE ]; then
   echo -en "$GREEN OK $DEFAULT\tBackup Already done today$DEFAULT \n"
   echo -en "$GREEN\tFILE NAME : $ARCH_NAME $DEFAULT |\tLAST BCK DATE : $ARCH_DATE\n"
else
   echo -en "$YELLOW \tOLD BACKUP : $ARCH_NAME $DEFAULT |\tDATE: $ARCH_DATE\n"
   echo -en "\tBackup in process...\n"
   sleep 2
   ./jenkins-backup.sh /var/lib/jenkins /tmp/jenkins_backup_`date +"%d%m%Y"`.tar.gz
fi
