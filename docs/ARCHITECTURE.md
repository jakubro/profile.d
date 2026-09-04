# Architecture

Internal notes for working on profile.d itself. For using it, start at [what profile.d is](index.md).

## Layout

| Path | Contents |
|---|---|
| `bin/install` | The installer. Also the update command, and the only file with real logic in it |
| `src/include` | The two loader functions, sourced into every shell |
| `src/bashrc` | The shell entry point: sources `include`, then runs the three shell stages |
| `home/` | `.bashrc`, `.bash_profile`, `.profile` - symlinked into the user's home directory |
| `hooks/<stage>/` | profile.d's own hooks, loaded before any plugin's |
| `examples/` | A sample `.profiledrc` and an empty plugin skeleton |
| `tests/` | A containerised install test and two unit tests |
| `docs/`, `site/` | This documentation and the Astro project that publishes it |

## Loading

`~/.bashrc` is a symlink to `home/.bashrc`, which sources `/etc/bashrc` and then `src/bashrc`. That sources
`src/include` and calls `__profile_d_load_stage__` for `hooks/pre-init`, `hooks/init` and `hooks/post-init`.

`__profile_d_load_stage__ <stage>` loads `lib/<stage>` and then `plugins/*/<stage>`. `__profile_d_load__` recurses
directories in glob order and sources every file except `README.md`. Both are in `src/include`, and both are the whole
of the loading mechanism - there is no registry, no ordering metadata and no dependency resolution.

The two prompt stages are not driven from `src/bashrc`. `hooks/pre-init/01-register-prompt-hooks` rebuilds
`PROMPT_COMMAND` as `(pre-prompt hook, <previous value>, post-prompt hook)`, guarded on the shell being interactive.
It caches the previous value in `__PROFILE_D_INITIAL_PROMPT_COMMAND__` and tests for that cache with `declare -p`
rather than by reading its first element - an initially empty `PROMPT_COMMAND` caches as an empty array, which a
first-element test cannot distinguish from an absent cache, and re-caching the already-wrapped value doubles both
hooks on the first reload. `tests/test-prompt-hooks.sh` covers it.

Both hooks run before the prompt: bash evaluates the whole of `PROMPT_COMMAND` and only then expands `PS1`. The
`post-prompt` stage is last in the array, not after the prompt.

## Installing

`main` runs four steps in order:

1. `install_prerequisites` - ensures `git` and `curl`, through whichever of eight package managers is present.
2. `install_lib` - resolves where profile.d itself should come from, puts it at `~/.profile.d/lib`, links `home/`,
   and writes `~/.profiledrc` if absent.
3. `install_plugins` - sources `~/.profiledrc` and installs each entry of `PLUGINS`.
4. `uninstall_plugins` - removes anything under `~/.profile.d/plugins/` that `PLUGINS` no longer names. The name it
   compares must not share a variable with the loop that collects the configured names: bash `local` is scoped to the
   function, so reusing it would leave the test comparing the last configured entry against itself, and nothing would
   ever be removed.

Step 2 writing the config that step 3 reads is why a first install lands no plugins: the file it reads is the empty
one it has just created.

`install_dir` is shared between the lib and the plugins. A source matching `<scheme>://<rest>` is cloned, or `git
pull`ed if the target exists; anything else is symlinked. It refuses to link a path onto itself, because `mklink`
removes its target before linking and a self-targeting install would delete the tree.

### Resolving where the installer came from

`get_lib_remote` decides between "I am a checkout, install from here" and "I was fetched, clone from GitHub". The
naive test - whether `BASH_SOURCE[0]` is empty - does not work, because **read inside a function it holds the string
`main` under a pipe**, never the empty string it holds at top level. The check is therefore two-part: the path must
name an existing file, and the directory above the one holding it must contain `src/include`. Either alone is
insufficient - `main` names no file, but a stray file by that name in the working directory would still resolve to
some directory. `tests/test-install.sh` covers both invocation shapes, the piped one from two working directories.

## Linking dotfiles

`link_dotfiles` symlinks each entry of a `home/` directory into `~`, one level deep, skipping `README.md`. `mklink`
unlinks an existing symlink outright and renames an existing real file to `<name>.backup.<epoch>`. Plugins go through
the same function, so a plugin's `home/` behaves exactly like profile.d's.

The one-level-deep rule means a directory in `home/` is claimed whole. That is deliberate - it is what lets a plugin
own a config tree - but it is worth knowing before adding one.

## Tests

`tests/test.sh <image>` runs the suite in a container against a distribution image; `tests/test-entrypoint.sh` is what
runs inside it, and calls the two unit tests before doing a real install, an update, and a direnv exercise.

`tests/test-install.sh` covers `get_lib_remote`, `install_dir`'s refusal to link a path onto itself, and which plugins
`uninstall_plugins` decides to remove; it sources `bin/install` with `PROFILE_D_DEFINE_ONLY` set, which suppresses the
call to `main`, and drives the removal cases against a throwaway `$HOME`. `tests/test-prompt-hooks.sh` sources the
prompt-hook registration file directly inside an interactive shell, since the hook is a no-op without one.

```console
$ tests/test.sh fedora
$ tests/test.sh ubuntu
```

Nothing is wired to CI beyond the documentation build - the install tests need a container and a package manager, and
`tests/test.sh` is the way to run them.
