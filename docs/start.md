# Your first shell

This goes from a machine with nothing installed to a shell that loads a plugin you chose. It ends at a working prompt,
not at a command that printed something.

## Before you start

You need bash and a home directory you can write to. The installer also needs `git` and `curl`; if they are missing it
installs them through your system's package manager - `dnf`, `yum`, `apt`, `apt-get`, `pacman`, `apk`, `zypper` or
`brew`, whichever it finds. It prefixes that with `sudo` whenever `sudo` exists, which is a test of the command rather
than of who you are: as root on a machine that has it, the install still goes through `sudo`, and as an ordinary user
on a machine without it, the command runs bare and fails on permissions. If you would rather it did not touch your
package manager at all, install `git` and `curl` yourself first and it will skip the step entirely.

## 1. Install

```bash
curl https://raw.githubusercontent.com/jakubro/profile.d/main/bin/install | bash
\. ~/.bashrc
```

The script clones profile.d into `~/.profile.d/lib`, symlinks three files into your home directory, and writes an empty
config. Reading the output top to bottom:

```
===========================================================================================
profile.d
===========================================================================================
Installing from https://github.com/jakubro/profile.d...
Linking dotfiles into home directory...
'.bashrc' -> '/home/you/.profile.d/lib/home/.bashrc'
'.bash_profile' -> '/home/you/.profile.d/lib/home/.bash_profile'
'.profile' -> '/home/you/.profile.d/lib/home/.profile'
===========================================================================================
Successfully installed
===========================================================================================
Run the following command for the changes to take effect:
  \. ~/.bashrc
```

**If you already had a `~/.bashrc`, it has not been deleted.** It was renamed to `~/.bashrc.backup.<timestamp>` before
the symlink was made. The same applies to every file profile.d links into your home directory, now and later. See
[what happens to your dotfiles](guide/dotfiles.md), which also covers how to fold the old file back in.

## 2. Notice that nothing else happened

This first run installed no plugins, and that is not a failure. The installer writes `~/.profiledrc` as part of
setting itself up, and reads it in the same run - so on a first install it reads the file it just created, which is
empty:

```bash
#!/bin/bash
# https://github.com/jakubro/profile.d

PLUGINS=()
```

Every plugin, including the ones that ship in this project, is listed there by you. A fresh install is therefore a
shell with profile.d loaded and nothing loaded into it.

## 3. Choose a plugin

Add one entry. [pyenv](plugins/pyenv.md) is a good first pick because you can see it work in one command:

```bash
#!/bin/bash
# https://github.com/jakubro/profile.d

PLUGINS=(
  https://github.com/jakubro/profile.d-pyenv
)
```

The [available plugins](index.md#available-plugins) table lists the rest. An entry that looks like a URL is cloned; an
entry that looks like a path is symlinked from where it already is, which is what you want while writing your own.

## 4. Install it

```bash
profile.d-install
\. ~/.bashrc
```

`profile.d-install` is an alias profile.d defines for you, so it exists only in a shell that has already loaded it -
that is what the `\. ~/.bashrc` in step 1 was for. If the alias is not found, source `~/.bashrc` and try again.

The command re-reads `~/.profiledrc`, clones anything new, updates anything already there, and runs each plugin's own
install script. pyenv's compiles a small helper, so this one takes a minute.

## 5. Confirm

```console
$ pyenv --version
pyenv 2.4.7
```

That command works because the plugin's `init` hook put `~/.pyenv/bin` on your `PATH` and ran `pyenv init` - not
because anything was written to a startup file of yours. Nothing you own was edited. The whole of your configuration
is still the six lines of `~/.profiledrc`, which is a file worth committing somewhere.

## Where to go next

- Adding, updating, pinning and removing plugins: [managing plugins](guide/plugins.md).
- Which hook stage your own customisations belong in: [the hook lifecycle](guide/lifecycle.md).
- Writing your own plugin: [writing a plugin](guide/authoring.md).
- Something did not work: [when something goes wrong](guide/troubleshooting.md).
