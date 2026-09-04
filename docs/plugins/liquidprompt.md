# liquidprompt

Installs and activates [liquidprompt](https://github.com/nojhan/liquidprompt), a prompt that shows what is true right
now and stays quiet about the rest - a battery reading only when you are on battery, a git branch only inside a
repository, a load average only when the machine is busy.

## Enable it

```bash
PLUGINS=(
  https://github.com/jakubro/profile.d-liquidprompt
)
```

```bash
profile.d-install
\. ~/.bashrc
```

## What it does

**At install time** it clones liquidprompt into `~/.liquidprompt` from its `stable` branch, or `git pull`s it if the
directory is already there. It tracks `stable` rather than the default branch, so updates are releases.

**In every interactive shell** it sources `~/.liquidprompt/liquidprompt`, which takes over `PS1`. Nothing happens in a
non-interactive shell.

## Using it

There is nothing to run. The prompt replaces itself and adapts to context - it shortens the path when the path is
long, marks a directory you cannot write to, shows the exit code of a command that failed, and adds a git branch and
dirty marker inside a repository.

Two commands are worth knowing:

```console
$ prompt_off      # back to the plain prompt, this shell only
$ prompt_on       # and back again
```

## Configuring it

liquidprompt reads `~/.liquidpromptrc`, which this plugin does not ship - without one you get liquidprompt's own
defaults, which show more than most people want. Create it to turn features off and set colours:

```bash
# ~/.liquidpromptrc
LP_ENABLE_LOAD=0
LP_ENABLE_BATT=0
LP_ENABLE_TIME=1
LP_ENABLE_SHORTEN_PATH=1
LP_PATH_LENGTH=15
```

Every variable is listed in
[liquidprompt's own configuration reference](https://liquidprompt.readthedocs.io/en/stable/config.html). A file you
write there is yours - profile.d neither creates nor overwrites it - so it is worth keeping in a plugin of your own
alongside your other dotfiles. See [writing a plugin](../guide/authoring.md#shipping-dotfiles).

## Requirements

None beyond bash and git. Individual prompt features read from tools that may not be present - `battery`, `sensors`,
version-control binaries - and each is simply omitted when its source is missing.
