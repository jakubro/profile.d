# Hook reference

The exact contract a plugin is loaded under. [The hook lifecycle](../guide/lifecycle.md) is the narrative version;
this page is the detail.

## The loader

Two functions, defined in `src/include` and sourced into every shell before any hook runs.

### `__profile_d_load__ <path>`

- **A file** is sourced, unless its basename is exactly `README.md`.
- **A directory** has each of its entries passed back to `__profile_d_load__`, recursively, in `*` glob order.
- **Anything else** - a path that does not exist, a dangling symlink - is ignored without a message.

`*` does not match names beginning with a dot, so dotfiles at any depth are skipped. That is what lets a `.gitkeep`
hold an empty stage directory in git.

`README.md` is the only name treated specially. Every other file is sourced whatever its extension, so a stage
directory is not a place to keep notes.

The function is available inside hooks, and plugins use it to source a third-party script that may not be present:

```bash
#!/bin/bash

__profile_d_load__ ~/.cargo/env
```

That is a one-line replacement for a guarded `source`, because a missing path is a no-op.

### `__profile_d_load_stage__ <stage>`

Loads `~/.profile.d/lib/<stage>` first, then `<plugin>/<stage>` for each entry of `~/.profile.d/plugins/*` in glob
order. `<stage>` is a path relative to a plugin root, always one of the five `hooks/...` directories.

## Stages

| Stage | Sourced from | When |
|---|---|---|
| `hooks/pre-init` | `src/bashrc` | Once per shell, before `init` |
| `hooks/init` | `src/bashrc` | Once per shell |
| `hooks/post-init` | `src/bashrc` | Once per shell, after `init` |
| `hooks/pre-prompt` | `PROMPT_COMMAND` | Before each prompt, interactive shells only |
| `hooks/post-prompt` | `PROMPT_COMMAND` | Before each prompt but after the pre-existing `PROMPT_COMMAND` entries, interactive shells only |

The prompt stages are registered by profile.d's own `hooks/pre-init/01-register-prompt-hooks`, which rebuilds
`PROMPT_COMMAND` as `(pre-prompt hook, <whatever it already held>, post-prompt hook)`. The original value is cached, so
re-sourcing `~/.bashrc` re-registers rather than accumulating.

Bash runs every `PROMPT_COMMAND` entry *before* it expands and prints `PS1`, so neither stage runs after a prompt has
appeared. `post-prompt` is named for its position in the array, not its position relative to the prompt: it is the
last thing to run before the prompt you are about to see.

## What is in scope

**In a hook**, sourced into your interactive shell:

- `__profile_d_load__` and `__profile_d_load_stage__`.
- Everything earlier stages and earlier plugins have defined. A plugin cannot rely on a *later* plugin.
- Nothing else. The logging functions below belong to install time and are not defined in your shell.

**In a plugin's `bin/install`**, run as a separate `bash` process during installation:

| Function | Effect |
|---|---|
| `log_header <text>` | Blue banner: a rule, the text, another rule |
| `log_info <text>` | Green |
| `log_warn <text>` | Yellow |
| `log_error <text>` | Red, to stderr |
| `log_debug <text>` | Gray |
| `has <command>` | True when the command exists |
| `is_uri <string>` | True when the string matches `<scheme>://<rest>` |
| `mklink <source> <target> [-f]` | Symlink `target` to `source`. An existing target that is itself a symlink is unlinked with no backup, `-f` or not; a real file or directory is backed up, or removed outright with `-f` |
| `rm_backup <path>` | Resolve `path`, then rename what it resolves to `<resolved>.backup.<epoch seconds>`. Given a symlink this renames the target and leaves the link dangling |
| `has_flag <flag> <args>` | True when `args` contains `flag` |

These reach the child process because the installer exports them. Its *variables* are not exported, so `$LIB_PATH` and
`$PLUGINS_PATH` are empty in your install script - write `~/.profile.d/lib` and `~/.profile.d/plugins` out.

## Directories a plugin may contain

| Path | Handled by | Effect |
|---|---|---|
| `bin/install` | installation | Run with `/bin/bash` after the plugin is cloned or linked, on every `profile.d-install` |
| `hooks/<stage>/` | every shell | Sourced, per the table above |
| `home/` | installation | Each entry except `README.md` symlinked into your home directory |
| `README.md` | nothing | Skipped by the loader wherever it appears, and never linked out of `home/` |

`home/` is linked one level deep. `home/.gitconfig` links that file; `home/.config` links the **whole directory**,
replacing whatever `~/.config` was - after backing it up. Ship individual files unless you mean to own the directory.

## Idempotence

`profile.d-install` runs every plugin's `bin/install` every time, including plugins that were already installed and
unchanged. There is no first-run flag and no way to opt out. An install script must therefore be safe to re-run: check
before you clone, prefer update over reinstall, and do not assume you are running for the first time.
