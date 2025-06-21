# macos-bootstrap

A comprehensive script to bootstrap a fresh macOS installation with all essential development tools, applications, and custom settings.

## Features

- **macOS Updates**: Safely checks for and installs available macOS updates
- **Xcode Command Line Tools**: Automatically installs Xcode CLI tools if not present
- **Homebrew**: Installs Homebrew package manager
- **Development Tools**: Installs essential development tools via Brewfile
- **Comprehensive Logging**: Detailed logging of all operations
- **Dry Run Mode**: Preview changes without making them
- **Error Handling**: Robust error handling and cleanup

## What Gets Installed

The script installs the following categories of tools:

### Development Languages & Runtimes

- Node.js, Python, Ruby, Go
- npm, Yarn package managers

### Development Utilities

- Git, GitHub CLI
- jq, curl, wget, tree, htop
- tmux, vim, neovim

### Database & Container Tools

- PostgreSQL, Redis
- Docker, Docker Compose

### Cloud & Infrastructure

- AWS CLI, Terraform

### System Utilities

- GNU coreutils, findutils, grep, sed, tar, which
- Security tools (OpenSSL, GPG)
- Network tools (nmap, Wireshark)

## Usage

### Quick Start

After a fresh macOS install:

1. Open Terminal
2. Run the following command:

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/robocopklaus/macos-bootstrap/main/scripts/setup-mac.sh)
   ```

### Local Development

If you have the repository cloned locally:

```bash
cd macos-bootstrap
./scripts/setup-mac.sh
```

### Options

- `--dry-run` or `-d`: Preview what the script will do without making changes
- `--verbose` or `-v`: Enable verbose output
- `--help` or `-h`: Show help information

Examples:

```bash
# Preview changes
./scripts/setup-mac.sh --dry-run

# Run with verbose output
./scripts/setup-mac.sh --verbose

# Show help
./scripts/setup-mac.sh --help
```

## Customization

### Adding More Applications

Edit the `Brewfile` to add or remove applications:

```bash
# Add a new application
echo 'brew "application-name"' >> Brewfile

# Remove an application
# Delete or comment out the line in Brewfile
```

### Brewfile Syntax

The Brewfile supports various Homebrew installation types:

```bash
# Install a formula
brew "formula-name"

# Install a cask (GUI application)
cask "application-name"

# Install from a tap
tap "user/repo"
brew "formula-name"

# Install a specific version
brew "formula-name@version"
```

## Requirements

- macOS (tested on macOS 10.15+)
- Internet connection
- Administrator privileges (for some installations)

## Logging

The script creates detailed logs at `/tmp/macos-bootstrap-YYYYMMDD-HHMMSS.log` for troubleshooting and verification.

## Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure you have administrator privileges
2. **Homebrew Installation Fails**: Check your internet connection and try again
3. **Xcode CLI Tools Issues**: Run `xcode-select --install` manually if needed

### Getting Help

- Check the log file for detailed error information
- Run with `--verbose` for more detailed output
- Use `--dry-run` to preview changes before making them

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).
