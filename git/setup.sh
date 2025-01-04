#!/bin/bash -euo pipefail
echo "Configuring git... "

CONFIG_PATH=${CONFIG_PATH:-${HOME}/.config/}

# load configuration
source ./git/user-info.sh

# we set our personal email as global
git config --global user.email "${EMAIL_PERSONAL}"
git config --global user.name "${NAME}"

GITCONFIG_ROOT="${HOME}/.gitconfig"
# create .gitconfig
if [ -f ${GITCONFIG_ROOT} ]
    then
        echo "> File ${GITCONFIG_ROOT} already exists, skipping"
    else
        envsubst < ${CONFIG_PATH}/.gitconfig_root_template > ${GITCONFIG_ROOT}
        echo "> File ${GITCONFIG_ROOT} was created"
fi

for i in work opensource personal
do
    LEAF="${HOME}/${i}"
    if [ -d ${LEAF} ]
    then
        echo "> Directory ${HOME}/${i} already exists, skipping"
    else
        mkdir -p ${LEAF}
        echo "> ${LEAF} was created"
        envsubst < ./git/.gitconfig_leaf_template > ${LEAF}/.gitconfig
        echo "> File ${LEAF}/.gitconfig was created"
        if ! grep "${LEAF}/.gitconfig" ${GITCONFIG_ROOT} -q &> /dev/null; then
            # include leaf gitconfig in root
            echo -e "\n[includeIf \"gitdir:${LEAF}/**\"]\n\tpath = ${LEAF}/.gitconfig\n" >> ${GITCONFIG_ROOT}
            echo "> ${LEAF}/.gitconfig was included in ${GITCONFIG_ROOT}"
        else
            echo "> ${LEAF}/.gitconfig is already included in ${GITCONFIG_ROOT}"
        fi
    fi
done

echo "- ok"