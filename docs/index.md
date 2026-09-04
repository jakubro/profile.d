# profile.d

profile.d is a plugin manager for your bash startup files.

Everything your shell does on the way to a prompt - setting `PATH`, defining aliases, activating a version manager,
drawing the prompt itself - lives in a plugin. A plugin is a directory with a fixed layout, usually a git repository.
You list the ones you want in a single file, run one command, and profile.d fetches them, links their dotfiles into
your home directory, and sources their hooks in a defined order every time a shell starts.

The point is that a `.bashrc` grown over ten years is one file nobody wants to touch. Split across plugins, each piece
is separately installable, separately versionable, and separately removable - and the ordering between them stops being
an accident of what got appended last.

Your `~/.profiledrc` is the whole configuration:

```bash
#!/bin/bash

PLUGINS=(
  https://github.com/jakubro/profile.d-direnv
  https://github.com/jakubro/profile.d-pyenv
  ~/work/my-own-plugin
)
```

An entry that looks like a URL is cloned. Anything else is treated as a path on this machine and symlinked, so a plugin
you are writing is live in the next shell with no reinstall. See [managing plugins](guide/plugins.md).

## What a shell start looks like

```
~/.bashrc                          symlink into ~/.profile.d/lib/home/
  /etc/bashrc                      your distribution's, first and untouched
  ~/.profile.d/lib/src/bashrc
      hooks/pre-init/              before anything is configured
      hooks/init/                  the bulk: PATH, aliases, version managers, completions
      hooks/post-init/             after everything is configured
```

Each stage runs profile.d's own hooks first, then every plugin's, and a plugin can contribute to any stage or none. Two
further stages - `pre-prompt` and `post-prompt` - run around each prompt rather than once per shell.
[The hook lifecycle](guide/lifecycle.md) covers all five and the ordering rule between them.

## Two ways in

**You want to use it.** Start with [your first shell](start.md), which goes from nothing to a working install with one
plugin in it. Then [managing plugins](guide/plugins.md) for adding, updating and removing them,
[what happens to your dotfiles](guide/dotfiles.md) for what installation does to the files already in your home
directory, and [when something goes wrong](guide/troubleshooting.md) when it does.

**You want to write a plugin.** [Writing a plugin](guide/authoring.md) walks the four directories a plugin may contain
and what each one is for. [Hook reference](reference/hooks.md) is the exact contract: which stage runs when, what is
in scope, and the shell functions your install script may call.

## Available plugins

| Plugin | Integrates | For |
|---|---|---|
| [autojump](plugins/autojump.md) | [autojump](https://github.com/wting/autojump) | Jumping to a directory by name instead of path |
| [direnv](plugins/direnv.md) | [direnv](https://direnv.net/) | Per-directory environments, plus `use node`, `use python` and three more |
| [hstr](plugins/hstr.md) | [hstr](https://github.com/dvorka/hstr) | Searchable shell history on Ctrl-r |
| [liquidprompt](plugins/liquidprompt.md) | [liquidprompt](https://github.com/nojhan/liquidprompt) | An adaptive prompt |
| [nvm](plugins/nvm.md) | [nvm](https://github.com/nvm-sh/nvm) | Node.js versions |
| [pyenv](plugins/pyenv.md) | [pyenv](https://github.com/pyenv/pyenv) | Python versions |

profile.d is bash-only. The prompt stages are built on `PROMPT_COMMAND` arrays and the plugins wrap bash-oriented
tools; there is no zsh implementation and adding one would be a separate project rather than a port.
