#!/bin/bash

# ==============================================================================
# Memo Management System - load_memo.sh (@)
# Copyright (c) 2026 yukiho72
# Licensed under the MIT License.
# ==============================================================================

# Shared output styling helpers.
deco_on()  { [ -t 1 ] && printf "\e[1;33m"; }
deco_off() { [ -t 1 ] && printf "\e[m"; }
echo2()    { deco_on; printf "%s" "$*"; deco_off; printf "\n"; }

_load_memo(){
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || return 1
  local default_path="$script_dir/memofiles"
  : "${MEMOFILES_DIR:=$default_path}"
  local path="$MEMOFILES_DIR"
  local save_history=true

  # --- Option parsing (-v: view mode, without saving to history) ---
  if [[ "$1" == "-v" ]]; then
    save_history=false
    shift
  fi

  # Validate arguments to prevent directory traversal and wildcard expansion.
  for arg in "$@"; do
    if [[ "$arg" == *"/"* ]] || [[ "$arg" == ".." ]] || [[ "$arg" == "." ]]; then
      echo2 "error: Invalid characters in argument."
      return 1
    fi
    if [[ "$arg" == *"*"* ]] || [[ "$arg" == *"?"* ]] || [[ "$arg" == *"["* ]] || [[ "$arg" == *"]"* ]]; then
      echo2 "error: Wildcards (*, ?, [, ]) are not allowed."
      return 1
    fi
  done

  # --- Build the matching file list ---
  local files=()
  local old_nullglob
  old_nullglob=$(shopt -p nullglob)
  shopt -s nullglob

  if [ $# -eq 0 ]; then
    # 1. No arguments: show all memo files.
    files=( "$path"/* )
  elif [ $# -eq 1 ] && [ -f "$path/$1" ]; then
    # 2. Exact memo name matches take priority.
    files=( "$path/$1" )
  else
    # 3. Otherwise, treat arguments as search prefixes.
    for arg in "$@"; do
      # Search memo files by prefix inside the memo directory.
      files+=( "$path"/"$arg"* )
    done
  fi
  eval "$old_nullglob"

  # --- Decide how to display the result ---
  local num_files=${#files[@]}

  if [ "$num_files" -eq 0 ]; then
    # Use $* here if you want to show the original search query.
    #echo2 "No memo found matching '$*'."
    echo2 "No memos yet. Use @@ to create one."
  elif [ "$num_files" -eq 1 ]; then
    # --- Single memo mode ---
    local memo="${files[0]}"
    # Read non-empty lines, normalize CRLF endings, and optionally save them to history.
    local lines=()

    while IFS= read -r raw_line || [ -n "$raw_line" ]; do
      local line="$raw_line"
      line="${line%$'\r'}"
      [ -z "$line" ] && continue
      lines+=("$line")
    done < "$memo"

    for (( i=0; i<${#lines[@]}; i++ )); do echo2 "${lines[$i]}"; done
    
    if $save_history; then
      for (( i=${#lines[@]}-1; i>=0; i-- )); do history -s "${lines[$i]}"; done
    fi

  else
    # --- Search/list mode for multiple matches ---
    local file_names=()
    for f in "${files[@]}"; do file_names+=("${f##*/}"); done

    echo2 "*** memo list (matches: $num_files) ***"

    deco_on
    if command -v column >/dev/null 2>&1; then
      printf '%s\n' "${file_names[@]}" | column
    else
      printf '%s\n' "${file_names[@]}"
    fi
    deco_off

    if $save_history; then
      for (( i=${#file_names[@]}-1; i>=0; i-- )); do history -s "@ ${file_names[$i]}"; done
    fi
  fi

  return
}

_memo_main() {
  _load_memo "$@"
  local status=$?
  unset -f deco_on deco_off echo2 _load_memo _memo_main
  return "$status"
}

_memo_main "$@"
