# What happens to your dotfiles

Installing profile.d replaces three files in your home directory with symlinks, and each plugin you add may replace
more. A real file is kept under a new name, but a file that was **already a symlink** is deleted outright - see
[your originals are kept](#your-originals-are-kept). This page is what that means and how to get your old
configuration back into the new arrangement.

## The three files profile.d owns

| File | Becomes a symlink to | Contents |
|---|---|---|
| `~/.bashrc` | `~/.profile.d/lib/home/.bashrc` | Sources `/etc/bashrc`, then profile.d |
| `~/.bash_profile` | `~/.profile.d/lib/home/.bash_profile` | Sources `~/.bashrc` |
| `~/.profile` | `~/.profile.d/lib/home/.profile` | A shebang and nothing else |

The first two are a handful of lines each and exist to hand control to the loader. The third does nothing at all -
profile.d does not use `~/.profile`, and ships an inert one so that nothing else can either.

## Your originals are kept

Before replacing a real file, profile.d renames it to `<name>.backup.<epoch seconds>`:

```console
$ ls -la ~ | grep bashrc
lrwxrwxrwx.  .bashrc -> /home/you/.profile.d/lib/home/.bashrc
-rw-r--r--.  .bashrc.backup.1756500000
```

Three properties worth knowing, and the first is the one that can lose work.

**The rename happens only for a real file.** If the target is already a symlink it is unlinked and replaced, with no
backup and no record of where it pointed. That is what stops `profile.d-install` littering your home directory with a
new backup on every run - but it also means an existing `~/.bashrc` that was itself a link into your own dotfiles
repository is removed silently. Check for that before the first install; the link target itself is untouched.

**The timestamp is seconds since the epoch**, so backups sort chronologically. Two backups of the same path within
one second would overwrite each other, which the code does not guard against.

**A backup follows the file, not the name.** The rename resolves symlinks first, so where the thing being replaced is
a link, the backup appears beside its target rather than beside the link.

`~/.profile` is the one to check. A real `~/.profile` on a login-shell system may have been carrying your `PATH`, and
its replacement does nothing. If you had one, its contents are in `~/.profile.backup.<digits>` and are no longer being
read by anything.

## Folding your old configuration back in

Do not edit the symlinked files. They are inside `~/.profile.d/lib`, which is a git checkout that
`profile.d-install` updates - your edits will be overwritten or will block the next update.

Put your customisations in a plugin of your own instead:

```bash
mkdir -p ~/work/my-dotfiles/hooks/init
cp ~/.bashrc.backup.1756500000 ~/work/my-dotfiles/hooks/init/01-legacy
```

Then add `~/work/my-dotfiles` to `~/.profiledrc` and run `profile.d-install`. The file is now sourced at the `init`
stage of every shell, exactly as it used to be, and it is somewhere you can put under version control.

Two things to fix as you go. Strip anything that re-sources `~/.bashrc` or `~/.profile`, which would now recurse. And
split the file up - the point of the arrangement is that `PATH` and your aliases and your version managers stop being
one file. [Writing a plugin](authoring.md) covers the layout.

## Plugins link dotfiles too

A plugin may ship a `home/` directory, and every entry in it except `README.md` is linked into your home directory on
installation, under the same backup rule. `profile.d-direnv` ships a `~/.direnvrc` this way.

Linking is one level deep, and that has a consequence worth checking before you install an unfamiliar plugin: a plugin
shipping `home/.gitconfig` claims that one file, but a plugin shipping `home/.config` claims **your entire `~/.config`
directory**, moving whatever was there to `~/.config.backup.<digits>` and symlinking the plugin's in its place.

To see what a plugin will claim before installing it, list that directory in its repository:

```console
$ ls -a ~/.profile.d/plugins/profile.d-direnv/home
.  ..  .direnvrc
```

## Removing a plugin leaves its dotfiles behind

Removing a plugin deletes it from `~/.profile.d/plugins/`, but the symlinks it put in your home directory stay,
pointing at a path that no longer exists. A tool that reads such a file usually treats it as absent rather than
erroring - direnv does this with `~/.direnvrc` - so the symptom is configuration quietly going missing.

After removing a plugin, check for dangling links and delete them:

```console
$ find ~ -maxdepth 1 -xtype l
/home/you/.direnvrc
```

Your original, if you had one, is still in the matching `.backup.<digits>` file.

## Uninstalling profile.d

There is no uninstall command. To undo it by hand:

```bash
rm ~/.bashrc ~/.bash_profile ~/.profile          # the three symlinks
mv ~/.bashrc.backup.<digits> ~/.bashrc           # and the other two, if you had them
rm -rf ~/.profile.d ~/.profiledrc
find ~ -maxdepth 1 -xtype l -delete              # dotfiles linked by plugins, now dangling
```

The order of the last two matters. `-xtype l` matches only links that fail to resolve, so while
`~/.profile.d` still exists every plugin-linked dotfile is still valid and the `find` deletes nothing.

That leaves what plugins installed elsewhere - `~/.pyenv`, `~/.nvm`, `~/.autojump`, `~/.liquidprompt` and the like.
Remove those separately.
