# bashmemo

Bash の履歴に、よく使うコマンドのメモを読み込むための小さなスクリプトです。

[English version](README.md)

## Files

- `load_memo.sh`: メモを表示し、コマンド履歴へ追加します。
- `save_memo.sh`: メモファイルを `$EDITOR` で作成・編集します。
- `memofiles/`: メモファイルのデフォルト保存先です。

## Setup

`~/.bashrc` などに alias と、必要に応じて環境変数を追加します。

```bash
alias @='source /path/to/bashmemo/load_memo.sh'
alias @@='source /path/to/bashmemo/save_memo.sh'
alias @v='source /path/to/bashmemo/load_memo.sh -v'

# 任意: メモファイルの保存先を変更します。
MEMOFILES_DIR="$HOME/.local/share/bashmemo/memofiles"

# 任意: 使用するエディタを指定します。
EDITOR=nano
```

`/path/to/bashmemo` は、このリポジトリを置いた場所に置き換えてください。

`load_memo.sh` は現在のシェルの履歴にコマンドを追加するため、これらのスクリプトは `source` して使う前提です。

## Usage

メモを作成・編集します。

```bash
@@ etc
```

引数なしでメモ一覧を表示します。

```bash
@
```

この後は、ほとんど矢印キーと Enter だけで操作できます。

メモ名を指定すると、内容を表示して Bash の履歴に追加します。

```bash
@ etc
```

メモ名の前方一致検索もできます。

```bash
@ e
```

複数のメモが見つかった場合は、候補一覧を表示します。候補名も履歴に追加されるため、履歴検索やカーソル編集で呼び出しやすくなります。

表示だけして履歴に追加したくない場合は `-v` を使います。

```bash
@ -v etc
```

Setup 例の `@v` alias を使うこともできます。

```bash
@v etc
```

## Memo Format

メモファイルには、1 行に 1 コマンドを書きます。空行は読み込み時に無視されます。

例:

```text
ls
df -H --total
free
```

## Options

メモファイルの保存先は、環境変数 `MEMOFILES_DIR` で変更できます。

未指定の場合は、スクリプトと同じディレクトリにある `memofiles/` が使われます。
