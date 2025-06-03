# Chezmoi Configuration Manager

This repository contains my configuration files for [chezmoi](https://www.chezmoi.io/), a dotfile manager that helps me manage my personal configuration files across multiple machines.

## Overview

Chezmoi allows you to keep your dotfiles (like `.bashrc`, `.vimrc`, etc.) in sync across different machines. This repository contains multiple configuration profiles for different environments, stored as `*-chezmoi.toml` files.

## Files

- **chezmoi.toml**: The active configuration file (symlink to one of the profile configurations)
- **\*-chezmoi.toml**: Various configuration profiles for different environments
- **restore.sh**: Utility script to manage configuration profiles

## Using restore.sh

The `restore.sh` script helps you manage your chezmoi configurations by:

1. Listing available configurations
2. Allowing you to select a configuration profile
3. Creating a symlink from the selected profile to `chezmoi.toml`
4. Optionally installing chezmoi if not present
5. Optionally initializing chezmoi with your configuration

### Usage

```bash
./restore.sh [OPTIONS]
```

### Options

- `-h, --help`: Show help message and exit
- `-l, --list`: List available configuration files and exit
- `-f, --force`: Force overwrite of existing symlink

### Examples

List available configurations:
```bash
./restore.sh --list
```

Choose a configuration (interactive):
```bash
./restore.sh
```

Force overwrite of an existing symlink:
```bash
./restore.sh --force
```

## Setting Up a New Machine

To set up chezmoi on a new machine:

1. Clone this repository:
   ```bash
   git clone <repository-url> ~/.config/chezmoi
   ```

2. Run the restore script:
   ```bash
   cd ~/.config/chezmoi
   ./restore.sh
   ```

3. Follow the prompts to select a configuration file, install chezmoi (if needed), and initialize your dotfiles.

## Adding New Configuration Profiles

To create a new configuration profile:

1. Create a new file named `<profile-name>-chezmoi.toml` 
2. Add your configuration settings to this file
3. Make sure to set the `machine` setting in the `[data]` to something that makes sense (generally it matches the profile-name from step 1)
4. Use `./restore.sh` to switch between profiles

## Why Use Multiple Configurations?

Different environments (work, personal, server, etc.) may require different chezmoi settings. This repository structure allows you to maintain separate configurations for each environment while sharing the same chezmoi source files.

---

For more information on chezmoi, visit the [official documentation](https://www.chezmoi.io/).
