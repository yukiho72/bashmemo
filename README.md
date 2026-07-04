# bashmemo

A small Bash tool that keeps your frequently used commands in plain-text memos and loads them into your Bash history on demand. Recall them with the ↑ key or `Ctrl+R`, tweak them, and run — no more retyping long commands or digging through old scrollback.

[日本語版はこちら](README.ja.md)

## How it works

1. **Save** commands you keep forgetting into a memo — a plain text file, one command per line:

   ```bash
   @@ docker    # opens the "docker" memo in your editor
   ```

2. **Load** the memo when you need it:

   ```console
   $ @ docker
   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
   docker system df
   docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | sort
   ```

3. **Run** — every line shown is now in your Bash history, as if you had just typed it. Press ↑ and the first command appears at your prompt; press ↑ again for the second. `Ctrl+R` search works too. Edit the command if you like, then press Enter.

bashmemo never executes anything on its own. It only displays commands and adds them to history — you decide what to run.

## Features

- **Plain text** — memos are ordinary text files: easy to edit, grep, back up, and sync.
- **Blends into your history** — loaded commands work with ↑ / ↓ / `Ctrl+R` exactly like commands you typed yourself.
- **Prefix search** — `@ d` matches `disk` and `docker`; the candidates are listed and also pushed to history, so you can pick one with ↑ and Enter.
- **View-only mode** — `@ -v <name>` shows a memo without touching your history.
- **No dependencies** — two small Bash scripts; nothing else to install.

## Requirements

- **Bash.** The scripts use Bash-specific features such as `history -s`, so zsh and other shells are not supported.
- `git` (for installation).
- Optional: the `column` command, which shows memo lists in multiple columns. Without it, lists are shown one name per line.

## Files

| File | Description |
| --- | --- |
| `load_memo.sh` | Shows memos and adds their commands to Bash history (used as `@`). |
| `save_memo.sh` | Creates/edits memo files with `$EDITOR` (`@@`) and appends history entries (`@+`). |
| `memofiles/` | Default memo directory, including sample memos (`git`, `docker`, `disk`, `net`, `memo`). |

## Setup

Clone this repository from GitHub and add the aliases to your `~/.bashrc` (or another Bash startup file):

```bash
# 1. Choose where to install bashmemo.
mkdir -p ~/scripts
cd ~/scripts

# 2. Clone the repository from GitHub.
git clone https://github.com/yukiho72/bashmemo.git

# 3. Add the bashmemo aliases to ~/.bashrc.
cat >> ~/.bashrc <<'EOF'

# bashmemo
alias @='source ~/scripts/bashmemo/load_memo.sh'
alias @@='source ~/scripts/bashmemo/save_memo.sh'
alias @+='source ~/scripts/bashmemo/save_memo.sh -a'
alias @v='source ~/scripts/bashmemo/load_memo.sh -v'
EOF

# 4. Reload ~/.bashrc in the current shell.
source ~/.bashrc

# 5. Try it — the bundled sample memos should be listed.
@
```

If you prefer SSH, replace the `git clone` command with:

```bash
git clone git@github.com:yukiho72/bashmemo.git
```

Notes:

- The scripts are designed to be run with `source`, and the aliases above do exactly that. A script executed normally runs in a child process and cannot add anything to your current shell's history (see [Under the hood](#under-the-hood)).
- If you install bashmemo somewhere other than `~/scripts/bashmemo`, adjust the paths in the aliases.
- `@`, `@@`, `@+`, and `@v` are just alias names. Rename them if you prefer something else.

### Optional configuration

By default, memos are stored in `memofiles/` inside the cloned repository. Setting `MEMOFILES_DIR` keeps your own memos outside the repository, where `git pull` will never touch them. You can also pick the editor `@@` uses:

```bash
# Add to ~/.bashrc, after the aliases:

# Store memo files outside the repository.
MEMOFILES_DIR="$HOME/.local/share/bashmemo/memofiles"

# Editor used by @@ (default: vi).
EDITOR=nano
```

Then create the directory — and copy the samples if you want to keep them:

```bash
mkdir -p ~/.local/share/bashmemo/memofiles
cp ~/scripts/bashmemo/memofiles/* ~/.local/share/bashmemo/memofiles/  # optional
source ~/.bashrc
```

## Usage

### Create or edit a memo: `@@ <name>`

```bash
@@ etc
```

Opens the memo `etc` in your editor (`$EDITOR`, default `vi`). Write one command per line, then save and quit — the file is created when you save. Memo names cannot contain `/` or wildcards and cannot start with `-`.

### List all memos: `@`

```console
$ @
*** memo list (matches: 5) ***
disk    docker  git     memo    net
```

Each listed name is also pushed to history as `@ <name>`. Press ↑ to bring up `@ disk`, ↑ again for `@ docker`, and so on — pick one and press Enter to load it. You rarely have to type a memo name yourself.

### Load a memo: `@ <name>`

```console
$ @ git
git log --oneline --graph --all -20
git diff --stat HEAD~1
git stash list
git branch -a --sort=-committerdate
git log --author="$(git config user.name)" --since="1 week ago" --oneline
```

The memo's commands are displayed and added to history in order: ↑ recalls the first line, ↑ ↑ the second, and so on. `Ctrl+R` search works as usual. Edit the recalled command however you like before running it.

### Search by prefix: `@ <prefix> ...`

An argument that isn't an exact memo name is treated as a name prefix:

```console
$ @ d
*** memo list (matches: 2) ***
disk    docker
```

- If exactly one memo matches, it is loaded right away — `@ do` loads `docker`.
- If several match, the candidates are listed and pushed to history as `@ <name>`: press ↑, pick one, press Enter.
- An exact name always wins: with memos `git` and `github`, `@ git` loads only `git`.
- Multiple prefixes are allowed: `@ d n` matches `disk`, `docker`, and `net`.
- If nothing matches, bashmemo prints `No memos yet. Use @@ to create one.`

### View without touching history: `@ -v` / `@v`

```bash
@ -v git   # display only; nothing is added to history
@v git     # same thing, using the alias
```

Useful for a quick look (or copying with the mouse) when you don't want to alter your history.

### Append without opening an editor: `@+`

Use `@+` when the command you want to save is already in your Bash history:

```bash
@+ git      # append the previous history entry
@+ git 100  # append history entry number 100
```

The target memo is created if it does not exist. Run `history` to see entry numbers.

## Command reference

| Command | What it does |
| --- | --- |
| `@` | List all memos and push `@ <name>` entries to history. |
| `@ <name>` | Show a memo and add each of its lines to history. |
| `@ <prefix> ...` | Prefix search: a single match loads immediately; multiple matches are listed. |
| `@ -v ...` | Any of the above, without adding anything to history. |
| `@v ...` | Alias for `@ -v ...`. |
| `@@ <name>` | Create or edit a memo with `$EDITOR`. |
| `@+ <name>` | Append the previous history entry to a memo. |
| `@+ <name> <number>` | Append a numbered history entry to a memo. |

## Memo format

Write one command per line, as plain text:

```text
df -h --total
du -sh * | sort -rh | head -20
free -h
```

- Empty lines are ignored when loading.
- Windows line endings (CRLF) are handled automatically.
- Lines go into history exactly as written and are never executed by bashmemo. A line starting with `#` does nothing when run, so it can serve as a label inside a memo.

## Sample memos

The repository ships with a few samples so you can try bashmemo immediately:

| Memo | Contents |
| --- | --- |
| `git` | Commit graph, diff stats, stashes, recent branches, your commits from the last week. |
| `docker` | Container status, disk usage, image sizes. |
| `disk` | Disk/memory usage and block devices. |
| `net` | Listening ports, interface addresses, external IP, ping test. |
| `memo` | Commands for looking after bashmemo itself (jump to the memo directory, edit `~/.bashrc`, …). |

## Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `MEMOFILES_DIR` | `memofiles/` next to the scripts | Where memo files live. `@@` creates the directory automatically if it is missing. |
| `EDITOR` | `vi` | Editor launched by `@@`. |

Because the scripts run inside your interactive shell (via `source`), setting these in `~/.bashrc` works without `export`.

## Under the hood

`load_memo.sh` relies on the Bash builtin `history -s`, which appends a line to the current shell's history without executing it. Only the shell itself can modify its own history — a normally executed script runs as a child process, and its history changes would vanish with it. That is why the aliases run the scripts with `source`. After each run, the scripts unset the functions they defined, leaving your shell clean.

## Troubleshooting

- **`@: command not found`** — the aliases aren't loaded yet. Run `source ~/.bashrc` or open a new terminal.
- **The memo is displayed, but ↑ doesn't recall its commands** — the script was probably executed directly (`bash load_memo.sh`). Use the aliases, or `source` the script.
- **`@@` opened an unfamiliar editor** — that's `vi` (quit with `Esc`, then `:q!`). Set `EDITOR=nano` (or your favorite editor) in `~/.bashrc`.
- **My memos seem to have vanished** — bashmemo only looks in the current `MEMOFILES_DIR`. Check it with `echo "$MEMOFILES_DIR"`, and move your memo files there if you changed it.
- **Does it work with zsh?** — No, bashmemo is Bash-only.

## License

MIT — see [LICENSE](LICENSE).
