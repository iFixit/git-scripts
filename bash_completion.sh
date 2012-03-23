#!/bin/sh

_git-scripts()
{
   local cmd="${1##*/}"
   local cur=${COMP_WORDS[COMP_CWORD]}
   local line=${COMP_LINE}

   # Check to see what command is being executed.
   case "$cmd" in
   feature)
      if [ "$line" = "$cmd $cur" ]; then
         words="switch start finish stashes list pull status"
      else
         # get branch names minus hotfixes
         words="$(git branch -a | tr -d ' *' | grep -v 'hotfix-' | sed 's|remotes/origin/||')"
      fi
      ;;
   hotfix)
      if [ "$line" = "$cmd $cur" ]; then
         words="switch start finish list"
      else
         # get hotfix branch names
         words="$(git branch -a | tr -d ' *' | grep 'hotfix-' | sed 's|remotes/origin/||')"
      fi
      ;;
   esac

   COMPREPLY=($(compgen -W "${words}" -- ${cur}))
   return 0
}

complete -F _git-scripts feature hotfix
