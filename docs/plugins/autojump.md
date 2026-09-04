# autojump

Installs and activates [autojump](https://github.com/wting/autojump), which learns the directories you visit and lets
you return to one by a fragment of its name instead of its path.

## Enable it

```bash
PLUGINS=(
  https://github.com/jakubro/profile.d-autojump
)
```

```bash
profile.d-install
\. ~/.bashrc
```

## What it does

**At install time** it clones autojump into a temporary directory and runs its installer with
`SHELL=bash ./install.py -d ~/.autojump`, then deletes the temporary clone. The installer prints setup instructions
for a manual install; profile.d has already done that part, and says so.

**In every interactive shell** it sources `~/.autojump/share/autojump/autojump.bash`, which defines `j` and hooks the
directory database into `cd`. It then runs `j --purge`, dropping entries for directories that no longer exist.

Both steps are skipped in a non-interactive shell.

## Using it

There is nothing to configure. Use `cd` as you always have, and the database builds itself:

```console
$ cd /var/log/nginx
```

Later, from anywhere:

```console
$ j nginx
/var/log/nginx
```

Matching is on a fragment of the path, weighted by how often and how recently you have been there, so the more you
use `cd` the better the guesses get. Other subcommands:

```console
$ j -s            # the database, with each directory's weight
$ j --purge       # drop entries for directories that no longer exist
$ jo nginx        # open the match in a file manager
```

A fresh install knows nothing and `j` will not find anything until you have visited a few directories normally.

## Requirements

Python, for autojump's installer and for autojump itself. The install script does not check for it and does not
install it - if Python is missing, the run fails with the installer's own error.

## Known issues

**Every update is a fresh install.** The install script clones autojump and runs its installer on every
`profile.d-install`, with no check for whether it is already present or unchanged. Nothing breaks, but a run that
should have been a no-op clones a repository and re-runs a Python installer.
