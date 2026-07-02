#!/bin/bash

# ==============================================================================
# Memo Management System - load_memo.sh (@)
# Copyright (c) 2026 yukiho72
# Licensed under the MIT License.
# ==============================================================================

# 装飾の一括管理
deco_on()  { printf "\e[1;33m"; }
deco_off() { printf "\e[m"; }
echo2()    { deco_on; printf "%s" "$*"; deco_off; printf "\n"; }

_load_memo(){
  local default_path="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)/memofiles"
  local path="${MEMOFILES_DIR:-$default_path}"
  local save_history=true

  # --- オプション解析 (-v: Viewモード) ---
  if [[ "$1" == "-v" ]]; then
    save_history=false
    shift
  fi

  # バリデーション（ディレクトリトラバーサル防止など）
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

# --- ファイルリストの取得 ---
  local files=()
  local old_nullglob=$(shopt -p nullglob)
  shopt -s nullglob

  if [ $# -eq 0 ]; then
    # 1. 引数なし：全リスト表示
    files=( "$path"/* )
  elif [ $# -eq 1 ] && [ -f "$path/$1" ]; then
    # 2. 完全一致するメモが memofiles 内にある場合は最優先
    files=( "$path/$1" )
  else
    # 3. それ以外：引数を「検索ワード」として処理
    for arg in "$@"; do
      # memofiles 内でワイルドカード検索
      files+=( "$path"/$arg* )
    done
  fi
  eval "$old_nullglob"

  # --- 判定ロジック ---
  local num_files=${#files[@]}

  if [ $num_files -eq 0 ]; then
    # 検索に使用した元の引数を表示すると分かりやすいため $* を活用
    #echo2 "No memo found matching '$*'."
    echo2 "No memo found"
    return
  elif [ $num_files -eq 1 ]; then
    # --- 1. 展開モード ---
    local memo="${files[0]}"
    # ... (既存のファイル読み込み・履歴保存処理) ...
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
    return

  else
    # --- 2. 検索・一覧表示モード (複数ヒットした場合) ---
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
}

_load_memo "$@"
status=$?
unset -f deco_on deco_off echo2 _load_memo
return "$status"
