# Dotfiles Management System

This repository provides a robust management system for your dotfiles, designed specifically for power users who require
a reliable and customizable environment. This documentation outlines the architecture of the project and provides
guidance on developing new plugins.

* [Usage](#usage)
* [Available Plugins](#available-plugins)
* [Architecture](#architecture)
* [Contributing](#contributing)
* [License](#license)

# Usage

## Installation

To install the dotfiles management system, run the following commands in your terminal:

```bash
curl https://raw.githubusercontent.com/jakubro/profile.d/main/bin/install.sh | bash
\. ~/.bashrc
```

This command executes the installation script, which handles the setup of necessary prerequisites, symlinks the required
files into your home directory, and installs any specified plugins.

## Configuration

You can customize your setup by modifying the `.profiledrc` file located in your home directory. This file allows you to
specify which plugins you want to install.

Then run the following commands to apply the changes:

```bash
profile.d-update
\. ~/.bashrc
```

### Example Configuration

Here’s an example of what your `.profiledrc` might look like:

```bash
#!/bin/bash
# https://github.com/jakubro/profile.d

PLUGINS=(
  https://github.com/jakubro/profile.d-autojump
  https://github.com/jakubro/profile.d-direnv
  https://github.com/jakubro/profile.d-hstr
  https://github.com/jakubro/profile.d-liquidprompt
  https://github.com/jakubro/profile.d-nvm
  https://github.com/jakubro/profile.d-pyenv
)
```

## Updating

To update the dotfiles management system, run the following commands:

```bash
profile.d-update
\. ~/.bashrc
```

# Available Plugins

* [autojump](https://github.com/jakubro/profile.d-autojump)
* [direnv](https://github.com/jakubro/profile.d-direnv)
* [hstr](https://github.com/jakubro/profile.d-hstr)
* [liquidprompt](https://github.com/jakubro/profile.d-liquidprompt)
* [nvm](https://github.com/jakubro/profile.d-nvm)
* [pyenv](https://github.com/jakubro/profile.d-pyenv)

# Architecture

The dotfiles management system is structured to facilitate easy installation, configuration, and management of
user-specific settings and tools. Below is a breakdown of the key components:

## Directory Structure

- **bin/**: Contains installation scripts that automate the setup and management of this tool.

- **examples/**:
    - **.profiledrc**: An example configuration file that lists plugins to install.
    - **plugin/**: Demonstrates the folder structure for creating a new example plugin.

- **home/**: Contains files that will be symlinked into your home directory during installation, including:
    - `.bashrc`: The main entrypoint invoked from `~/.bashrc`.
    - `.bash_profile`: Loads `.bashrc`.
    - `.profile`: An empty profile script.

- **hooks/**: Implements various hooks that allow for custom behavior at different stages of the tool's lifecycle (e.g.,
  pre-init, init, post-init).

- **tests/**: Contains scripts to run and test the installation process automatically within a Docker container,
  ensuring that everything works as expected.

- **include/**: Acts as a "standard library" containing utility functions that can be used throughout the scripts.

## Plugin System

The plugin system is designed to extend the functionality of the dotfiles management system. Each plugin can define its
own installation scripts, hooks, and configurations. Plugins are loaded based on the configuration specified in the
`.profiledrc` file located in the user's home directory.

## Hooks

The hooks provided in the `hooks/` directory allow you to extend the functionality of your dotfiles management system.
You can create custom scripts that will be executed at various points in the tool's lifecycle, such as before or after
the prompt is displayed.

# Developer Guide

## Developing New Plugins

Creating a new plugin involves setting up a specific directory structure and defining the necessary scripts. Here’s how
to get started:

### Step 1: Create Plugin Directory

Create a new directory for your plugin, e.g. in `~/work/my-profile.d-plugin`.

### Step 2: Define Installation Script

Inside your plugin directory, create a `bin/install.sh` file. This script should handle the installation logic for your
plugin. For example:

```bash
#!/bin/bash

log_info "Installing my-plugin..."

# Your installation logic here

log_info "my-plugin installed successfully."
```

### Step 3: Implement Hooks

If your plugin requires hooks, create a `hooks/` directory within your plugin directory. Inside this directory, you can
define various hook scripts such as `init`, `pre-init`, `post-init`, etc. Each script should start with a shebang (
`#!/bin/bash`) and implement the desired functionality.

### Step 3: Implement Dotfiles

If your plugin requires dotfiles, create a `home/` directory within your plugin directory. Inside this directory, you
can define various dotfiles such as `.gitconfig`, `.npmrc`, etc. During installation, these dotfiles will be symlinked
into your home directory.

### Step 4: Update .profiledrc

Add your plugin to the `.profiledrc` file in your home directory to ensure it gets loaded:

```bash
PLUGINS=(
  # ...
  ~/work/my-profile.d-plugin
)
```

### Step 5: Install the plugin

Run the following command to install the plugin:

```bash
profile.d-update
\. ~/.bashrc
```

# Contributing

If you would like to contribute to this project, please feel free to submit a pull request or open an issue for
discussion.

# License

This project is licensed under the MIT License. See the LICENSE file for more details.
