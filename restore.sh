#!/bin/bash
#
# restore.sh - Manage chezmoi configuration files
#
# This script helps manage chezmoi configuration files by:
# 1. Checking if chezmoi.toml is a symlink and reporting its target
# 2. If not, listing available *-chezmoi.toml files for selection
# 3. Creating a symlink to the selected configuration file
# 4. Optionally installing chezmoi if not present
# 5. Optionally running chezmoi init --apply with the selected configuration
#
# Enable stricter error handling
set -euo pipefail
# -e: Exit immediately if a command exits with a non-zero status
# -u: Treat unset variables as an error
# -o pipefail: Return value of a pipeline is the status of the last command
#              to exit with a non-zero status, or zero if no command exited with non-zero status

# Display usage information
show_usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help     Show this help message and exit
  -l, --list     List available configuration files and exit
  -f, --force    Force overwrite of existing symlink

Description:
  This script helps manage chezmoi configuration files by setting up the
  appropriate symlinks and optionally installing and initializing chezmoi.
EOF
}

# Logging functions
log_info() {
  echo -e "\033[0;34m[INFO]\033[0m $1"
}

log_success() {
  echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_warn() {
  echo -e "\033[0;33m[WARNING]\033[0m $1" >&2
}

# Error handling function
error_exit() {
  echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
  exit 1
}

# Function to cleanup on exit
cleanup() {
  # Add cleanup actions here if needed
  if [ $? -ne 0 ]; then
    log_warn "Script execution was interrupted."
  fi
}

# Handle interrupts and exits
trap cleanup EXIT
trap 'log_warn "Caught interrupt signal"; exit 1' INT HUP TERM

# Process command line arguments
FORCE_OVERWRITE=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
      ;;
    -l|--list)
      LIST_ONLY=true
      shift
      ;;
    -f|--force)
      FORCE_OVERWRITE=true
      shift
      ;;
    *)
      log_warn "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
done

# Change to the script's directory to ensure we're working in the right location
# This works in bash, zsh, and other shells
SCRIPT_PATH="${0}"
if [[ -L "${SCRIPT_PATH}" ]]; then
    # If the script is a symlink, resolve it
    SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
fi
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" &>/dev/null && pwd)"
if [ -z "$SCRIPT_DIR" ]; then
    error_exit "Failed to determine script directory."
fi
cd "$SCRIPT_DIR" || error_exit "Failed to change to script directory: $SCRIPT_DIR"
log_info "Working in directory: $SCRIPT_DIR"

# Verify that configuration files exist in this directory
if [ -z "$(find . -maxdepth 1 -name "*-chezmoi.toml" 2>/dev/null)" ]; then
    error_exit "No configuration files (*-chezmoi.toml) found in $SCRIPT_DIR."
fi

# Check if chezmoi.toml is a symlink
if [ -L "chezmoi.toml" ] && [ "$FORCE_OVERWRITE" = false ]; then
    # Get the target file that chezmoi.toml points to
    target=$(readlink -f "chezmoi.toml")
    target_name=$(basename "$target")
    log_info "chezmoi.toml is currently a symlink to: $target_name"
    if [ "$LIST_ONLY" = false ]; then
        log_info "Use --force to overwrite the existing symlink."
    fi
elif [ -L "chezmoi.toml" ] && [ "$FORCE_OVERWRITE" = true ] && [ "$LIST_ONLY" = false ]; then
    # Get the target file that chezmoi.toml points to
    target=$(readlink -f "chezmoi.toml")
    target_name=$(basename "$target")
    log_warn "Overwriting existing symlink: chezmoi.toml -> $target_name"
fi

# Find all *-chezmoi.toml files and sort them alphabetically
mapfile -t config_files < <(find . -maxdepth 1 -name "*-chezmoi.toml" | sort)

# Display the list of configuration files
log_info "Available configuration files:"
for i in "${!config_files[@]}"; do
    # Remove leading ./ from filenames for cleaner display
    clean_name=$(basename "${config_files[$i]}")
    log_info "  $((i+1)). $clean_name"
done

# If list-only mode is set, exit after listing files
if [ "$LIST_ONLY" = true ]; then
    exit 0
fi

# Prompt user to select a file
echo -n "Pick a configuration file: "
read -r selection || error_exit "Input interrupted."

# Validate input
if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
    error_exit "Invalid selection: Not a number"
fi

# Convert to zero-based index
selection=$((selection-1))

# Check if selection is valid
if [ "$selection" -lt 0 ] || [ "$selection" -ge "${#config_files[@]}" ]; then
    error_exit "Invalid selection: Number out of range"
fi

# Create symlink
selected_file="${config_files[$selection]}"
# Remove the leading ./ if present
selected_file="${selected_file#./}"

# Check if the selected file exists before creating symlink
if [ ! -f "$selected_file" ]; then
    error_exit "The selected file '$selected_file' does not exist."
fi

# Create the symlink and check if it succeeded
if ln -sf "$selected_file" "chezmoi.toml"; then
    selected_file_name=$(basename "$selected_file")
    log_success "Created symlink: chezmoi.toml -> $selected_file_name"
else
    error_exit "Failed to create symlink."
fi

# Check to see if chezmoi is installed.
if ! command -v chezmoi &> /dev/null
then
    # Ask if the user wants to install chezmoi
    log_warn "chezmoi is not installed. Do you want to install it? (y/n)"
    read -r install_choice || error_exit "Input interrupted."
    if [[ "$install_choice" =~ ^[yY](es)?$ ]]; then
        # Install chezmoi using the recommended method
        log_info "Installing chezmoi..."
        if command -v mise &> /dev/null; then
            mise use chezmoi
        elif command -v brew &> /dev/null; then
            brew install chezmoi
        elif command -v apt-get &> /dev/null; then
            sudo apt-get install chezmoi
        elif command -v dnf &> /dev/null; then
            sudo dnf install chezmoi
        elif command -v curl &> /dev/null; then
            sh -c "$(curl -fsLS get.chezmoi.io)"
        elif command -v wget &> /dev/null; then
            sh -c "$(wget -qO- get.chezmoi.io)"
        elif command -v iex &> /dev/null; then
            iex "&{$(irm 'https://get.chezmoi.io/ps1')}"
        else
            error_exit "No supported package manager found. Please install chezmoi manually."
        fi
    else
        log_warn "chezmoi installation skipped, install it and run:"
        log_info "chezmoi init --apply ${GITHUB_USERNAME:-$USER}"
        log_info "(last argument should be your github username)."
        exit 0
    fi
fi

# Ask the user if they want to run chezmoi init --apply
log_info "Do you want to run 'chezmoi init --apply' with the selected configuration? (y/n)"
read -r run_choice || error_exit "Input interrupted."
if [[ "$run_choice" =~ ^[yY](es)?$ ]]; then
    # Run chezmoi init --apply with the selected configuration
    log_info "Running 'chezmoi init --apply'..."
    if ! chezmoi init --apply "${GITHUB_USERNAME:-$USER}"; then
        error_exit "Failed to initialize chezmoi configuration."
    fi
else
    log_warn "chezmoi init --apply skipped."
    exit 0
fi

# Final message
log_success "chezmoi configuration has been restored."