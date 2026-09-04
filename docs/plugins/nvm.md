# nvm

Installs and activates [nvm](https://github.com/nvm-sh/nvm), which installs Node.js versions per user and switches
between them per shell.

## Enable it

```bash
PLUGINS=(
  https://github.com/jakubro/profile.d-nvm
)
```

```bash
profile.d-install
\. ~/.bashrc
```

## What it does

**At install time**, on a machine with no `~/.nvm`, it runs nvm's official install script pinned at `v0.39.5`. Once
`~/.nvm` exists, every later run instead fetches tags and checks out the newest one - so an existing install moves to
current nvm, while a fresh install starts at the pinned version and catches up on its second update.

**In every shell** it exports `NVM_DIR=~/.nvm` and sources `nvm.sh` and nvm's bash completion, but only if `~/.nvm`
exists. Unlike most of the plugins this one is not restricted to interactive shells, so `nvm` and `node` resolve in a
script too - when profile.d is loaded there at all, which needs `BASH_ENV`. See
[interactive and non-interactive shells](../guide/lifecycle.md#interactive-and-non-interactive-shells).

## Using it

```console
$ nvm ls-remote --lts      # what is available
$ nvm install 24           # install one
$ nvm use 24               # for this shell
$ nvm alias default 24     # for new shells
$ nvm exec 22 node --version
```

A `.nvmrc` file holding a version makes `nvm use` argument-free inside that directory:

```console
$ echo 24 > .nvmrc
$ nvm use
Now using node v24.9.0
```

nvm does not read `.nvmrc` on its own when you enter a directory. To get that, drive it from
[direnv](direnv.md#use-node-version---rootdir): `use node` in an `.envrc` reads `.nvmrc`, installs the version if it
is missing, and restores dependencies.

## Requirements

`curl` and `git`, both of which profile.d already ensures. Building native modules later needs a compiler toolchain,
which nvm does not install.

If you also use [direnv](direnv.md), note that its `use node` clears nvm's `default` alias whenever it installs a
version - see that plugin's [known issues](direnv.md#known-issues).
