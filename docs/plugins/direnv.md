# direnv

Installs and activates [direnv](https://direnv.net/), which loads and unloads environment variables as you change
directory, and adds five `use` commands of its own for the cases a bare `.envrc` handles badly.

This is the largest of the plugins: the extra commands set up whole language environments, so most of this page is
their reference.

## Enable it

```bash
PLUGINS=(
  https://github.com/jakubro/profile.d-direnv
)
```

```bash
profile.d-install
\. ~/.bashrc
```

## What it does

**At install time** it runs direnv's own install script with `bin_path=~/.local/bin`, so the binary lands somewhere
already on your `PATH` - profile.d puts `~/.local/bin` there at the `init` stage.

**In every shell** it evaluates `direnv hook bash`, in interactive shells only.

**In your home directory** it links a `~/.direnvrc`, which is what loads the five commands below into every `.envrc`
you write.

## A first `.envrc`

```bash
# .envrc
use default root

use node 24
use python 3.13.1
use dotenv
```

```console
$ direnv allow
```

That gets you Node 24 and Python 3.13.1 installed if missing, a `.venv` created and activated, both dependency sets
restored, and `.env` loaded - re-checked every time you enter the directory, and undone when you leave.

## `use default [root]`

Boilerplate every `.envrc` wants.

- Sources the nearest `.envrc` above this one, so a subdirectory inherits its parent's environment. Pass `root` to
  stop that - use it in the topmost `.envrc`, and in `~/.envrc`.
- Sources `.envrc.private` from this directory if it exists, which is where secrets go. Keep it out of git.
- Warns when `.envrc` differs from a committed `.envrc.template`, which is how a team notices the template moved.
- With `root`, watches `~/.direnvrc` and the plugin itself, so editing either reloads every environment.

## `use node [<version>] [--root=<dir>]`

Activates Node and restores dependencies.

```bash
use node                  # version from .nvmrc
use node 24
use node --root=./app     # the project is in a subdirectory
```

Installs [nvm](https://github.com/nvm-sh/nvm) if it is missing, installs the requested Node version if nvm does not
have it, then installs dependencies: `npm install` when there is a `package-lock.json`, otherwise `yarn install` when
there is a `yarn.lock` or a `package.json`. `yarn` is installed globally if needed.

Watches `package.json`, `package-lock.json` and `yarn.lock`, so a changed manifest reloads the environment.

Installing a version here clears nvm's `default` alias - see [Known issues](#known-issues).

## `use python [<version>] [--root=<dir>] [--upgrade-pip] [--write-requirements]`

Activates Python in a virtual environment and restores dependencies.

```bash
use python                        # version from .pvmrc
use python 3.13.1
use python --root=./src
use python --upgrade-pip          # upgrade pip inside the venv
use python --write-requirements   # rewrite requirements.txt if the install changed anything
```

Installs [pyenv](pyenv.md) if it is missing, builds the requested version if pyenv does not have it, creates `.venv`
in the project directory, and activates it. Dependencies come from `requirements.txt` if present - installed with
`--no-deps`, so the file is treated as a complete lock rather than a set of top-level requirements - otherwise from
`pyproject.toml` or `setup.py`, installed as `pip install --editable ".[dev]"`.

Three things worth knowing:

- **The version file is `.pvmrc`, not `.python-version`.** Without a version argument and without `.pvmrc`, it stops
  with an error rather than guessing.
- **An existing `.venv` is reused, never rebuilt.** If it was made with a different Python, you get a warning naming
  both versions and the environment keeps working. Delete `.venv` to move it.
- **Builds are tuned for the machine that runs them.** Python is compiled with `--enable-optimizations --with-lto`
  and `-march=native -mtune=native`, which is faster to run and slower to build - and not portable to a different
  CPU, which matters if you share `~/.pyenv` across machines.

## `use dotenv [<file>] [--root=<dir>] [--no-overwrite]`

Loads a `.env` file into the environment.

```bash
use dotenv                  # .env
use dotenv .env.local
use dotenv --no-overwrite   # keep variables that are already set
```

The file is sourced with `allexport`, so it is a shell script, not a `KEY=VALUE` parser - quoting and expansion behave
as bash. The file is watched, so editing it reloads.

If `.env` is absent but `.env.vault` is present, it decrypts the vault into `.env` first using `$DOTENV_KEY` or a
`.env.key` file, installing `dotenv-vault` globally through npm if needed.

## `use aws_secret_env <name> [--overwrite] [--profile=<p>] [--region=<r>]`

Exports every key of an AWS Secrets Manager secret as an environment variable.

```bash
use aws_secret_env myapp/database
use aws_secret_env myapp/database --profile=staging --region=us-east-1
```

Key names are uppercased, so a secret key `db_host` is exported as `DB_HOST`. Null and empty values are skipped.

Two limits worth knowing before you rely on it, both in [known issues](#known-issues): a key containing a space fails
the whole `.envrc` rather than being converted, and `--overwrite` does not do what its absence implies.

Needs the AWS CLI and `jq` on `PATH`, and credentials the CLI can find. This one reaches the network on every
directory entry, so it is noticeably slower than the others.

## Dependency caching

`use node` and `use python` skip restoring dependencies when nothing has changed. The check hashes each manifest and
stores the hash under `~/.cache/profile.d/plugins/direnv/`; a cached entry is stale when the hash differs **or when it
is more than seven days old**, so a project you have not touched in a week reinstalls once.

For Node, a missing `node_modules` also invalidates the cache, so deleting it forces a clean install. Deleting `.venv`
does the same for Python.

## Logging

Set `__PROFILE_D_DIRENV_LOG_LEVEL__` before entering a directory: `0` debug, `1` info (the default), `2` warnings,
`3` errors only. Every line already names the handler that emitted it; debug adds a per-step elapsed time and lines
the columns up, which is the way to find out why entering a directory is slow.

```console
$ __PROFILE_D_DIRENV_LOG_LEVEL__=0 direnv reload
```

## Requirements

`curl` for installation. `jq` and the AWS CLI for `use aws_secret_env` only. nvm and pyenv are installed on demand, so
they are not prerequisites - though installing [pyenv](pyenv.md) as a plugin instead gets you the
[build dependencies](pyenv.md#requirements) documented in one place.

## Known issues

**`use node` clears nvm's `default` alias whenever it installs a version.** The intent was to undo nvm making the
first version you install the global default, and only in that case - but the check for an existing default cannot
see one, so it fires every time. If a bare `node` outside your projects stops resolving after direnv installed a
version for one of them, set it again:

```console
$ nvm alias default 24
```

**`use python` reads `.pvmrc`, not `.python-version`.** pyenv's own file is ignored here, so a project already using
`pyenv local` needs the version named in `.envrc` or duplicated into `.pvmrc`.

**`use aws_secret_env` overwrites variables that are already set.** The guard meant to protect them tests the secret's
own key name, while the variable it exports is the uppercased form - so with a secret key `db_host`, an existing
`DB_HOST` is replaced whether or not you passed `--overwrite`. The guard only behaves as documented when the secret's
keys are already spelled in upper case.

**A secret key containing a space aborts the handler.** The key is used both as a shell variable name and, unquoted,
as a `jq` path before it is ever normalised, and both reject the space. The uppercase-and-underscore conversion is
unreachable for such a key, so a secret with one cannot be loaded at all.

**Entering a directory that uses `use aws_secret_env` makes a network call every time.** There is no caching of the
secret, so the delay is paid on every `cd` into the project.
