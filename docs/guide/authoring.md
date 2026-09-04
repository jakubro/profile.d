# Writing a plugin

A plugin is a directory with up to four things in it. None is required, and most plugins use one or two.

```
my-plugin/
  bin/install          run once per profile.d-install, as a separate bash process
  hooks/<stage>/       sourced into every shell
  home/                symlinked into the user's home directory
  README.md            never sourced, wherever it appears
```

That is the whole interface. There is no manifest, no metadata file, and no registration step beyond naming the
directory in `~/.profiledrc`.

## Develop it as a path, not a URL

Point at your working tree before you publish anything:

```bash
PLUGINS=(
  ~/work/my-plugin
)
```

profile.d symlinks a path entry rather than cloning it, so your edits are live in the next shell. Run
`profile.d-install` once to create the link, then just open a new shell - or `\. ~/.bashrc` - after every change.
Switch the entry to a URL when you publish, and nothing else changes.

## A first hook

The smallest useful plugin is one file:

```bash
mkdir -p ~/work/my-plugin/hooks/init
cat > ~/work/my-plugin/hooks/init/01-editor <<'EOF'
#!/bin/bash

export EDITOR=nano
export VISUAL=nano
EOF
```

The shebang is convention, not requirement - the file is sourced, never executed - but it is what tells your editor
and `shellcheck` to treat the extensionless file as bash.

Numeric prefixes order files within your plugin. They cannot order your plugin against another one; see
[the hook lifecycle](lifecycle.md#the-ordering-rule).

## Choosing a stage

Use `init` unless you have a reason not to. The five stages and what each is for are in
[the hook lifecycle](lifecycle.md); the precise loading contract is in the
[hook reference](../reference/hooks.md).

Two rules that catch people:

- **Guard anything that only makes sense at a prompt.** `init` also runs in non-interactive shells - always in a
  login shell such as `bash -lc`, and in a plain one when `BASH_ENV` is set - where a `bind` call or a banner is at
  best noise. Wrap it in `if [[ $- == *i* ]]; then ... fi`.
- **Do not put prose in `hooks/`.** Every file there is sourced except `README.md`. A `TODO.md` beside your hooks is
  handed to bash as a script.

## Depending on a tool that may not be installed

`__profile_d_load__` sources a path if it exists and does nothing if it does not, which covers most cases in one line:

```bash
#!/bin/bash

__profile_d_load__ ~/.cargo/env
```

For anything conditional on a command rather than a file, test for it:

```bash
#!/bin/bash

if command -v direnv &>/dev/null; then
  eval "$(direnv hook bash)"
fi
```

A hook that fails loudly at shell start is worse than one that quietly does nothing, because it fires on every shell
and there is no obvious place to look. Fail silently in hooks; report problems from `bin/install`, which the user is
watching.

## The install script

`bin/install` runs on every `profile.d-install`, including runs where nothing about your plugin changed. **It must be
safe to re-run** - there is no first-run flag.

```bash
#!/bin/bash

if [ ! -d ~/.my-tool ]; then
  log_info "Installing my-tool..."
  git clone --quiet https://github.com/someone/my-tool ~/.my-tool || exit 1
else
  log_info "Updating my-tool..."
  cd ~/.my-tool || exit 1
  git pull --quiet || exit 1
fi
```

`log_info` and its siblings, plus `has`, `mklink` and `rm_backup`, are provided by the installer. The
[hook reference](../reference/hooks.md#what-is-in-scope) lists them with their signatures, and notes which of the
installer's own variables you do **not** get.

Exit non-zero to report failure. profile.d prints your plugin's name in red and carries on with the others.

## Shipping dotfiles

Anything in `home/` except `README.md` is symlinked into the user's home directory, one level deep. A real file
already at that path is backed up first; one that is already a symlink is replaced with no backup. Prefer individual
files - `home/.direnvrc` claims one path, `home/.config` claims all of `~/.config`. See
[what happens to your dotfiles](dotfiles.md#plugins-link-dotfiles-too).

## Publishing

Push it anywhere `git clone` can reach and give people the URL to add to `PLUGINS`. The directory name profile.d uses
is the last segment of that URL, and it is also what decides load order, so name the repository for what it does.

Your `README.md` is the only documentation a user gets, and the loader skips that filename wherever it appears - so
you can put one in `hooks/init/` beside your hooks without it being sourced.
