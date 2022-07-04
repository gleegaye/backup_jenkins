#!/bin/bash
#---------------------------------------------------------------------------#
# Auteur : Abdou Khadre GAYE                                             #
# Version : v1.0                                                            #
# Usage: ./jenkins-backup.sh /path/to/jenkins_home \
#            /path/to/destination/jenkins_backup_$(date +"%d%m%Y_%H%M").tar.gz
#---------------------------------------------------------------------------#

# stop when error is occurred
set -o pipefail


readonly JENKINS_HOME="$1"
readonly DEST_FILE="$2"
#readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
#readonly TMP_DIR="${CUR_DIR}/tmp"
readonly TMP_DIR="/outil/tmp"
readonly ARC_NAME="jenkins-backup"
readonly ARC_DIR="${TMP_DIR}/${ARC_NAME}"
readonly TMP_TAR_NAME="${TMP_DIR}/jenkins_backup.tar.gz"


function usage() {
  echo "usage: $(basename $0) /path/to/jenkins_home jenkins_backup.tar.gz"
}


function backup_jobs() {
  local run_in_path="$1"
  local rel_depth=${run_in_path#${JENKINS_HOME}/jobs/}

  if [ -d "${run_in_path}" ]; then
    cd "${run_in_path}"

    find . -maxdepth 1 -type d | while read job_name; do
      [ "${job_name}" = "." ] && continue
      [ "${job_name}" = ".." ] && continue
      [ -d "${JENKINS_HOME}/jobs/${rel_depth}/${job_name}" ] && mkdir -p "${ARC_DIR}/jobs/${rel_depth}/${job_name}/"
      find "${JENKINS_HOME}/jobs/${rel_depth}/${job_name}/" -maxdepth 1  \( -name "*.xml" -o -name "nextBuildNumber" \) -print0 | xargs -0 -I {} cp {} "${ARC_DIR}/jobs/${rel_depth}/${job_name}/"
      if [ -f "${JENKINS_HOME}/jobs/${rel_depth}/${job_name}/config.xml" ] && [ "$(grep -c "com.cloudbees.hudson.plugins.folder.Folder" "${JENKINS_HOME}/jobs/${rel_depth}/${job_name}/config.xml")" -ge 1 ] ; then
        backup_jobs "${JENKINS_HOME}/jobs/${rel_depth}/${job_name}/jobs"
      else
        true
      fi
    done
    cd -
  fi
}



function cleanup() {
  rm -rf "${ARC_DIR}"
}


function main() {
  if [ -z "${JENKINS_HOME}" -o -z "${DEST_FILE}" ] ; then
    usage >&2
    exit 1
  fi

  rm -rf "${ARC_DIR}" "{$TMP_TAR_NAME}"
 # create temporary directories for backup
  for plugin in plugins jobs users secrets nodes userContent war workflow-libs workspace scriptler logs monitoring; do
    mkdir -p "${ARC_DIR}/${plugin}"
  done

  cp "${JENKINS_HOME}/"*.xml "${ARC_DIR}"

  cp "${JENKINS_HOME}/plugins/"*.[hj]pi "${ARC_DIR}/plugins"
  hpi_pinned_count=$(find ${JENKINS_HOME}/plugins/ -name *.hpi.pinned | wc -l)
  jpi_pinned_count=$(find ${JENKINS_HOME}/plugins/ -name *.jpi.pinned | wc -l)
  if [ ${hpi_pinned_count} -ne 0 -o ${jpi_pinned_count} -ne 0 ]; then
    cp "${JENKINS_HOME}/plugins/"*.[hj]pi.pinned "${ARC_DIR}/plugins"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/users/)" ]; then
    cp -RP "${JENKINS_HOME}/users/"* "${ARC_DIR}/users"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/secrets/)" ] ; then
    cp -RP "${JENKINS_HOME}/secrets/"* "${ARC_DIR}/secrets"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/secret.key*)" ] ; then
    cp -RP "${JENKINS_HOME}/secret.key"* "${ARC_DIR}/"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/nodes/)" ] ; then
    cp -RP "${JENKINS_HOME}/nodes/"* "${ARC_DIR}/nodes"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/userContent/)" ] ; then
    cp -RP "${JENKINS_HOME}/userContent/"* "${ARC_DIR}/userContent"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/war/)" ] ; then
    cp -RP "${JENKINS_HOME}/war/"* "${ARC_DIR}/war"
  fi


  if [ "$(ls -A ${JENKINS_HOME}/workflow-libs/)" ] ; then
    cp -RP "${JENKINS_HOME}/workflow-libs/"* "${ARC_DIR}/workflow-libs"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/workspace/)" ] ; then
    cp -RP "${JENKINS_HOME}/workspace/"* "${ARC_DIR}/workspace"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/scriptler/)" ] ; then
    cp -RP "${JENKINS_HOME}/scriptler/"* "${ARC_DIR}/scriptler"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/logs/)" ] ; then
    cp -RP "${JENKINS_HOME}/logs/"* "${ARC_DIR}/logs"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/monitoring/)" ] ; then
    cp -RP "${JENKINS_HOME}/monitoring/"* "${ARC_DIR}/monitoring"
  fi

  if [ "$(ls -A ${JENKINS_HOME}/jobs/)" ] ; then
    backup_jobs ${JENKINS_HOME}/jobs/
  fi

  cd "${TMP_DIR}"
  tar -czvf "${TMP_TAR_NAME}" "${ARC_NAME}/"*
  cd -
  mv -f "${TMP_TAR_NAME}" "${DEST_FILE}"

  cleanup

  exit 0
}


main
