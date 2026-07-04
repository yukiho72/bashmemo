#!/bin/bash

# ==============================================================================
# Memo Management System - save_memo.sh (@@, @+)
# Copyright (c) 2026 yukiho72
# Licensed under the MIT License.
# ==============================================================================

# --- Shared output styling helpers ---
deco_on()  { [ -t 1 ] && printf "\e[1;33m"; }
deco_off() { [ -t 1 ] && printf "\e[m"; }
echo2()    { deco_on; printf "%s" "$*"; deco_off; printf "\n"; }

_save_memo(){
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || return 1
  local default_path="$script_dir/memofiles"
  : "${MEMOFILES_DIR:=$default_path}"
  local path="$MEMOFILES_DIR"

  if ! mkdir -p "$path" 2>/dev/null; then
    echo2 "error: Failed to create directory $path"
    return 1
  fi

  if [[ "$1" == "-a" ]] || [[ "$1" == "--append" ]]; then
    shift
    _save_memo_append "$path" "$@"
    return
  fi

  _save_memo_edit "$path" "$@"
}

_save_memo_validate_name() {
  local memoname="$1"
  if [[ "$memoname" == *"/"* ]]; then echo2 "error: Memo name cannot contain '/'."; return 1; fi
  if [[ "$memoname" == -* ]]; then echo2 "error: Memo name cannot start with '-'."; return 1; fi
  if [[ "$memoname" == "." ]] || [[ "$memoname" == ".." ]]; then echo2 "error: Invalid memo name."; return 1; fi
  if [[ "$memoname" == *"*"* ]] || [[ "$memoname" == *"?"* ]] || [[ "$memoname" == *"["* ]] || [[ "$memoname" == *"]"* ]]; then
    echo2 "error: Wildcards (*, ?, [, ]) are not allowed."
    return 1
  fi
}

_save_memo_edit() {
  local path="$1"
  shift

  if [ $# -ne 1 ]; then
    echo2 "usage: @@ memoname"
    return 1
  fi

  local memoname="$1"
  _save_memo_validate_name "$memoname" || return 1

  local memo="$path/$memoname"

  ${EDITOR:-vi} "$memo"
}

_save_memo_append_usage() {
  echo2 "usage:"
  echo2 "  @+ memoname"
  echo2 "  @+ memoname history-number"
}

_save_memo_is_append_command() {
  local command="$1"
  [[ "$command" == @+* ]] || [[ "$command" == source\ *save_memo.sh\ -a* ]] || [[ "$command" == source\ *save_memo.sh\ --append* ]]
}

_save_memo_parse_history_line() {
  local raw="$1"
  if [[ "$raw" =~ ^[[:space:]]*([0-9]+)[[:space:]]+(.*)$ ]]; then
    _memo_history_number="${BASH_REMATCH[1]}"
    _memo_history_command="${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
}

_save_memo_previous_history() {
  local raw command=""
  while IFS= read -r raw; do
    _save_memo_parse_history_line "$raw" || continue
    _save_memo_is_append_command "$_memo_history_command" && continue
    command="$_memo_history_command"
  done < <(HISTTIMEFORMAT='' history 20)

  if [ -z "$command" ]; then
    { echo2 "error: No previous history entry found."; } >&2
    return 1
  fi

  printf '%s\n' "$command"
}

_save_memo_numbered_history() {
  local target="$1"
  if ! [[ "$target" =~ ^[1-9][0-9]*$ ]]; then
    { echo2 "error: History number must be a positive integer."; } >&2
    return 1
  fi

  local raw command histbeg="" last_num="" found=""
  while IFS= read -r raw; do
    _save_memo_parse_history_line "$raw" || continue
    [ -z "$histbeg" ] && histbeg="$_memo_history_number"
    last_num="$_memo_history_number"

    if [ "$_memo_history_number" = "$target" ]; then
      command="$_memo_history_command"
      found=true
    fi
  done < <(HISTTIMEFORMAT='' history)

  if [ -z "$histbeg" ]; then
    { echo2 "error: No history entries found."; } >&2
    return 1
  fi

  if [ "$target" -lt "$histbeg" ] || [ "$target" -gt "$last_num" ]; then
    { echo2 "error: History entry $target out of range (available: ${histbeg:-1} - $last_num)."; } >&2
    return 1
  fi

  if [ -z "$found" ]; then
    { echo2 "error: History entry $target not found."; } >&2
    return 1
  fi

  printf '%s\n' "$command"
}

_save_memo_append_line() {
  local memo="$1"
  local command="$2"

  command="${command%$'\r'}"
  if [ -z "$command" ]; then
    echo2 "error: Nothing to append."
    return 1
  fi

  printf '%s\n' "$command" >> "$memo" || return 1
  echo2 "+ $command"
  echo2 "appended 1 line."
}

_save_memo_append() {
  local path="$1"
  shift

  if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    _save_memo_append_usage
    return 1
  fi

  local memoname="$1"
  shift
  _save_memo_validate_name "$memoname" || return 1

  local memo="$path/$memoname"
  local command

  if [ $# -eq 0 ]; then
    command="$(_save_memo_previous_history)" || return 1
  else
    command="$(_save_memo_numbered_history "$1")" || return 1
  fi

  _save_memo_append_line "$memo" "$command"
}

_memo_main() {
  _save_memo "$@"
  local status=$?
  unset _memo_history_number _memo_history_command
  unset -f deco_on deco_off echo2 _save_memo _save_memo_validate_name _save_memo_edit _save_memo_append_usage _save_memo_is_append_command _save_memo_parse_history_line _save_memo_previous_history _save_memo_numbered_history _save_memo_append_line _save_memo_append _memo_main
  return "$status"
}

_memo_main "$@"
