#!/bin/sh
#
# An example hook script to check the commit log message.
# Called by "git commit" with one argument, the name of the file
# that has the commit message.  The hook should exit with non-zero
# status after issuing an appropriate message if it wants to stop the
# commit.  The hook is allowed to edit the commit message file.

YELLOW="\e[93m"
GREEN="\e[32m"
RED="\e[31m"
ENDCOLOR="\e[0m"

printMessage() {
   printf "${YELLOW}AppFlowy : $1${ENDCOLOR}\n"
}

printSuccess() {
   printf "${GREEN}AppFlowy : $1${ENDCOLOR}\n"
}

printError() {
   printf "${RED}AppFlowy : $1${ENDCOLOR}\n"
}

printMessage "Running the AppFlowy commit-msg hook."

# This example catches duplicate Signed-off-by lines.

test "" = "$(grep '^Signed-off-by: ' "$1" |
	 sort | uniq -c | sed -e '/^[ 	]*1[ 	]/d')" || {
	echo >&2 Duplicate Signed-off-by lines.
	exit 1
}

.githooks/gitlint \
	 --msg-file=$1 \
	 --subject-regex="^(build|chore|ci|docs|feat|feature|fix|perf|refactor|revert|style|test)(.*)?:\s?.*" \
    --subject-maxlen=150 \
    --subject-minlen=10 \
    --body-regex=".*" \
    --max-parents=1

if [ $? -ne 0 ]
then
    printError "Please fix your commit message to match AppFlowy coding standards"
    printError "https://docs.appflowy.io/docs/documentation/software-contributions/conventions/git-conventions"
    exit 1
fi

