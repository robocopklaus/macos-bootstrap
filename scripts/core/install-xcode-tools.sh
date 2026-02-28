#!/usr/bin/env bash

# Xcode Command Line Tools Installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Check if Xcode CLI tools are installed
check_xcode_cli_tools() {
    local clt_path="/Library/Developer/CommandLineTools"
    local clt_git="$clt_path/usr/bin/git"
    local xcode_path
    xcode_path="$(xcode-select -p 2>/dev/null || true)"

    # Primary check: xcode-select points to CLT and key binary exists.
    if [[ "$xcode_path" == "$clt_path" ]] && [[ -x "$clt_git" ]]; then
        return 0
    fi

    # Fallback check: CLT package is registered and key binary exists.
    if pkgutil --pkg-info com.apple.pkg.CLTools_Executables >/dev/null 2>&1 && [[ -x "$clt_git" ]]; then
        return 0
    fi

    return 1
}

# Install Xcode Command Line Tools
install_xcode_cli_tools() {
    info "Checking Xcode Command Line Tools..."
    
    if check_xcode_cli_tools; then
        success "Xcode Command Line Tools are already installed"
        return 0
    fi
    
    info "Xcode Command Line Tools not found. Installing..."
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would install Xcode Command Line Tools"
        return 0
    fi
    
    # Create temporary file to trigger installation
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    
    # Get the product identifier (try multiple extraction methods for robustness)
    local product_id

    # Method 1: Extract using Label: format (newer macOS versions)
    product_id=$(softwareupdate -l 2>/dev/null | \
        grep -E "^\s*\*.*Command Line Tools" | \
        tail -n 1 | \
        awk -F'Label: ' '{print $2}' | \
        xargs 2>/dev/null)

    # Method 2: Fallback extraction for older format
    if [[ -z "$product_id" ]] || [[ ! "$product_id" =~ ^Command ]]; then
        product_id=$(softwareupdate -l 2>/dev/null | \
            grep -i "Command Line Tools" | \
            grep -v "^\s*$" | \
            tail -n 1 | \
            sed -E 's/^.*\* (Command Line Tools[^,]*).*/\1/' | \
            xargs 2>/dev/null)
    fi

    # Validate the extracted ID
    if [[ -z "$product_id" ]] || [[ ! "$product_id" =~ ^Command ]]; then
        error "Could not find Command Line Tools product identifier"
        error "Try running: xcode-select --install"
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        return 1
    fi
    
    info "Installing Command Line Tools: $product_id"
    
    if sudo softwareupdate -i "$product_id" --verbose; then
        success "Xcode Command Line Tools installed successfully"
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    else
        error "Failed to install Xcode Command Line Tools"
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        return 1
    fi
}

# Verify installation
verify_installation() {
    info "Verifying Xcode CLI tools installation..."
    
    local all_good=true
    
    # Check Xcode CLI tools
    if check_xcode_cli_tools; then
        success "✓ Xcode Command Line Tools verified"
    else
        error "✗ Xcode Command Line Tools verification failed"
        info "Checking git location: $(which git 2>/dev/null || echo 'git not found')"
        info "Checking xcode-select path: $(xcode-select -p 2>/dev/null || echo 'xcode-select failed')"
        all_good=false
    fi
    
    # Check git
    if command -v git >/dev/null 2>&1; then
        success "✓ Git is available"
        local git_version
        git_version=$(git --version 2>/dev/null || echo "version check failed")
        info "Git version: $git_version"
    else
        error "✗ Git is not available"
        all_good=false
    fi
    
    if [[ "$all_good" == true ]]; then
        success "All verifications passed!"
    else
        error "Some verifications failed"
        warn "You may need to restart your terminal or run 'xcode-select --install' manually"
        return 1
    fi
}

# Main function
main() {
    # Skip installation if already done by bootstrap script
    if check_xcode_cli_tools; then
        info "Xcode Command Line Tools already installed (likely by bootstrap script)"
        verify_installation
        return 0
    fi
    
    install_xcode_cli_tools
    verify_installation
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_script
    parse_args "$@"
    main
fi 
