# Managing plugins

`~/.profiledrc` is the whole of your configuration. It is a bash script that sets one array:

```bash
#!/bin/bash
# https://github.com/jakubro/profile.d

PLUGINS=(
  https://github.com/jakubro/profile.d-direnv
  https://github.com/jakubro/profile.d-pyenv
  ~/work/my-own-plugin
)
```

Nothing else in it is read. It is sourced, so you can compute the list if you want to - a hostname check that adds a
plugin only on your laptop is a normal thing to write there - but the array is the only output that matters.

Every change to the file takes effect the same way:

```bash
profile.d-install
\. ~/.bashrc
```

## Two kinds of entry

An entry is treated as a URL when it looks like `<scheme>://<something>`, and as a path otherwise. The difference is
not cosmetic:

| Entry | What installation does | On the next `profile.d-install` |
|---|---|---|
| `https://github.com/jakubro/profile.d-pyenv` | Clones it into `~/.profile.d/plugins/profile.d-pyenv` | `git pull` in that clone |
| `~/work/my-own-plugin` | Symlinks `~/.profile.d/plugins/my-own-plugin` to it | Nothing - the symlink already points at your working tree |

The path form is what you want while writing a plugin: your edits are live in the next shell, with no reinstall and no
copy to keep in step. See [writing a plugin](authoring.md).

The directory name under `~/.profile.d/plugins/` is the last segment of the entry, and that name decides load order.
[The hook lifecycle](lifecycle.md#the-ordering-rule) covers why, and why the order of lines in `~/.profiledrc` does
not.

## Adding one

Add the line, run the two commands above. Installation clones the plugin, symlinks anything in its `home/` directory
into yours, and runs its `bin/install`.

That last step is why adding a plugin can take a while: `profile.d-pyenv` compiles a helper, `profile.d-autojump`
clones and runs an installer of its own. The output names each plugin as it goes.

## Updating

The same command. `profile.d-install` pulls every plugin installed from a URL and re-runs every plugin's
`bin/install`, whether or not anything changed.

A plugin whose update fails does not stop the others - the failure is reported in red and the run continues. The usual
cause is a `git pull` that cannot fast-forward because you edited files inside
`~/.profile.d/plugins/<name>/`. Either discard those changes, or move the plugin to the path form and keep your work
in your own checkout.

## Removing one

Delete its line from `~/.profiledrc` and run `profile.d-install`. At the end of every run, profile.d compares what is
in `~/.profile.d/plugins/` against what your config asks for, and removes anything unlisted.

**Removal is not gentle.** A plugin installed from a URL is deleted outright, not backed up, along with anything you
left inside its directory. A plugin installed from a path is only unlinked, so your working tree is untouched - the
one case where the path form protects you.

Two things removal does not undo. Files the plugin's `bin/install` wrote outside its own directory - `~/.pyenv`,
`~/.nvm`, `~/.autojump` - stay where they are; delete them yourself if you want them gone. And dotfiles it linked into
your home directory stay linked, now pointing at a directory that no longer exists. See
[what happens to your dotfiles](dotfiles.md#removing-a-plugin-leaves-its-dotfiles-behind).

## Pinning a version

There is no version, tag or branch syntax. A URL entry tracks its repository's default branch and moves forward every
time you update.

If you need a fixed version, clone it yourself, check out what you want, and point at it by path:

```bash
PLUGINS=(
  ~/work/profile.d-pyenv     # git checkout v1.2.0 in there; nothing will move it
)
```

## Where things live

| Path | Contents |
|---|---|
| `~/.profiledrc` | Your configuration. The only file you edit |
| `~/.profile.d/lib/` | profile.d itself |
| `~/.profile.d/plugins/<name>/` | One directory or symlink per plugin |
| `~/.bashrc`, `~/.bash_profile`, `~/.profile` | Symlinks into `~/.profile.d/lib/home/` |
| `~/<anything>.backup.<digits>` | A file profile.d replaced. See [dotfiles](dotfiles.md) |
