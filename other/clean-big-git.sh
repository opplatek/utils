#!/bin/bash
#
# Find big .git repos and clean big files (probably trash)
#
# IMPORTANT: Be careful with this as this will delete all the files and directories
#   from your git history!!!
#
# Don't waste your time with git filter-branch or git filter-index ...
#

# Get scala (for bfg)
cd ~/tools/
wget https://github.com/sbt/sbt/releases/download/v1.5.5/sbt-1.5.5.zip -O sbt-1.5.5.zip
unzip sbt-1.5.5.zip
mv sbt sbt-1.5.5
cd sbt-1.5.5/
ln -s $(pwd)/sbt ~/bin/sbt

# Install bfg; follow the instructions https://github.com/rtyley/bfg-repo-cleaner/blob/master/BUILD.md
cd ~/tools/
wget https://github.com/rtyley/bfg-repo-cleaner/archive/refs/tags/v1.14.0.tar.gz -O bfg-repo-cleaner-1.14.0.tar.gz
tar xvzf bfg-repo-cleaner-1.14.0.tar.gz
cd bfg-repo-cleaner-1.14.0/
sbt # <- start the sbt console
bfg/assembly # <- download dependencies, run the tests, build the jar

# Make link to you bin directory:
# Paste this (without the ">" symbol) into ~/bin/bfg
nano ~/bin/bfg
#   > #!/bin/bash
#   > java -jar /home/joppelt/tools/bfg-repo-cleaner-1.14.0/bfg/target/bfg-1.14.0-unknown.jar $@



### Find big .gits
find . -type d -name ".git" -prune -exec du -sh {} \;
# Or just check git repo size
# cd ~/project-to-clean/
# du -sh .git

# Check the big files; from # https://gist.github.com/magnetikonline/dd5837d597722c9c2d5dfa16d8efe5b9;
#   Other comments on similar topic: https://stackoverflow.com/questions/2100907/how-to-remove-delete-a-large-file-from-commit-history-in-the-git-reposito
git big-files
#OR
#~/tools/utils/gitlistobjectbysize.sh

# Add to .gitinore so we don't get them again

# Add changes and commit
git add .
git commit -m "Updated .gitignore before cleaning with bfg"

# Repack big blobs
git gc --prune=now --aggressive

# Remove big files with bfg https://rtyley.github.io/bfg-repo-cleaner/ (by far the best and easiest solution)
bfg --strip-blobs-bigger-than 10M .git
# or remove files by name
# bfg --delete-files hsa.*.pdf .git
# or folders
# bfg --delete-folders *bckp .git

# Clean and finalize the deletion
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# Add changes, commit and push
git add .
git commit -m "Commit after cleaning with bfg"

# Push to master
git push -f origin master

# Check the .git repo size
du -sh .git

