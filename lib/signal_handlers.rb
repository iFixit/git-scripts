# On a Ctrl-C or a broken pipe, just exit instead of printing a stack strace
trap "INT",  "EXIT"
trap "PIPE", "EXIT"
