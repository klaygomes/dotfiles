#!/bin/bash -euo pipefail

if [ $# -eq 0 ]
then
  echo "where is the .gitconfig?"
  exit 1
fi

# we use the company name as working directory
[ -z ${work+x} ] && read -p "Where do you work: " work

if [ ! -d ${HOME}/${work} ]
then
  mkdir -p "${HOME}/${work}"
  echo "Directory ${HOME}/${REPLY} was created"
fi

# we assume the actual ${HOME}/.gitconfig is your work related one
if [ -f ${HOME}/.gitconfig ]
then
  echo "Warning: there is already a file named ${HOME}/.gitconfig."
  echo -e "Do you want to move to ${HOME}/${work}? (type yes)\n"
  read  -n3 -r
  if [ "$REPLY" == 'yes' ]
  then
    mv ${HOME}/.gitconfig ${HOME}/${work}/.gitconfig
    echo -e "\n.gitconfig moved to ${HOME}/${work}\n"
  fi
fi

[ -z ${email+x} ] && read -p "Your personal email: " email
[ -z ${name+x} ] && read -p "Your name: " name

# now we move the file we got as parameters and replace 
[ -f "$1" ] && mv $1 ${HOME}/.gitconfig

# we set our personal email as global
git config --global user.email ${email}
git config --global user.name "${name}"

# If you are inside ${HOME}/[company] use its configuration
echo -e "\n[includeIf \"gitdir:${HOME}/${work}/**\"]\n\tpath = ${HOME}/${work}/.gitconfig\n" >> ${HOME}/.gitconfig

