# hstr

Configures bash history for volume and cross-session safety, and binds Ctrl-r to
[hstr](https://github.com/dvorka/hstr), a full-screen searchable view of it.

Four history settings apply as soon as the plugin is enabled. Everything else - the Ctrl-r binding and the
cross-session synchronisation - waits until the `hstr` binary is on `PATH`.

## Enable it

```bash
PLUGINS=(
  https://github.com/jakubro/profile.d-hstr
)
```

```bash
profile.d-install
\. ~/.bashrc
```

You must install hstr yourself - see [Requirements](#requirements).

## What it does

**At install time**, nothing. See [Known issues](#known-issues).

**In every interactive shell** it applies four history settings:

| Setting | Effect |
|---|---|
| `shopt -s histappend` | Appends to `~/.bash_history` instead of overwriting it, so two shells no longer discard each other's history on exit |
| `HISTCONTROL=ignorespace` | A command typed with a leading space is not recorded |
| `HISTFILESIZE=500000` | Up from bash's default of 500 |
| `HISTSIZE=500000` | The in-memory list, matched to the file |

Then, **only if `hstr` is on `PATH`**, it sets `HSTR_CONFIG=hicolor,raw-history-view`, binds Ctrl-r to hstr, and adds
`history -a; history -n` to the front of `PROMPT_COMMAND` so each command is written to the history file and re-read
from it at every prompt. That last part is what makes a command run in one terminal searchable from another
immediately, rather than after both have exited.

## Using it

Press <kbd>Ctrl</kbd>+<kbd>r</kbd>, type to filter, arrow keys to move, Enter to run. Ctrl-r again cycles the match
strategy between exact, regex and keyword.

To keep a command out of your history, type it with a leading space:

```console
$ ls -la                       # recorded
$  curl -H "Authorization: ..."  # leading space: not recorded
```

## Requirements

**hstr itself, which this plugin does not install.** From your distribution:

```bash
sudo dnf install hstr          # Fedora family
sudo apt install hstr          # Debian family
brew install hh                # macOS
```

Without it, the history settings still apply and Ctrl-r keeps bash's built-in reverse search. That is the whole
symptom - there is no error - so if Ctrl-r looks unchanged after installing this plugin, check that `hstr` is on
`PATH`.

## Known issues

**The install script is a placeholder.** It prints `Installing/Updating hstr...`, does nothing, and prints a line
telling you to ignore the instructions above it. It has never installed hstr; the binary has to come from your
package manager.
