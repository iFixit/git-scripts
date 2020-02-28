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
         words="switch start finish finish-issue stashes list merge pull status prune url"
      else
         words="$(git branch -a | tr -d ' *' | sed 's|remotes/origin/||')"
      fi
      ;;
   esac

   COMPREPLY=($(compgen -W "${words}" -- ${cur}))
   return 0
}

complete -F _git-scripts feature fs
