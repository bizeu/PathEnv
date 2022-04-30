# shellcheck shell=bash

#######################################
# envfile.sh completion
# Globals:
#   COMPREPLY
# Arguments:
#   1     name of the command whose arguments are being completed
#   2     word being completed ("cur")
#   3     word preceding the word being completed or $1 when is the first word ("prev")
#######################################
_envfile() {
  local opt=""
  [ "$1" = "$3" ] || return 0
  [ "${1}.sh" != "$1" ] || opt=" hook"
  mapfile -t COMPREPLY < <(compgen -W "-h --help help${opt}" -- "$2")
}

complete -F _helps envfile
complete -F _helps envfile.sh
