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
  # History keeps the line as typed, so a renamed alias is only recognized
  # through BASHMEMO_APPEND_ALIAS.
  [[ "$command" == "${BASHMEMO_APPEND_ALIAS:-@+}"* ]] ||
    [[ "$command" == source\ *save_memo.sh\ -a* ]] ||
    [[ "$command" == source\ *save_memo.sh\ --append* ]] ||
    [[ "$command" == .\ *save_memo.sh\ -a* ]] ||
    [[ "$command" == .\ *save_memo.sh\ --append* ]]
}

# Read `history` output from stdin into _memo_hist_nums/_memo_hist_cmds.
# Entry lines are "%5d%c %s", where %c is '*' once the entry has been edited.
# Any other line is the continuation of a multi-line entry and is joined to
# the previous command with a newline.
_save_memo_read_history() {
  _memo_hist_nums=()
  _memo_hist_cmds=()
  local entry_re='^[[:space:]]*([0-9]+)(\*| )[[:space:]](.*)$'
  local raw last
  while IFS= read -r raw; do
    last=$(( ${#_memo_hist_cmds[@]} - 1 ))
    if [[ "$raw" =~ $entry_re ]]; then
      # A continuation line can also look like an entry line. Real entry
      # numbers are consecutive, so treat anything else as a continuation.
      if [ "$last" -lt 0 ] || [ "${BASH_REMATCH[1]}" -eq $(( _memo_hist_nums[last] + 1 )) ]; then
        _memo_hist_nums+=("${BASH_REMATCH[1]}")
        _memo_hist_cmds+=("${BASH_REMATCH[3]}")
        continue
      fi
    fi
    if [ "$last" -ge 0 ]; then
      _memo_hist_cmds[last]+=$'\n'"$raw"
    fi
  done
}

_save_memo_reject_multiline() {
  local number="$1" command="$2"
  # Memo files hold one command per line, so multi-line entries cannot be stored.
  if [[ "$command" == *$'\n'* ]]; then
    { echo2 "error: Cannot append a multi-line command (history entry $number)."; } >&2
    return 1
  fi
}

_save_memo_previous_history() {
  local i
  _save_memo_read_history < <(HISTTIMEFORMAT='' builtin history 20)

  for (( i=${#_memo_hist_cmds[@]}-1; i>=0; i-- )); do
    _save_memo_is_append_command "${_memo_hist_cmds[i]}" && continue
    _save_memo_reject_multiline "${_memo_hist_nums[i]}" "${_memo_hist_cmds[i]}" || return 1
    printf '%s\n' "${_memo_hist_cmds[i]}"
    return 0
  done

  { echo2 "error: No previous history entry found."; } >&2
  return 1
}

_save_memo_numbered_history() {
  local target="$1"
  if ! [[ "$target" =~ ^[1-9][0-9]*$ ]]; then
    { echo2 "error: History number must be a positive integer."; } >&2
    return 1
  fi

  _save_memo_read_history < <(HISTTIMEFORMAT='' builtin history)

  local count=${#_memo_hist_nums[@]}
  if [ "$count" -eq 0 ]; then
    { echo2 "error: No history entries found."; } >&2
    return 1
  fi

  local histbeg="${_memo_hist_nums[0]}"
  local last_num="${_memo_hist_nums[count-1]}"
  if [ "$target" -lt "$histbeg" ] || [ "$target" -gt "$last_num" ]; then
    { echo2 "error: History entry $target out of range (available: $histbeg - $last_num)."; } >&2
    return 1
  fi

  local i
  for (( i=count-1; i>=0; i-- )); do
    if [ "${_memo_hist_nums[i]}" = "$target" ]; then
      _save_memo_reject_multiline "$target" "${_memo_hist_cmds[i]}" || return 1
      printf '%s\n' "${_memo_hist_cmds[i]}"
      return 0
    fi
  done

  { echo2 "error: History entry $target not found."; } >&2
  return 1
}

_save_memo_append_line() {
  local memo="$1"
  local command="$2"

  command="${command%$'\r'}"
  if [ -z "$command" ]; then
    echo2 "error: Nothing to append."
    return 1
  fi

  # Keep the one-command-per-line format even if the file lacks a final newline.
  if [ -s "$memo" ] && [ -n "$(tail -c 1 "$memo")" ]; then
    printf '\n' >> "$memo" || return 1
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
  unset _memo_hist_nums _memo_hist_cmds
  unset -f deco_on deco_off echo2 _save_memo _save_memo_validate_name _save_memo_edit _save_memo_append_usage _save_memo_is_append_command _save_memo_read_history _save_memo_reject_multiline _save_memo_previous_history _save_memo_numbered_history _save_memo_append_line _save_memo_append _memo_main
  return "$status"
}

_memo_main "$@"
