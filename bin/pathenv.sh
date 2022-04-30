# shellcheck shell=bash disable=SC2001,SC2120

#
# sources .EnvFile in current working or git top path, calls direnv hook and sources completions

[ "${BASH_SOURCE-}" ] || return

# <html><h2>Project Directory </h2>
# <p><strong><code>$PROJECT_DIR</code></strong>: if found on first line of EnvFile.</p>
# <p><strong><code>PROJECT_DIR=$PROJECT_DIR$</code></strong></p>
# </html>
export PROJECT_DIR

# <html><h2>Bash Prompt Command </h2>
# <p><strong><code>$PROMPT_COMMAND</code></strong>.</p>
# <p>If this variable is set, and is an array, the value of each set element is interpreted as a command to
# execute before printing the primary prompt ($PS1). If this is set but not an array variable, its value
# is used as a command to execute instead.</p>
# <a href="https://www.gnu.org/software/bash/manual/html_node/Controlling-the-Prompt.html">Controlling-the-Prompt</a>
# </html>
export PROMPT_COMMAND

# <html><h2>Super Project Repository Path </h2>
# <p><strong><code>$SUPER</code></strong>: always shows $TOP if it is not a submodule.</p>
# <p><strong><code>git rev-parse --show-superproject-working-tree --show-toplevel | head -1</code></strong></p>
# </html>
export SUPER

# <html><h2>Project Directory/Git Top Repository Path </h2>
# <p><strong><code>$TOP</code></strong>: alias of $PROJECT_DIR.</p>
# <p><strong><code>git rev-parse --show-toplevel</code></strong></p>
# </html>
export TOP

#######################################
# sources .EnvFile in current working or git top path, calls direnv hook and sources completions
# Globals:
#   __PATHENV_PREVIOUS_SUPER
#   __PATHENV_SET
#   PATH
#   PROJECT_DIR
#   PS1
#   SUPER
#   TOP
# Arguments:
#  None
# Returns:
#   $?
#######################################
pathenv() {
  local rc=$? basename EnvFile file function="pathenv" line project=false set tops tmp upper variable verbose=false
  set="$(grep -v "^rc=" <<< "${__PATHENV_SET-}")"
  __PATHENV_PREVIOUS_SUPER=${SUPER-}

  test $# -eq 0 || "${FUNCNAME[0]}.sh" "$@"

  if tops="$(git rev-parse --show-superproject-working-tree --show-toplevel 2>/dev/null)"; then
    project=true
    SUPER="$(echo "${tops}" | tail -1)"
    TOP="$(echo "${tops}" | head -1)"
  fi
  # TODO: no puedo cambiar todas las variables y funciones asi por asi, tienen que ser las que he cambiado yo haciendo algo aqui, o sea hay que guardar lo que he hecho y punto.
  if [ "${SUPER-}" != "${__PATHENV_PREVIOUS_SUPER}" ]; then
    __PATHENV_SET="$(set | grep -vE "^rc=|^set=|^BASH|")"
    if [ "${SUPER-}" ]; then
      basename="${SUPER##*/}"
      upper="${basename^^}"
    fi
    [ ! "${PS1-}" ] || >&2 echo "${function}: entering ${basename}"

    export PROJECT_DIR
    export SUPER
    export TOP
  fi

  if [ ! "${__PATHENV_SET-}" ]; then

    EnvFile="${SUPER:-.}/.EnvFile"

    if [ -f "${EnvFile}" ]; then
      [ ! "${PS1-}" ] || >&2 echo "${function}: loading $(echo "${EnvFile}" | sed "s|${HOME}|~|")"

      line=0
      if head -1 "${EnvFile}" | grep -q "=\$PROJECT_DIR\$$"; then
        variable="$(head -1 "${EnvFile}" | cut -d '=' -f 1)"
        [ "${variable}" = "PROJECT_DIR" ] || eval "export ${variable}=${PROJECT_DIR}"
        line=1
      fi
      eval "$(awk -v l=$line 'FNR > l { gsub("export ", ""); gsub("^", "export "); print }' "${EnvFile}")" || return
      PATH="$(echo "${PATH}" | tr ':' '\n' | uniq | tr '\n' ':' | sed 's/:$//')"
    fi
    ! test -d "${PROJECT_DIR}/bin" || [[ "${PATH}" =~ ${PROJECT_DIR}/bin: ]] || export PATH="${PROJECT_DIR}/bin:${PATH}"
  fi

  tmp="$(mktemp)"
  eval "$(direnv export bash 2>"${tmp}")"
  case "$(cat "${tmp}")" in
    *"direnv allow"*)
      direnv allow
      ${function}
      [ ! "${PS1-}" ] || >&2 echo "${function}: allowed"
      ;;
    *"direnv: loading"*)
      [ ! "${PS1-}" ] || grep -E "^direnv: loading|^direnv: export" "${tmp}"
      if [ "${PS1-}" ] && command -v complete >/dev/null; then
        for file in "${PROJECT_DIR}/etc/bash_completion.d"/*; do
          test -f "${file}" || break
          source "${file}" || return
        done <>/dev/null
      fi
      ;;
    *"direnv: unloading"*)
      [ ! "${PS1-}" ] || >&2 echo "${function}: unloading"
      eval echo "${__PATHENV_SET}" 2>&1 | grep -vE 'BASH|readonly' || true
      unset __PATHENV_SET
      ;;
    *) cat "${tmp}" ;;
  esac
  rm -f "${tmp}"

  return $rc
}

__PATHENV_PREVIOUS_SUPER=
__PATHENV_SET=

export -f pathenv

[[ "${PROMPT_COMMAND:-}" =~ pathenv ]] || PROMPT_COMMAND="pathenv${PROMPT_COMMAND:+; ${PROMPT_COMMAND}}"

if [ "${BASH_SOURCE[0]##*/}" = "${0##*/}" ]; then
  for arg; do
    case "${arg}" in
      -h|--help|help) code=0 ;;
      hook) cat "$0"; exit ;;
      *) >&2 echo -e "${0##*/}: ${arg}: invalid argument\n" ;;
    esac
  done
  >&2 cat << EOF
usage: . ${0##*/}
   or: ${0##*/} -h|-help|help

sources .EnvFile in current working or git super top path, calls direnv hook and sources completions

If VARIABLE=\$PROJECT_DIR\$ in first line of .EnvFile file, VARIABLE is also set to \$PROJECT_DIR.

\$PATH is updated with \$SUPER/bin if exists and no .EnvFile file is found .

Commands:
   -h, --help, help               display this help and exit
   hook                           display the hook script

Globals:
   PROJECT_DIR                    git top path or dirname of \$BASH_SOURCE or \$0, if VARIABLE=\$PROJECT_DIR\$.
   SUPER                          super project repository path, always shows \$TOP if it is not a submodule.
   TOP                            project directory/git top repository path.
EOF
  exit "${code:-1}"
fi

