# bashmemo

A small Bash memo tool that loads frequently used commands into your Bash history.

[日本語版はこちら](README.ja.md)

## Files

- `load_memo.sh`: Displays memos and adds commands to Bash history.
- `save_memo.sh`: Creates or edits memo files with `$EDITOR`.
- `memofiles/`: Default directory for memo files.

## Setup

Clone this repository from GitHub, then add aliases and optional environment
variables to your `~/.bashrc` or another Bash startup file.

```bash
# 1. Choose where to install bashmemo.
mkdir -p ~/scripts
cd ~/scripts

# 2. Clone the repository from GitHub.
git clone https://github.com/yukiho72/bashmemo.git

# 3. Add bashmemo aliases to ~/.bashrc.
cat >> ~/.bashrc <<'EOF'

# bashmemo
alias @='source ~/scripts/bashmemo/load_memo.sh'
alias @@='source ~/scripts/bashmemo/save_memo.sh'
alias @v='source ~/scripts/bashmemo/load_memo.sh -v'

# Optional: change where memo files are stored.
MEMOFILES_DIR="$HOME/.local/share/bashmemo/memofiles"

# Optional: choose your editor.
EDITOR=nano
EOF

# 4. Create the memo directory if you use MEMOFILES_DIR above.
mkdir -p ~/.local/share/bashmemo/memofiles

# 5. Reload ~/.bashrc in the current shell.
source ~/.bashrc
```

If you prefer SSH, replace the `git clone` command with:

```bash
git clone git@github.com:yukiho72/bashmemo.git
```

If you install bashmemo somewhere other than `~/scripts/bashmemo`, update the paths
in the aliases.

These scripts are intended to be used with `source`, because `load_memo.sh` adds commands to the current shell's history.

## Usage

Create or edit a memo:

```bash
@@ etc
```

Show the memo list:

```bash
@
```

After loading the list, most operations can be done with the arrow keys and Enter.

Load a memo by name. Its contents are displayed and added to Bash history:

```bash
@ etc
```

Search memos by name prefix:

```bash
@ e
```

If multiple memos match, bashmemo displays the candidates. Candidate commands are also added to history, so you can recall and edit them with history navigation.

Use `-v` to view a memo without adding its contents to history:

```bash
@ -v etc
```

Or use the `@v` alias from the setup example:

```bash
@v etc
```

## Memo Format

Write one command per line in each memo file. Empty lines are ignored when loading.

Example:

```text
ls
df -H --total
free
```

## Options

Set `MEMOFILES_DIR` to change where memo files are stored.

If `MEMOFILES_DIR` is not set, bashmemo uses the `memofiles/` directory next to the scripts.
