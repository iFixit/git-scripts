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
      echo "Available feature branches: (current branch marked with >>)"
      echo
      # List all branches
      git branch |
         # Make the 'current branch' mark more obvious
         sed -e "s/\* \(.*\)/>> \1 <</" |
         # Remove non-feature branches
         grep -vE "  (hot-fix-|master|development)$"
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
