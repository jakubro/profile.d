# pyenv

Installs and activates [pyenv](https://github.com/pyenv/pyenv), which builds and switches between Python versions per
user, per directory or per shell, without touching the system Python.

## Enable it

```bash
PLUGINS=(
  https://github.com/jakubro/profile.d-pyenv
)
```

```bash
profile.d-install
\. ~/.bashrc
```

## What it does

**At install time**, on a machine with no `~/.pyenv`, it pipes `https://pyenv.run` into bash - pyenv's own installer,
which brings pyenv along with the plugins it bundles rather than a bare checkout. Once `~/.pyenv` exists, later runs
`git pull` it instead. Either way it then compiles pyenv's small C helper with `src/configure && make -C src`.

**In every shell**, provided `~/.pyenv` exists, it exports `PYENV_ROOT=~/.pyenv`, prepends `~/.pyenv/bin` to `PATH`,
and evaluates `pyenv init -`, which installs the shims that make `python` resolve to whichever version is selected.
All three happen at the `init` stage and are not restricted to interactive shells. If the install failed and
`~/.pyenv` is absent, the hook does nothing at all rather than reporting it.

## Using it

```console
$ pyenv install --list          # what is available
$ pyenv install 3.13.1          # build one, which takes a few minutes
$ pyenv global 3.13.1           # the default for this account
$ pyenv local 3.11.9            # writes .python-version, for this directory down
$ pyenv version                 # what is active, and why
```

`pyenv local` writes a `.python-version` file you are meant to commit. If you would rather select the version from
`.envrc`, [direnv](direnv.md)'s `use python` drives pyenv for you and adds a virtual environment.

## Requirements

`curl`, for the installer this plugin pipes into bash.

Building a Python from source additionally needs a compiler and a set of development headers, which pyenv does not
install. On a Fedora-family system:

```bash
sudo dnf install make gcc zlib-devel bzip2-devel readline-devel sqlite-devel \
  openssl-devel tk-devel libffi-devel xz-devel
```

Debian-family and other distributions are covered by
[pyenv's own build environment page](https://github.com/pyenv/pyenv/wiki#suggested-build-environment). Without them
`pyenv install` fails partway through a build with a compiler error rather than a clear message.

## Known issues

**The helper is recompiled on every update.** The `configure && make` step runs on each `profile.d-install`, not only
when pyenv changed, so every update pays for it. It is a small build - seconds, not minutes - but it is why a run that
should have been a no-op is not silent.
