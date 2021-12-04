#!/bin/bash -e
#
# List all Git repository objects by size
#
# Author and source:
# https://gist.github.com/magnetikonline/dd5837d597722c9c2d5dfa16d8efe5b9
# Other comments on similar topic:
# https://stackoverflow.com/questions/2100907/how-to-remove-delete-a-large-file-from-commit-history-in-the-git-repository
#
# Usage:
# $ ./gitlistobjectbysize.sh
# If we now wish to remove something/really/large.iso we can rewrite history using git filter-branch:
# $ git filter-branch --index-filter 'git rm --cached --ignore-unmatch big-thing-to-remove' HEAD
#
# OR slower but safer
#
# $ git filter-branch \
#	--tree-filter "rm -f big-thing-to-remove" \
#	-- --all
#
# And then push the changes to the remote
# $ git push origin master --force
#

function main {
	local tempFile=$(mktemp)

	# work over each commit and append all files in tree to $tempFile
	local IFS=$'\n'
	local commitSHA1
	for commitSHA1 in $(git rev-list --all); do
		git ls-tree -r --long "$commitSHA1" >>"$tempFile"
	done

	# sort files by SHA1, de-dupe list and finally re-sort by filesize
	sort --key 3 "$tempFile" | \
		uniq | \
		sort --key 4 --numeric-sort # --reverse

	# remove temp file
	rm "$tempFile"
}


main
