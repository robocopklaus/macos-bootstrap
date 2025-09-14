#!/usr/bin/env bash

# macOS Updates

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Check for available updates
check_for_updates() {
    info "Checking for available macOS updates..."
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would check for updates"
        return 0
    fi
    
    # Get the update list and check for available updates
    local update_output
    update_output=$(softwareupdate -l 2>/dev/null)
    
    # Check if the output contains "No new software available"
    if echo "$update_output" | grep -q "No new software available"; then
        success "No updates available"
        return 0
    fi
    
    # Check if there are any updates (lines starting with *)
    if echo "$update_output" | grep -q "^\*"; then
        local update_count
        update_count=$(echo "$update_output" | grep -c "^\*" | tr -d '[:space:]')
        info "Found $update_count update(s) available"
        echo "$update_output" | grep "^\*" | sed 's/^[ *]*//'
        return 1
    else
        success "No updates available"
        return 0
    fi
}

# Update macOS with user confirmation
update_macos() {
    info "Checking for macOS updates..."
    
    if ! check_for_updates; then
        if [[ "$NON_INTERACTIVE" != true ]]; then
            echo
            warn "Updates are available. This may include system updates that require a restart."
            echo -n "Do you want to install available updates? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                warn "Skipping macOS updates"
                return 0
            fi
        else
            info "Non-interactive mode enabled; proceeding with updates."
        fi
        
        if [[ "$DRY_RUN" == true ]]; then
            warn "DRY RUN: Would install macOS updates"
            return 0
        fi
        
        info "Installing macOS updates..."
        if sudo softwareupdate -i -a; then
            success "macOS updates installed successfully"
            warn "System restart may be required"
        else
            error "Failed to install macOS updates"
            return 1
        fi
    fi
}

# Main function
main() {
    update_macos
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_script
    main
fi 
