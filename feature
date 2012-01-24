#!/bin/bash

function has_uncommitted_changes() {
   # List all local changes
   git status -s |
      # Look for lines that don't start with ??
      # ?? = untracked file, anything else (M,D,..) is a dirty tree
      grep -vE "^\?\?" >>/dev/null
}

command="$1"
case "$command" in
   list)
      echo
      echo "Available feature branches: (current branch is colored)"
      echo
      git branch --no-merged master |
      grep -vE "  (hot-fix-|master)$" |
      while read line ; do
         reg="\*"
         # If this is the current branch
         if [[ $line =~ $reg ]]; then
            # Trim off the first two characters
            line=${line:2}
            # Make this line red
            printf "\033[31m"
         fi
         printf "%-30s %s\n" "$line" "`git show -s --pretty="%h %an %Cgreen(%ar)%Creset" $line`"
      done
      ;;

   *)
      echo "Invalid command '$command'

      ================================
      Git Feature Branch Helper

      usage:
         feature list
         feature start name-of-feature
         feature switch name-of-feature
         feature finish name-of-feature

      Look at the source to discover what each of these commands does.
      " >&2
      exit 1
      ;;
esac
