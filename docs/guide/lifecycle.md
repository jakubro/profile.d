# The hook lifecycle

A hook is an executable-looking file in a plugin's `hooks/<stage>/` directory. profile.d sources it - it never runs it
as a program - so everything it does happens in your shell: exporting a variable, defining an alias, evaluating a
version manager's init snippet.

There are five stages. Three run once per shell, two run around every prompt.

| Stage | Runs | Use it for |
|---|---|---|
| `pre-init` | once per shell, first | Anything later stages depend on, and anything that must see the shell before profile.d has touched it |
| `init` | once per shell | Nearly everything: `PATH`, aliases, exports, version managers, completions |
| `post-init` | once per shell, last | Anything that must observe the finished environment - a banner, a summary, a consistency check |
| `pre-prompt` | before each prompt | Reading state the previous command left behind |
| `post-prompt` | before each prompt, after everything else | Recording state for the next shell - the working directory, a terminal title |

If you are unsure, use `init`. The other four exist for the cases where ordering against everything else matters, and
most customisations do not care.

## What runs when

```
~/.bashrc                                  a symlink into ~/.profile.d/lib/home/
  /etc/bashrc                              your distribution's, sourced first and never modified
  ~/.profile.d/lib/src/bashrc
      src/include                          defines the two loader functions
      hooks/pre-init                       stage 1
      hooks/init                           stage 2
      hooks/post-init                      stage 3

then, in an interactive shell only, around every prompt:
      hooks/pre-prompt                     stage 4
      <whatever PROMPT_COMMAND already held>
      hooks/post-prompt                    stage 5
```

The prompt stages are wired in by profile.d's own `pre-init` hook, which wraps `PROMPT_COMMAND` rather than replacing
it - anything your distribution or another tool had put there still runs, in the middle, untouched.

Both prompt stages run *before* the prompt is printed; bash evaluates the whole of `PROMPT_COMMAND` and only then
expands `PS1`. `post-prompt` is post relative to the entries already in the array, not to the prompt.

## The ordering rule

Within one stage, profile.d loads **its own hooks first, then each plugin's, in alphabetical order of the plugin's
directory name**. A plugin's directory name is the last path segment of its `~/.profiledrc` entry, so
`https://github.com/jakubro/profile.d-nvm` becomes `profile.d-nvm`.

With the six published plugins installed, every `init` hook in `profile.d-autojump` runs before every `init` hook in
`profile.d-direnv`, and so on down to `profile.d-pyenv`.

**The order of entries in `~/.profiledrc` has no effect on load order.** That file says which plugins you want, not
when they run. Reordering it changes nothing.

Inside a single plugin, files load in the order the shell's `*` glob returns them, which is alphabetical. This is why
hook files are conventionally given numeric prefixes:

```
hooks/init/01-path
hooks/init/50-docker
hooks/init/90-completions
```

Those prefixes order files **within that one plugin only**. They cannot move a plugin's hook ahead of a different
plugin's - nothing can, short of renaming the plugin. If your plugin has to run after another one, say so in its
README; if it has to run before profile.d's own hooks, it cannot.

## Interactive and non-interactive shells

Bash sources `~/.bashrc` for interactive shells. A plain non-interactive shell - `bash script.sh`, a cron entry -
sources nothing unless `BASH_ENV` names a file, and profile.d does not set `BASH_ENV`.

A non-interactive **login** shell is the exception, and it is a common one: `bash -lc`, `su - user -c`, and some ssh
and cron invocations all read `~/.bash_profile`, which profile.d installs and which sources `~/.bashrc` with no
interactivity check. All three shell stages run there.

Wherever the three shell stages run, the two prompt stages still do not: they are registered behind a check for the
interactive flag, and a shell with no prompt never reaches them.

The practical consequence for a hook author is that `init` runs in both kinds of shell. If your hook is only meaningful
at a prompt - a keybinding, a banner, anything that writes to the terminal - guard it:

```bash
#!/bin/bash

if [[ $- == *i* ]]; then
  bind '"\C-g": "git status\C-j"'
fi
```

## Two ways a hook silently does not run

**A file whose name begins with a dot.** Loading uses `*`, which does not match dotfiles. This is deliberate - it is
what lets `.gitkeep` hold an empty stage directory in git without being sourced - but it also means a hook named
`.local-overrides` is skipped without a word.

**A `README.md` in a stage directory.** It is the one filename the loader skips by name, so that a plugin can document
its hooks in place. **Every other file is sourced, whatever its extension.** A `NOTES.md` next to your hooks is fed to
bash as a shell script, and markdown is not valid bash. Keep prose out of `hooks/`.

The exact contract - what the loader does with directories, what your hook can rely on being defined, and what is
already in scope - is in the [hook reference](../reference/hooks.md).
