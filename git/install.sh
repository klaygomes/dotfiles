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
  echo "Directory ${HOME}/${work} was created"
fi

# we assume the actual ${HOME}/.gitconfig is your work related one
if [ -f ${HOME}/.gitconfig ]
then
  echo "Warning: there is already a file named ${HOME}/.gitconfig."
  echo -e "Do you want to move to ${HOME}/${work}? (type yes)\n"
  read  -n3 -r REPLY
  if [ "$REPLY" == 'yes' ]
  then

    git_home=${HOME}/.gitconfig 
    git_work=${HOME}/${work}/.gitconfig 
    # first lets create a backup
    cp ${git_home}  ${git_home}.${RANDOM}.bak
    [ -f "${git_work}" ] && cp ${git_work} ${git_work}.${RANDOM}.bak

    mv ${HOME}/.gitconfig ${HOME}/${work}/.gitconfig
    echo -e "\n.gitconfig moved to ${HOME}/${work}\n"
  fi
fi

while [ -z ${email+x} ] ; do
  read -p "Your personal email: " email
done

while [ -z ${name+x} ] ; do
  read -p "Your name: " name
done

# now we move the file we got as parameters and replace 
[ -f "$1" ] && mv $1 ${HOME}/.gitconfig

# we set our personal email as global
git config --global user.email ${email}
git config --global user.name "${name}"

# set delta as global pager
for t in diff log reflog show;
do
 git config --global pager.$t delta
done

git config --global delta.features "side-by-side line-numbers decorations"
git config --global delta.syntax-theme Dracula
git config --global delta.plus-style 'syntax "#003800"'
git config --global delta.minus-style 'syntax "#3f0001"'

cat >> ${HOME}/.gitconfig <<EOF

[delta "decorations"]
    commit-decoration-style = bold yellow box ul
    file-style = bold yellow ul
    file-decoration-style = none
    hunk-header-decoration-style = cyan box ul

[delta "line-numbers"]
    line-numbers-left-style = cyan
    line-numbers-right-style = cyan
    line-numbers-minus-style = 124
    line-numbers-plus-style = 28

EOF

# If you are inside ${HOME}/[company] use its configuration
echo -e "\n[includeIf \"gitdir:${HOME}/${work}/**\"]\n\tpath = ${HOME}/${work}/.gitconfig\n" >> ${HOME}/.gitconfig

