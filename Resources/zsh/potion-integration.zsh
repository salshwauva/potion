# Potion command tracking.
#
# Emits OSC 133 semantic prompt markers (A prompt start, B input start,
# C execution start, D command finished with exit code), an OSC 9001 report
# carrying the command line, and OSC 7 working-directory reports. The host app
# reads these to build a command timeline. Active only inside Potion, and only
# once per shell.

[[ -n $POTION_INTEGRATION_LOADED ]] && return
[[ -z $POTION ]] && return
POTION_INTEGRATION_LOADED=1

autoload -Uz add-zsh-hook

__potion_report_cwd() {
  local host=${HOST:-localhost}
  print -n -- $'\e]7;file://'"${host}${PWD}"$'\a'
}

__potion_precmd() {
  local exit_code=$?
  if [[ -n $POTION_CMD_ACTIVE ]]; then
    print -n -- $'\e]133;D;'"${exit_code}"$'\a'
    unset POTION_CMD_ACTIVE
  fi
  __potion_report_cwd
  print -n -- $'\e]133;A\a'
}

__potion_preexec() {
  print -n -- $'\e]133;C\a'
  local encoded
  encoded=$(print -rn -- "$1" | base64 | tr -d '\n')
  print -n -- $'\e]9001;'"${encoded}"$'\a'
  POTION_CMD_ACTIVE=1
}

add-zsh-hook precmd __potion_precmd
add-zsh-hook preexec __potion_preexec

# Append the input-start marker (OSC 133;B) to the prompt as a zero-width
# segment. Applied once so a static prompt keeps it across redraws.
if [[ $POTION_PS1_MARKED != 1 ]]; then
  PS1="${PS1}"$'%{\e]133;B\a%}'
  POTION_PS1_MARKED=1
fi
