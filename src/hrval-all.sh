#!/usr/bin/env bash

set -o errexit
shopt -s extglob

DIR=${1}
IGNORE_VALUES=${2-false}
KUBE_VER=${3-master}
HELM_VER=${4-v2}
IGNORE_EXPRESSION=${5}
HRVAL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/hrval.sh"

if [[ ${HELM_VER} == "v2" ]]; then
    helm init --client-only
fi

# If the path provided is actually a file, just run hrval against this one file
if test -f "${DIR}"; then
  ${HRVAL} ${DIR} ${IGNORE_VALUES} ${KUBE_VER} ${HELM_VER}
  exit 0
fi

# If the path provided is not a directory, print error message and exit
if [ ! -d "$DIR" ]; then
  echo "\"${DIR}\" directory not found!"
  exit 1
fi

function isHelmRelease {
  KIND=$(yq r ${1} kind)
  if [[ ${KIND} == "HelmRelease" ]]; then
      echo true
  else
    echo false
  fi
}

# Find yaml files in directory recursively
DIR_PATH=$(echo ${DIR} | sed "s/^\///;s/\/$//")
FILES_TESTED=0
for f in `find ${DIR} -type f -name '*.yaml' -or -name '*.yml'`; do
  if [[ -n ${IGNORE_EXPRESSION} && ${f} = ${IGNORE_EXPRESSION} ]]; then
    >&2 echo "Skipping file ${f} by ignore expression"
    continue
  fi
  if [[ $(isHelmRelease ${f}) == "true" ]]; then
    echo ${f}
    FILES_TESTED=$(( FILES_TESTED+1 ))
  else
    >&2 echo "Ignoring ${f} not a HelmRelease"
  fi
done | parallel --jobs 4 "${HRVAL} {} \"${IGNORE_VALUES}\" ${KUBE_VER} ${HELM_VER}"

# This will set the GitHub actions output 'numFilesTested'
echo "::set-output name=numFilesTested::${FILES_TESTED}"
