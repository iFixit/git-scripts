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
         words="switch start finish stashes list merge pull status clean"
      else
         # get branch names minus hotfixes
         words="$(git branch -a | tr -d ' *' | grep -v 'hotfix-' | sed 's|remotes/origin/||')"
      fi
      ;;
   hotfix)
      if [ "$line" = "$cmd $cur" ]; then
         words="switch start finish merge list clean"
      else
         # get hotfix branch names
         words="$(git branch -a | tr -d ' *' | grep 'hotfix-' | sed -e 's|remotes/origin/||' -e 's|hotfix-||')"
      fi
      ;;
   esac

   COMPREPLY=($(compgen -W "${words}" -- ${cur}))
   return 0
}

complete -F _git-scripts feature hotfix
