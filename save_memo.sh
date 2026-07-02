#!/bin/bash

# ==============================================================================
# Memo Management System - save_memo.sh (@@)
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

  if [ $# -ne 1 ]; then
    echo2 "usage: @@ memoname"
    return 1
  fi

  local memoname="$1"
  if [[ "$memoname" == *"/"* ]]; then echo2 "error: Memo name cannot contain '/'."; return 1; fi
  if [[ "$memoname" == -* ]]; then echo2 "error: Memo name cannot start with '-'."; return 1; fi
  if [[ "$memoname" == "." ]] || [[ "$memoname" == ".." ]]; then echo2 "error: Invalid memo name."; return 1; fi
  if [[ "$memoname" == *"*"* ]] || [[ "$memoname" == *"?"* ]]; then echo2 "error: Wildcards (*, ?) are not allowed."; return 1; fi

  local memo="$path/$memoname"

  ${EDITOR:-vi} "$memo"
}

_memo_main() {
  _save_memo "$@"
  local status=$?
  unset -f deco_on deco_off echo2 _save_memo _memo_main
  return "$status"
}

_memo_main "$@"
