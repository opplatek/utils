#!/bin/bash
#
# Git commit of .R and .sh scripts
# http://sivareddy.in/automatic-backup-project-data-git
 
git init # Creates .git directory, run this only once in the directory of Git synchro
#git config --global user.email "opplatek@gmail.com" # If necessary, adds user email to global settings
#git config --global user.name "Jan Oppelt" # If necessary, adds user name to global settings
 
VERSION=$(date +'%H%M/%m%d%Y')
 
# Add files you want to synchronize
git add .
 
# Commit the changes
#git commit -m '${VERSION}'
git commit -m ${VERSION}
 
# See git commits and differences
git show
 
# Upload git to bitbucket
#git remote add origin ssh://git@bitbucket.org/opplatek/nanopore_methylation-juzova.git # You need to specify this for all the projects
git push origin master
 
# Add the directory for regular automatic commits
#cp ~/Documents/scripts_commands/git.run . # Add script for backup
#crontab -e # Open cron job manager
# 30      23      *       *       *       cd /home/jan/Data/projects/linda/2017/scripts && ./git.run # Add for cron job for example line like this
 
# If you get error which tells you it is not possible to authenticate see either /etc/ssh/ssh_config or this bug https://bugs.launchpad.net/ubuntu/+source/gnome-keyring/+bug/201786
