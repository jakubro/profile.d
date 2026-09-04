# When something goes wrong

Indexed by what you see.

## `profile.d-install: command not found`

That name is an alias defined by one of profile.d's own `init` hooks, so it exists only in a shell that has already
loaded profile.d. Immediately after installing, your current shell has not:

```bash
\. ~/.bashrc
profile.d-install
```

If it is still missing after that, profile.d is not loading at all - see the next entry.

## A new shell has none of my configuration

Check that the entry point is in place and resolves:

```console
$ ls -l ~/.bashrc
lrwxrwxrwx. .bashrc -> /home/you/.profile.d/lib/home/.bashrc

$ cat ~/.profile.d/lib/src/include >/dev/null && echo ok
ok
```

A `~/.bashrc` that is a regular file means the symlink was replaced - by another installer, or by an editor that
followed and rewrote it. Re-run the installer to put it back; your file is kept as
`~/.bashrc.backup.<digits>`.

A `Too many levels of symbolic links` or `No such file` from the second command means the install is broken rather
than absent. Remove and reinstall:

```bash
rm -rf ~/.profile.d
curl https://raw.githubusercontent.com/jakubro/profile.d/main/bin/install | bash
\. ~/.bashrc
```

`~/.profiledrc` is not touched by that, so your plugin list survives.

## One plugin's hook never runs

In order of how often each is the cause:

1. **The plugin is not in `~/.profiledrc`**, or you have not run `profile.d-install` since adding it. Confirm with
   `ls ~/.profile.d/plugins/`.
2. **The filename starts with a dot.** Loading uses `*`, which skips dotfiles. Rename it.
3. **The file is called `README.md`.** That is the one name the loader always skips.
4. **It is in a directory that is not a stage.** The five are `hooks/pre-init`, `hooks/init`, `hooks/post-init`,
   `hooks/pre-prompt` and `hooks/post-prompt`. A typo like `hooks/pre_init` is simply never visited.

To see what would be loaded, list it the way the loader does:

```console
$ ls ~/.profile.d/plugins/*/hooks/init/
```

## A hook runs interactively but not in a script

`~/.bashrc` is sourced by bash for interactive shells. A plain `bash script.sh` sources nothing unless `BASH_ENV`
names a file, and profile.d does not set it. Either set it yourself, or stop relying on shell configuration in
non-interactive contexts - the second is usually right.

Note the asymmetry before concluding a hook never runs outside a terminal: a non-interactive **login** shell
(`bash -lc`, `su - user -c`) does read `~/.bash_profile`, which sources `~/.bashrc`, so the three shell stages run
there without `BASH_ENV`.

The prompt stages never run in a non-interactive shell even with `BASH_ENV` set. See
[interactive and non-interactive shells](lifecycle.md#interactive-and-non-interactive-shells).

## A syntax error on every new shell

Something in a `hooks/` directory is not bash. The loader sources every file it finds except `README.md`, so a
markdown or text file among your hooks produces an error at the top of every shell.

The message names the file. Move it out of `hooks/` - a plugin's own `README.md` is the one prose file that is safe
there.

## Updating a plugin fails in red

```
Failed to install https://github.com/jakubro/profile.d-pyenv
```

That one message covers every way installing a plugin can fail, so there are three candidates. Most often it is a
`git pull` that cannot fast-forward because files inside `~/.profile.d/plugins/<name>/` were edited in place - check
with `git -C ~/.profile.d/plugins/<name> status`. Failing that, it is the plugin's own `bin/install`: pyenv's compiles
a helper and exits non-zero when the build headers are missing, which a clean `git status` will not explain. Linking
the plugin's dotfiles is the third and by far the rarest.

Discard the changes, or keep them properly: clone the plugin yourself and switch the `~/.profiledrc` entry to that
path, which makes your checkout the plugin. See [managing plugins](plugins.md#two-kinds-of-entry).

The run continues past a failure, so other plugins in the same run did update.

## A plugin installed, but its command is missing

Some plugins wrap a tool they do not install - they configure it, and do nothing visible when it is absent, because a
hook that fails loudly would fail on every shell. [hstr](../plugins/hstr.md) is the clearest case: its install script
is a placeholder, and the binary has to come from your package manager.

Check the plugin's page for what it expects to find, then confirm the tool is on `PATH`.

## Everything is doubled after `. ~/.bashrc`

Re-sourcing `~/.bashrc` re-runs the three shell stages, and hooks that append rather than assign will append again -
a `PATH` entry twice over, an alias redefined, a banner printed a second time.

That is expected for `PATH`-appending hooks and harmless. If it is your own hook, make it idempotent:

```bash
case ":$PATH:" in
  *":$MY_DIR:"*) ;;
  *) export PATH="$MY_DIR:$PATH" ;;
esac
```

Open a new shell rather than re-sourcing when you want a clean check.

## My old `~/.profile` stopped being read

profile.d ships an inert `~/.profile` - a shebang and nothing else - and links it over yours, which is kept as
`~/.profile.backup.<digits>`. On a system where login shells read `~/.profile` for `PATH`, that content is now unused.

Move it into a plugin rather than editing the symlinked file, which is inside a checkout that updates over you. See
[folding your old configuration back in](dotfiles.md#folding-your-old-configuration-back-in).
