#!/usr/bin/env bash

# Dotfiles Setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Resolve repository root robustly (env → git → relative)
if [[ -n "${REPO_ROOT:-}" && -d "$REPO_ROOT" ]]; then
    :
else
    if command -v git >/dev/null 2>&1; then
        REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
    fi
    if [[ -z "${REPO_ROOT:-}" || ! -d "$REPO_ROOT" ]]; then
        REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    fi
fi

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
        
        if [[ "$DRY_RUN" == true ]]; then
            if [[ -L "$target" ]]; then
                info "DRY RUN: Would update symlink $target -> $dotfile"
            elif [[ -f "$target" ]]; then
                warn "DRY RUN: Would backup $target and create symlink to $dotfile"
            else
                info "DRY RUN: Would create symlink $target -> $dotfile"
            fi
            continue
        fi
        
        # Check if target already exists
        if [[ -L "$target" ]]; then
            # Check if it's already pointing to the right place
            if [[ "$(readlink "$target")" == "$dotfile" ]]; then
                success "✓ Symlink already exists: $target"
            else
                info "Updating symlink: $target"
                rm "$target"
                ln -s "$dotfile" "$target"
                success "✓ Updated symlink: $target"
            fi
        elif [[ -f "$target" ]]; then
            # Backup existing file
            local backup
            backup="$target.backup.$(date +%Y%m%d-%H%M%S)"
            info "Backing up existing file: $target -> $backup"
            mv "$target" "$backup"
            ln -s "$dotfile" "$target"
            success "✓ Created symlink: $target (backed up original to $backup)"
        else
            # Create new symlink
            ln -s "$dotfile" "$target"
            success "✓ Created symlink: $target"
        fi
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
