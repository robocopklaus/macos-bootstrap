#!/usr/bin/env bash

# Dotfiles Setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

REPO_ROOT=$(resolve_repo_root "$SCRIPT_DIR")

# Get target path for a given source file
get_target_path() {
    local source_file="$1"
    local filename
    filename=$(basename "$source_file")
    local default_target="$HOME/$filename"
    
    # App-specific configuration mappings
    case "$source_file" in
        */ghostty/config)
            echo "$HOME/.config/ghostty/config"
            ;;
        */oh-my-posh/theme.omp.json)
            echo "$HOME/.config/oh-my-posh/theme.omp.json"
            ;;
        *)
            # Default: place in home directory
            echo "$default_target"
            ;;
    esac
}

# Create symlinks for dotfiles
setup_dotfiles() {
    info "Setting up dotfiles..."
    
    local files_dir="$REPO_ROOT/files"
    
    if [[ ! -d "$files_dir" ]]; then
        warn "Files directory not found at: $files_dir"
        return 0
    fi
    
    info "Searching for dotfiles in: $files_dir"
    
    # Find and process all dotfiles in the files directory and subdirectories
    # Use a more robust approach to handle the find command
    local dotfiles_found=false
    
    while IFS= read -r -d '' dotfile; do
        dotfiles_found=true
        local target
        target=$(get_target_path "$dotfile")

        if [[ "$VERBOSE" == true ]]; then
            info "Processing dotfile: $dotfile -> $target"
        fi

        # Ensure the target directory exists for non-standard locations
        if [[ "$target" != "$HOME/$(basename "$dotfile")" && "$DRY_RUN" != true ]]; then
            mkdir -p "$(dirname "$target")"
        fi

        create_symlink "$dotfile" "$target"
    done < <(find "$files_dir" \( -name ".*" -o -path "*/ghostty/*" -o -path "*/oh-my-posh/*" \) -type f -print0 2>/dev/null || true)
    
    if [[ "$dotfiles_found" == false ]]; then
        info "No dotfiles found in $files_dir"
        info "You can add dotfiles to the files/ directory to have them automatically linked"
    fi
}

# Main function
main() {
    setup_dotfiles
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_script
    main
fi 
